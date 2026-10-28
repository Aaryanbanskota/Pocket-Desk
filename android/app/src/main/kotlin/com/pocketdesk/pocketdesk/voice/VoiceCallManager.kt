package com.pocketdesk.pocketdesk.voice

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioFocusRequest
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.media.audiofx.AcousticEchoCanceler
import android.media.audiofx.NoiseSuppressor
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit

class VoiceCallManager(private val context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "pocketdesk/voice_call")
    private val mainHandler = Handler(Looper.getMainLooper())
    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    private var audioRecord: AudioRecord? = null
    private var audioTrack: AudioTrack? = null
    private var recordThread: Thread? = null
    private var playThread: Thread? = null
    private val playQueue = LinkedBlockingQueue<ByteArray>()

    private var echoCanceler: AcousticEchoCanceler? = null
    private var noiseSuppressor: NoiseSuppressor? = null
    private var audioFocusRequest: AudioFocusRequest? = null

    @Volatile
    private var isCallActive = false

    // Adaptive real-time jitter buffer:
    // Only pre-buffers at utterance start (2 chunks = ~100ms cushion).
    // Never enters an artificial sleep/stall loop while speech packets are actively flowing.
    @Volatile
    private var isPreBuffering = true
    private val preBufferTarget = 2 
    private val maxQueueSize = 3 // Strict cap (~150ms max buffer) eliminates latency accumulation
    private var lastPacketReceivedTime = 0L

    @Volatile
    private var isMuted = false

    private val sampleRate = 16000
    // 50ms chunk size: 800 samples = 1600 bytes PCM (800 bytes mu-law)
    // Cuts latency in half, prevents frame drops, and ensures smooth continuous voice stream.
    private val chunkSize = 1600 

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startVoiceCall" -> {
                    val speaker = call.argument<Boolean>("speaker") ?: true
                    startVoiceCall(speaker)
                    result.success(true)
                }
                "stopVoiceCall" -> {
                    stopVoiceCall()
                    result.success(true)
                }
                "playAudioChunk" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes != null) {
                        playAudioChunk(bytes)
                    }
                    result.success(true)
                }
                "setMuted" -> {
                    isMuted = call.argument<Boolean>("muted") ?: false
                    result.success(true)
                }
                "setSpeaker" -> {
                    val speaker = call.argument<Boolean>("speaker") ?: false
                    setSpeaker(speaker)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun startVoiceCall(speaker: Boolean = true) {
        stopVoiceCall()

        try {
            requestCallAudioFocus()
            audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
            setSpeaker(speaker)
            isMuted = false

            val minRecBuf = AudioRecord.getMinBufferSize(
                sampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            )
            val recBufSize = maxOf(minRecBuf * 2, 4096)

            audioRecord = tryCreateRecorder(recBufSize)

            val sessionId = audioRecord?.audioSessionId ?: AudioManager.AUDIO_SESSION_ID_GENERATE

            // Enable hardware AcousticEchoCanceler
            if (AcousticEchoCanceler.isAvailable() && sessionId != AudioManager.AUDIO_SESSION_ID_GENERATE) {
                try {
                    echoCanceler = AcousticEchoCanceler.create(sessionId)?.apply {
                        enabled = true
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            // Enable hardware NoiseSuppressor
            if (NoiseSuppressor.isAvailable() && sessionId != AudioManager.AUDIO_SESSION_ID_GENERATE) {
                try {
                    noiseSuppressor = NoiseSuppressor.create(sessionId)?.apply {
                        enabled = true
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            // NOTE: Hardware AutomaticGainControl (AGC) is intentionally NOT enabled here.
            // Hardware AGC on Android introduces violent volume swings (+20dB gain pumping during pauses,
            // then sudden clamping down when speaking), and breaks AEC double-talk detection.
            // Instead, we use a smooth linear soft-limiter to maintain warm, stable speech levels.

            val minPlayBuf = AudioTrack.getMinBufferSize(
                sampleRate,
                AudioFormat.CHANNEL_OUT_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            )
            val playBufSize = maxOf(minPlayBuf * 2, 4096)

            // AudioTrack with USAGE_VOICE_COMMUNICATION for system telephony echo cancellation path
            val trackBuilder = AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(sampleRate)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build()
                )
                .setBufferSizeInBytes(playBufSize)
                .setTransferMode(AudioTrack.MODE_STREAM)

            audioTrack = trackBuilder.build().apply {
                if (state == AudioTrack.STATE_INITIALIZED) {
                    setVolume(1.0f)
                    play()
                }
            }

            try {
                if (audioRecord?.state == AudioRecord.STATE_INITIALIZED) {
                    audioRecord?.startRecording()
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }

            isCallActive = true
            isPreBuffering = true
            lastPacketReceivedTime = 0L
            playQueue.clear()

            // Playback Thread with non-stalling, timed-poll buffer
            playThread = Thread {
                while (isCallActive) {
                    try {
                        if (isPreBuffering) {
                            // Only pause briefly while accumulating the initial 2-chunk cushion
                            Thread.sleep(10)
                            continue
                        }

                        // Block wait up to 45ms for next chunk.
                        // If queue has an item, returns immediately (0ms latency).
                        val chunk = playQueue.poll(45, TimeUnit.MILLISECONDS)
                        if (chunk == null) {
                            // Queue temporarily empty: if silence lasts > 350ms, mark for pre-buffering
                            // before the next sentence begins. DO NOT stall current audio mid-word!
                            if (System.currentTimeMillis() - lastPacketReceivedTime > 350) {
                                isPreBuffering = true
                            }
                            continue
                        }

                        val track = audioTrack ?: break
                        if (track.state == AudioTrack.STATE_INITIALIZED) {
                            // Apply smooth soft limiter to playback to prevent audio cracking / volume spikes
                            applySoftLimiter(chunk, chunk.size)
                            track.write(chunk, 0, chunk.size, AudioTrack.WRITE_BLOCKING)
                        }
                    } catch (e: InterruptedException) {
                        break
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }.apply { name = "PocketdeskCallPlay" }
            playThread?.start()

            // Recording Thread with 50ms chunks and soft peak limiting
            recordThread = Thread {
                val buffer = ByteArray(chunkSize)
                while (isCallActive) {
                    var totalRead = 0
                    while (totalRead < chunkSize && isCallActive) {
                        val recorder = audioRecord ?: break
                        val read = recorder.read(buffer, totalRead, chunkSize - totalRead)
                        if (read <= 0) break
                        totalRead += read
                    }

                    if (totalRead > 0 && isCallActive && !isMuted) {
                        // Soft limiter prevents microphone distortion without volume pumping
                        applySoftLimiter(buffer, totalRead)
                        val chunk = buffer.copyOf(totalRead)
                        mainHandler.post {
                            if (isCallActive && !isMuted) {
                                channel.invokeMethod("onLocalAudioChunk", chunk)
                            }
                        }
                    }
                }
            }.apply { name = "PocketdeskCallRecord" }
            recordThread?.start()
        } catch (e: Exception) {
            e.printStackTrace()
            isCallActive = false
        }
    }

    private fun tryCreateRecorder(recBufSize: Int): AudioRecord? {
        val sources = intArrayOf(
            MediaRecorder.AudioSource.VOICE_COMMUNICATION,
            MediaRecorder.AudioSource.MIC,
            MediaRecorder.AudioSource.DEFAULT,
        )
        for (source in sources) {
            try {
                val recorder = AudioRecord(
                    source,
                    sampleRate,
                    AudioFormat.CHANNEL_IN_MONO,
                    AudioFormat.ENCODING_PCM_16BIT,
                    recBufSize
                )
                if (recorder.state == AudioRecord.STATE_INITIALIZED) {
                    return recorder
                }
                recorder.release()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        return null
    }

    private fun requestCallAudioFocus() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                            .build()
                    )
                    .setAcceptsDelayedFocusGain(false)
                    .build()
                audioFocusRequest = request
                audioManager.requestAudioFocus(request)
            } else {
                @Suppress("DEPRECATION")
                audioManager.requestAudioFocus(
                    null,
                    AudioManager.STREAM_VOICE_CALL,
                    AudioManager.AUDIOFOCUS_GAIN_TRANSIENT,
                )
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun playAudioChunk(bytes: ByteArray) {
        if (!isCallActive || bytes.isEmpty()) return
        val now = System.currentTimeMillis()

        // If the gap between packets was large (> 350ms, a natural sentence pause),
        // pre-buffer the upcoming phrase for smooth playback without cutouts
        if (now - lastPacketReceivedTime > 350) {
            isPreBuffering = true
        }
        lastPacketReceivedTime = now

        // Strictly bound queue size to max 3 chunks (~150ms buffer) to prevent latency buildup
        while (playQueue.size >= maxQueueSize) {
            playQueue.poll() // Discard oldest packet to catch up immediately
        }

        playQueue.offer(bytes)

        // Release pre-buffer hold as soon as the target cushion is reached
        if (isPreBuffering && playQueue.size >= preBufferTarget) {
            isPreBuffering = false
        }
    }

    /**
     * Smooth 16-bit PCM soft limiter:
     * Prevents loud sudden peaks or volume swings without introducing the pumping/ducking
     * caused by hardware AGC. Keeps speech warm, intelligible, and consistent.
     */
    private fun applySoftLimiter(buffer: ByteArray, length: Int) {
        val maxAmp = 26000
        for (i in 0 until length - 1 step 2) {
            var sample = (buffer[i].toInt() and 0xFF) or (buffer[i + 1].toInt() shl 8)
            if (sample >= 0x8000) sample -= 0x10000

            if (sample > maxAmp) {
                sample = maxAmp + ((sample - maxAmp) / 3)
            } else if (sample < -maxAmp) {
                sample = -maxAmp + ((sample - -maxAmp) / 3)
            }

            buffer[i] = (sample and 0xFF).toByte()
            buffer[i + 1] = ((sample shr 8) and 0xFF).toByte()
        }
    }

    fun setSpeaker(speaker: Boolean) {
        try {
            audioManager.isSpeakerphoneOn = speaker
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val devices = audioManager.availableCommunicationDevices
                if (speaker) {
                    val speakerDevice = devices.find {
                        it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER
                    }
                    if (speakerDevice != null) {
                        audioManager.setCommunicationDevice(speakerDevice)
                    }
                } else {
                    val earpieceDevice = devices.find {
                        it.type == AudioDeviceInfo.TYPE_BUILTIN_EARPIECE
                    }
                    if (earpieceDevice != null) {
                        audioManager.setCommunicationDevice(earpieceDevice)
                    } else {
                        audioManager.clearCommunicationDevice()
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun stopVoiceCall() {
        isCallActive = false
        isPreBuffering = true
        try {
            recordThread?.interrupt()
            recordThread = null

            playThread?.interrupt()
            playThread = null
            playQueue.clear()

            echoCanceler?.release()
            echoCanceler = null

            noiseSuppressor?.release()
            noiseSuppressor = null

            try {
                audioRecord?.stop()
            } catch (_: Exception) {
            }
            audioRecord?.release()
            audioRecord = null

            try {
                audioTrack?.stop()
            } catch (_: Exception) {
            }
            audioTrack?.release()
            audioTrack = null

            audioManager.mode = AudioManager.MODE_NORMAL
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && audioFocusRequest != null) {
                audioManager.abandonAudioFocusRequest(audioFocusRequest!!)
            } else {
                @Suppress("DEPRECATION")
                audioManager.abandonAudioFocus(null)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
