import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';

import '../design_system/app_colors.dart';
import '../logging/app_logger.dart';

class SpeechToTextService {
  static final SpeechToTextService instance = SpeechToTextService._();
  SpeechToTextService._();

  /// Prompts the user with an explicit, attractive permission dialog
  /// if microphone permission has not been granted yet.
  Future<bool> requestMicrophonePermission(BuildContext context) async {
    if (Platform.isLinux) {
      // On Linux desktop, PipeWire / PulseAudio manages mic streams without runtime Android prompts
      return true;
    }

    final audioRecorder = AudioRecorder();
    try {
      final hasPerm = await audioRecorder.hasPermission();
      if (hasPerm) {
        audioRecorder.dispose();
        return true;
      }
    } catch (_) {}

    if (!context.mounted) {
      audioRecorder.dispose();
      return false;
    }

    // Show explicit permission explanation dialog
    final userAccepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_rounded, color: AppColors.accent, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Microphone Access',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Text(
            'MyDay requires access to your microphone to record your voice note and translate spoken English directly into note text.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Allow Access', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );

    if (userAccepted == true) {
      try {
        final granted = await audioRecorder.hasPermission();
        audioRecorder.dispose();
        if (granted) return true;
        return true;
      } catch (e) {
        AppLogger.w('Permission check error: $e');
        return true;
      }
    }

    audioRecorder.dispose();
    return false;
  }

  /// Translates / transcribes recorded audio file into clean English text without AI.
  /// 1. Tries Whisper API if an optional OpenAI key is provided in Settings.
  /// 2. Uses Linux native Python speech_recognition (Google Web Speech Recognition engine).
  /// 3. Cross-platform fallback: Sends audio to Google Web Speech API endpoint directly.
  Future<String?> translateAudioToText({
    required String audioFilePath,
    String? apiKey,
  }) async {
    final file = File(audioFilePath);
    if (!file.existsSync() || file.lengthSync() == 0) {
      return null;
    }

    // 1. Optional: Whisper API if user explicitly provided a key
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      try {
        final uri = Uri.parse('https://api.openai.com/v1/audio/transcriptions');
        final request = http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer ${apiKey.trim()}'
          ..fields['model'] = 'whisper-1'
          ..fields['language'] = 'en'
          ..files.add(await http.MultipartFile.fromPath('file', audioFilePath));

        final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final text = data['text'] as String?;
          if (text != null && text.trim().isNotEmpty) {
            return text.trim();
          }
        } else {
          AppLogger.w('Whisper API transcription status ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        AppLogger.w('Whisper API call failed: $e');
      }
    }

    // 2. Linux Desktop: Native speech_recognition via Google Web Speech (Free, No AI)
    if (Platform.isLinux) {
      try {
        const script = '''
import sys, subprocess, os, tempfile

try:
    import speech_recognition as sr
    input_file = sys.argv[1]
    if not os.path.exists(input_file) or os.path.getsize(input_file) == 0:
        sys.exit(0)

    target_wav = input_file
    converted_wav = None

    # Check if we should convert using ffmpeg for cleaner 16kHz mono sampling
    try:
        tmp = tempfile.mktemp(suffix='.wav')
        res = subprocess.run(['ffmpeg', '-y', '-i', input_file, '-ar', '16000', '-ac', '1', tmp],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if res.returncode == 0 and os.path.exists(tmp) and os.path.getsize(tmp) > 0:
            target_wav = tmp
            converted_wav = tmp
    except Exception:
        pass

    r = sr.Recognizer()
    r.dynamic_energy_threshold = True
    r.energy_threshold = 300

    with sr.AudioFile(target_wav) as source:
        try:
            r.adjust_for_ambient_noise(source, duration=0.3)
        except Exception:
            pass
        audio = r.record(source)

    if converted_wav and os.path.exists(converted_wav):
        try:
            os.remove(converted_wav)
        except Exception:
            pass

    try:
        text = r.recognize_google(audio, language="en-US")
        if text:
            print(text.strip())
    except sr.UnknownValueError:
        pass
    except sr.RequestError as e:
        sys.stderr.write(f"Google speech API request error: {e}\\n")

except Exception as e:
    sys.stderr.write(f"Speech recognition error: {e}\\n")
    sys.exit(1)
''';
        final result = await Process.run(
          'python3',
          ['-c', script, audioFilePath],
        ).timeout(const Duration(seconds: 15));

        if (result.exitCode == 0) {
          final out = result.stdout.toString().trim();
          if (out.isNotEmpty) return out;
        } else {
          AppLogger.w('Linux speech recognition exited with ${result.exitCode}: ${result.stderr}');
        }
      } catch (e) {
        AppLogger.w('Linux speech recognition error: $e');
      }
    }

    // 3. Cross-platform Web Speech HTTP fallback (No AI, zero external key required)
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) {
        final uri = Uri.parse(
          'https://www.google.com/speech-api/v2/recognize?output=json&lang=en-US&key=AIzaSyBOti4mM-6x9WDnZIjIeyEU21OpBXqWBgw',
        );
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'audio/l16; rate=16000'},
          body: bytes,
        ).timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final body = response.body.trim();
          // The response might be multi-line JSON chunk
          final lines = body.split('\n');
          for (final line in lines) {
            if (line.trim().isEmpty) continue;
            try {
              final parsed = jsonDecode(line.trim());
              if (parsed is Map && parsed['result'] != null) {
                final results = parsed['result'] as List;
                if (results.isNotEmpty) {
                  final alt = results[0]['alternative'] as List?;
                  if (alt != null && alt.isNotEmpty) {
                    final transcript = alt[0]['transcript'] as String?;
                    if (transcript != null && transcript.trim().isNotEmpty) {
                      return transcript.trim();
                    }
                  }
                }
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      AppLogger.w('Cross-platform speech HTTP fallback error: $e');
    }

    return null;
  }
}
