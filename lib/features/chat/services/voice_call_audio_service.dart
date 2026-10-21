import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'chat_socket_service.dart';

// --- Shared Audio Format Constants ---
// 16000 Hz, 1 channel (mono), 16-bit signed little-endian PCM
const int kAudioSampleRate = 16000;
const int kAudioChannels = 1;
const int kAudioBitDepth = 16;
const int kAudioChunkDurationMs = 50; // 50ms chunks (1600 bytes PCM -> 800 bytes mu-law) for low-latency voice
const int kAudioPcmChunkBytes = (kAudioSampleRate * kAudioChannels * (kAudioBitDepth ~/ 8) * kAudioChunkDurationMs) ~/ 1000; // 1600 bytes

class VoiceCallAudioService {
  static final VoiceCallAudioService instance = VoiceCallAudioService._internal();
  factory VoiceCallAudioService() => instance;
  VoiceCallAudioService._internal();

  static const MethodChannel _channel = MethodChannel('pocketdesk/voice_call');

  bool _isCallActive = false;
  bool _isMuted = false;
  bool _isSpeaker = false;

  String? _activeCallId;
  String? _myNumber;
  String? _peerNumber;

  StreamSubscription<CallSignal>? _callSignalSub;

  // Track locally sent chunk tokens in memory to guarantee 100% immunity against self-loopback
  final Set<String> _locallySentChunkTokens = <String>{};

  double _remoteAudioLevel = 0.0;

  // Linux Process Handles
  Process? _linuxRecordProcess;
  Process? _linuxPlayProcess;
  StreamSubscription<List<int>>? _linuxRecordSub;

  // Debug Chunk Counters
  int _sentChunksCount = 0;
  int _passedFiltersChunksCount = 0;
  int _playedChunksCount = 0;

  bool get isCallActive => _isCallActive;
  bool get isMuted => _isMuted;
  bool get isSpeaker => _isSpeaker;

  void initialize() {
    _channel.setMethodCallHandler(_handleNativeMethodCall);
  }

  Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    if (call.method == 'onLocalAudioChunk') {
      final bytes = call.arguments as Uint8List?;
      if (bytes != null && bytes.isNotEmpty && _isCallActive && !_isMuted) {
        _broadcastLocalAudioChunk(bytes);
      }
    }
    return null;
  }

  Future<void> startVoiceCall({
    required String callId,
    required String myNumber,
    required String peerNumber,
  }) async {
    if (_isCallActive) stopVoiceCall();

    _isCallActive = true;
    _activeCallId = callId;
    final effectiveMy = (myNumber.isNotEmpty ? myNumber : ChatSocketService().currentIdentityKey) ?? '';
    _myNumber = effectiveMy;
    _peerNumber = peerNumber;
    _isMuted = false;
    _isSpeaker = true;

    _sentChunksCount = 0;
    _passedFiltersChunksCount = 0;
    _playedChunksCount = 0;
    _locallySentChunkTokens.clear();

    // Register active call session with socket service so incoming packets are routed accurately
    ChatSocketService().setActiveCallSessionId(callId);
    ChatSocketService().joinCallChannel(callId);

    // Listen for incoming audio chunks from peer
    _callSignalSub = ChatSocketService().onCallSignal.listen((signal) {
      if (signal.type == CallSignalType.audioChunk &&
          signal.callId == _activeCallId &&
          signal.audioData != null &&
          signal.audioData!.isNotEmpty) {
        // 1. RULE: NEVER play audio sent from our own physical device instance (eliminate local mic feedback)
        if (signal.token != null && _locallySentChunkTokens.contains(signal.token)) {
          return;
        }
        if (signal.senderDeviceId != null &&
            signal.senderDeviceId!.isNotEmpty &&
            signal.senderDeviceId == ChatSocketService.currentDeviceId) {
          return;
        }

        // 2. RULE: Audio chunk must belong to active call session
        if (signal.callId != _activeCallId) {
          return;
        }

        try {
          final rawBytes = base64Decode(signal.audioData!);
          // Codec detection: branch explicitly on codec field; fall back to size check for legacy packets
          final Uint8List pcmBytes;
          if (signal.codec == 'mulaw') {
            pcmBytes = decodeMuLaw(rawBytes);
          } else if (signal.codec == 'pcm16') {
            pcmBytes = rawBytes;
          } else {
            // Backward compatibility when 'codec' is missing:
            // 100ms 16kHz s16le PCM is 3200 bytes; mu-law is 1600 bytes.
            pcmBytes = (rawBytes.length <= 1600) ? decodeMuLaw(rawBytes) : rawBytes;
          }

          _passedFiltersChunksCount++;
          if (kCallDebug) {
            debugPrint(
              '[CallAudio][FilterPass #$_passedFiltersChunksCount] id=${signal.callId} '
              'codec=${signal.codec ?? "legacy"} pcmBytes=${pcmBytes.length}',
            );
          }

          playRemoteChunk(pcmBytes);
        } catch (e) {
          if (kCallDebug) debugPrint('[CallAudio] Error decoding incoming chunk: $e');
        }
      }
    });

    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod('startVoiceCall', {'speaker': _isSpeaker});
      } catch (e) {
        debugPrint('VoiceCallAudioService startVoiceCall Android error: $e');
      }
    } else if (!kIsWeb && Platform.isLinux) {
      _startLinuxVoicePipeline();
    }
  }

  static double calculateRms(Uint8List pcm16) {
    if (pcm16.isEmpty) return 0.0;
    final byteData = ByteData.sublistView(pcm16);
    final count = pcm16.length ~/ 2;
    if (count == 0) return 0.0;
    double sum = 0.0;
    for (int i = 0; i < count; i++) {
      final s = byteData.getInt16(i * 2, Endian.little);
      sum += s * s;
    }
    return math.sqrt(sum / count);
  }

  void _broadcastLocalAudioChunk(Uint8List chunk) {
    if (!_isCallActive || _isMuted || _activeCallId == null || _peerNumber == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final localRms = calculateRms(chunk);

    // Audio stream is continuous: hardware DSP handles AEC & noise suppression on device,
    // so we never drop voice chunks in software to eliminate stutter and mid-word cutting.
    // Compress with G.711 mu-law (halves network bandwidth to 1600 bytes per 100ms)
    final compressedChunk = encodeMuLaw(chunk);

    _sentChunksCount++;
    final chunkToken = '${_activeCallId}_${now}_${ChatSocketService.currentDeviceId}_$_sentChunksCount';
    _locallySentChunkTokens.add(chunkToken);
    if (_locallySentChunkTokens.length > 500) {
      _locallySentChunkTokens.remove(_locallySentChunkTokens.first);
    }

    if (kCallDebug) {
      debugPrint(
        '[CallAudio][Sent #$_sentChunksCount] id=$_activeCallId bytes=${compressedChunk.length} '
        'codec=mulaw rms=${localRms.toStringAsFixed(1)}',
      );
    }

    final signal = CallSignal(
      type: CallSignalType.audioChunk,
      callId: _activeCallId!,
      callerNumber: _myNumber ?? 'me',
      callerName: 'Me',
      calleeNumber: _peerNumber!,
      senderNumber: _myNumber ?? 'me',
      targetNumber: _peerNumber,
      senderDeviceId: ChatSocketService.currentDeviceId,
      audioData: base64Encode(compressedChunk),
      codec: 'mulaw',
      timestamp: now,
      token: chunkToken,
    );

    ChatSocketService().sendCallSignal(signal);
  }

  Future<void> playRemoteChunk(Uint8List bytes) async {
    if (!_isCallActive || bytes.isEmpty) return;

    _remoteAudioLevel = calculateRms(bytes);

    _playedChunksCount++;
    if (kCallDebug) {
      debugPrint(
        '[CallAudio][Played #$_playedChunksCount] id=$_activeCallId bytes=${bytes.length} '
        'rms=${_remoteAudioLevel.toStringAsFixed(1)}',
      );
    }

    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod('playAudioChunk', {'bytes': bytes});
      } catch (e) {
        debugPrint('VoiceCallAudioService playRemoteChunk Android error: $e');
      }
    } else if (!kIsWeb && Platform.isLinux) {
      try {
        _linuxPlayProcess?.stdin.add(bytes);
        await _linuxPlayProcess?.stdin.flush();
      } catch (e) {
        if (kCallDebug) debugPrint('[CallAudio] Linux play stdin error: $e');
      }
    }
  }

  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod('setMuted', {'muted': muted});
      } catch (_) {}
    }
  }

  Future<void> setSpeaker(bool speaker) async {
    _isSpeaker = speaker;
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod('setSpeaker', {'speaker': speaker});
      } catch (_) {}
    }
  }

  void _startLinuxVoicePipeline() {
    _startLinuxPlayProcess();
    _startLinuxRecordProcess();
  }

  Future<void> _startLinuxPlayProcess() async {
    try {
      final proc = await Process.start('pw-play', [
        '--raw',
        '--format=s16',
        '--rate=$kAudioSampleRate',
        '--channels=$kAudioChannels',
        '-',
      ]);
      _linuxPlayProcess = proc;
      bool hasFallenBack = false;

      proc.stderr.transform(utf8.decoder).listen((data) {
        if (kCallDebug && data.trim().isNotEmpty) {
          debugPrint('[CallAudio] pw-play stderr: ${data.trim()}');
        }
      });

      proc.exitCode.then((exitCode) {
        if (!_isCallActive) return;
        if (kCallDebug) debugPrint('[CallAudio] pw-play exited with code $exitCode');
        if (!hasFallenBack) {
          hasFallenBack = true;
          _fallbackToAplay();
        }
      });
    } catch (e) {
      if (kCallDebug) debugPrint('[CallAudio] Failed to start pw-play: $e, falling back to aplay');
      _fallbackToAplay();
    }
  }

  Future<void> _fallbackToAplay() async {
    if (!_isCallActive) return;
    try {
      final proc = await Process.start('aplay', [
        '-t',
        'raw',
        '-f',
        'S16_LE',
        '-r',
        '$kAudioSampleRate',
        '-c',
        '$kAudioChannels',
        '-q',
      ]);
      _linuxPlayProcess = proc;
      proc.stderr.transform(utf8.decoder).listen((data) {
        if (kCallDebug && data.trim().isNotEmpty) {
          debugPrint('[CallAudio] aplay stderr: ${data.trim()}');
        }
      });
    } catch (e) {
      if (kCallDebug) debugPrint('[CallAudio] Failed to start aplay fallback: $e');
    }
  }

  Future<void> _startLinuxRecordProcess() async {
    try {
      final proc = await Process.start('pw-record', [
        '--raw',
        '--format=s16',
        '--rate=$kAudioSampleRate',
        '--channels=$kAudioChannels',
        '-',
      ]);
      _linuxRecordProcess = proc;
      _setupLinuxRecordStream(proc);
      bool hasFallenBack = false;

      proc.stderr.transform(utf8.decoder).listen((data) {
        if (kCallDebug && data.trim().isNotEmpty) {
          debugPrint('[CallAudio] pw-record stderr: ${data.trim()}');
        }
      });

      proc.exitCode.then((exitCode) {
        if (!_isCallActive) return;
        if (kCallDebug) debugPrint('[CallAudio] pw-record exited with code $exitCode');
        if (!hasFallenBack) {
          hasFallenBack = true;
          _fallbackToArecord();
        }
      });
    } catch (e) {
      if (kCallDebug) debugPrint('[CallAudio] Failed to start pw-record: $e, falling back to arecord');
      _fallbackToArecord();
    }
  }

  Future<void> _fallbackToArecord() async {
    if (!_isCallActive) return;
    try {
      final proc = await Process.start('arecord', [
        '-t',
        'raw',
        '-f',
        'S16_LE',
        '-r',
        '$kAudioSampleRate',
        '-c',
        '$kAudioChannels',
        '-q',
      ]);
      _linuxRecordProcess = proc;
      _setupLinuxRecordStream(proc);
      proc.stderr.transform(utf8.decoder).listen((data) {
        if (kCallDebug && data.trim().isNotEmpty) {
          debugPrint('[CallAudio] arecord stderr: ${data.trim()}');
        }
      });
    } catch (e) {
      if (kCallDebug) debugPrint('[CallAudio] Failed to start arecord fallback: $e');
    }
  }

  void _setupLinuxRecordStream(Process proc) {
    _linuxRecordSub?.cancel();
    final buffer = <int>[];

    _linuxRecordSub = proc.stdout.listen((data) {
      if (!_isCallActive || _isMuted) return;
      buffer.addAll(data);
      while (buffer.length >= kAudioPcmChunkBytes) {
        final chunk = Uint8List.fromList(buffer.sublist(0, kAudioPcmChunkBytes));
        buffer.removeRange(0, kAudioPcmChunkBytes);
        _broadcastLocalAudioChunk(chunk);
      }
    });
  }

  // --- G.711 mu-law Codec ---
  static Uint8List encodeMuLaw(Uint8List pcm16) {
    final byteData = ByteData.sublistView(pcm16);
    final numSamples = pcm16.length ~/ 2;
    final muLaw = Uint8List(numSamples);
    for (int i = 0; i < numSamples; i++) {
      final sample = byteData.getInt16(i * 2, Endian.little);
      muLaw[i] = _linearToMuLaw(sample);
    }
    return muLaw;
  }

  static Uint8List decodeMuLaw(Uint8List muLaw) {
    final numSamples = muLaw.length;
    final pcm16 = Uint8List(numSamples * 2);
    final byteData = ByteData.sublistView(pcm16);
    for (int i = 0; i < numSamples; i++) {
      final sample = _muLawToLinear(muLaw[i]);
      byteData.setInt16(i * 2, sample, Endian.little);
    }
    return pcm16;
  }

  static int _linearToMuLaw(int sample) {
    const cBias = 0x84;
    const cClip = 32635;
    int sign = (sample >> 8) & 0x80;
    if (sign != 0) sample = -sample;
    if (sample > cClip) sample = cClip;
    sample += cBias;
    int exponent = 7;
    for (int expMask = 0x4000; (sample & expMask) == 0 && exponent > 0; exponent--, expMask >>= 1) {}
    int mantissa = (sample >> (exponent + 3)) & 0x0F;
    int muLaw = ~(sign | (exponent << 4) | mantissa);
    return muLaw & 0xFF;
  }

  static int _muLawToLinear(int muLawByte) {
    const cBias = 0x84;
    muLawByte = ~muLawByte;
    int sign = muLawByte & 0x80;
    int exponent = (muLawByte >> 4) & 0x07;
    int mantissa = muLawByte & 0x0F;
    int sample = ((mantissa << 3) + cBias) << exponent;
    sample -= cBias;
    return sign != 0 ? -sample : sample;
  }

  void stopVoiceCall() {
    _isCallActive = false;
    _activeCallId = null;
    _remoteAudioLevel = 0.0;
    _locallySentChunkTokens.clear();
    _callSignalSub?.cancel();
    _callSignalSub = null;

    // Reset active call session and leave channel
    ChatSocketService().setActiveCallSessionId(null);
    ChatSocketService().leaveCallChannel();

    if (!kIsWeb && Platform.isAndroid) {
      try {
        _channel.invokeMethod('stopVoiceCall');
      } catch (_) {}
    } else if (!kIsWeb && Platform.isLinux) {
      try {
        _linuxRecordSub?.cancel();
        _linuxRecordSub = null;
        _linuxRecordProcess?.kill();
        _linuxRecordProcess = null;
        _linuxPlayProcess?.kill();
        _linuxPlayProcess = null;
      } catch (_) {}
    }
  }
}
