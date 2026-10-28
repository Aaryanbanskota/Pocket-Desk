import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CallAudioService {
  static final CallAudioService instance = CallAudioService._internal();
  factory CallAudioService() => instance;
  CallAudioService._internal();

  AudioPlayer? _keypadPlayer;
  AudioPlayer? _ringtonePlayer;
  AudioPlayer? _dialingPlayer;
  AudioPlayer? _sfxPlayer;

  Process? _keypadProcess;
  Process? _ringtoneProcess;
  Process? _dialingProcess;
  Process? _sfxProcess;

  bool isAudioEnabled = true;

  /// Resolves local sound file path dynamically across desktop and package environments
  static String? _resolveSoundPath(String filename) {
    if (kIsWeb) return null;
    final candidates = [
      'assets/sounds/$filename',
      'assets/sounds/dtmf/$filename',
      '${Directory.current.path}/assets/sounds/$filename',
      '${Directory.current.path}/assets/sounds/dtmf/$filename',
      '${File(Platform.resolvedExecutable).parent.path}/data/flutter_assets/assets/sounds/$filename',
      '${File(Platform.resolvedExecutable).parent.path}/data/flutter_assets/assets/sounds/dtmf/$filename',
      '${File(Platform.resolvedExecutable).parent.path}/assets/sounds/$filename',
      '${File(Platform.resolvedExecutable).parent.path}/assets/sounds/dtmf/$filename',
    ];
    for (final p in candidates) {
      if (File(p).existsSync()) return p;
    }
    return null;
  }

  /// Helper to drain stdout and stderr from helper processes so pipes never fill and hang
  static void _drainProcessOutputs(Process proc) {
    proc.stdout.drain<void>().catchError((_) {});
    proc.stderr.drain<void>().catchError((_) {});
  }

  /// Resolves the DTMF filename for a given character ('0'-'9', '*', '#')
  static String _dtmfFilename(String? key) {
    if (key == null || key.isEmpty) return 'dtmf_0.mp3';
    final trimmed = key.trim();
    if (trimmed == '*') return 'dtmf_star.mp3';
    if (trimmed == '#') return 'dtmf_hash.mp3';
    if (RegExp(r'^[0-9]$').hasMatch(trimmed)) return 'dtmf_$trimmed.mp3';
    return 'dtmf_0.mp3';
  }

  /// Plays authentic DTMF tone when tapping any dialpad number key.
  /// If another tone is currently playing, immediately interrupts it for zero-latency response.
  Future<void> playDialpadTone([String? key]) async {
    HapticFeedback.lightImpact();
    if (!isAudioEnabled) return;

    final filename = _dtmfFilename(key);

    // Desktop Linux native playback - avoids MissingPluginException when running without recompilation
    if (!kIsWeb && Platform.isLinux) {
      try {
        _keypadProcess?.kill();
        _keypadProcess = null;

        final path = _resolveSoundPath(filename) ??
            _resolveSoundPath('dialing_numbers.mp3') ??
            _resolveSoundPath('dial_tone.mp3');

        if (path != null) {
          try {
            final proc = await Process.start('pw-play', [path]);
            _drainProcessOutputs(proc);
            _keypadProcess = proc;
            return;
          } catch (_) {
            final proc = await Process.start('ffplay', [
              '-nodisp',
              '-autoexit',
              '-loglevel',
              'quiet',
              '-nostats',
              path,
            ]);
            _drainProcessOutputs(proc);
            _keypadProcess = proc;
            return;
          }
        }
      } catch (_) {}
    }

    // Android / iOS / Cross-platform AudioPlayer fallback
    try {
      _keypadPlayer ??= AudioPlayer();
      await _keypadPlayer!.stop();
      await _keypadPlayer!.setVolume(0.85);
      await _keypadPlayer!.play(AssetSource('sounds/$filename'));
    } catch (_) {
      try {
        await _keypadPlayer?.play(AssetSource('sounds/dtmf/$filename'));
      } catch (_) {
        try {
          SystemSound.play(SystemSoundType.click);
        } catch (_) {}
      }
    }
  }

  /// Plays incoming call ringtone in continuous loop until answered or declined.
  /// Uses downloaded classic phone ring (classic_ring.mp3 / ringtone.mp3).
  Future<void> startRingtone() async {
    if (!isAudioEnabled) return;

    if (!kIsWeb && Platform.isLinux) {
      try {
        _ringtoneProcess?.kill();
        _ringtoneProcess = null;

        final path = _resolveSoundPath('classic_ring.mp3') ??
            _resolveSoundPath('ringtone.mp3') ??
            _resolveSoundPath('lively_ring.mp3');

        if (path != null) {
          try {
            final proc = await Process.start('ffplay', [
              '-nodisp',
              '-loop',
              '0',
              '-loglevel',
              'quiet',
              '-nostats',
              path,
            ]);
            _drainProcessOutputs(proc);
            _ringtoneProcess = proc;
            return;
          } catch (_) {
            final proc = await Process.start('pw-play', [path]);
            _drainProcessOutputs(proc);
            _ringtoneProcess = proc;
            return;
          }
        }
      } catch (_) {}
    }

    try {
      _ringtonePlayer ??= AudioPlayer();
      await _ringtonePlayer!.stop();
      await _ringtonePlayer!.setReleaseMode(ReleaseMode.loop);
      await _ringtonePlayer!.setVolume(1.0);
      await _ringtonePlayer!.play(AssetSource('sounds/classic_ring.mp3'));
    } catch (e) {
      debugPrint('CallAudioService startRingtone error: $e');
      try {
        await _ringtonePlayer?.play(AssetSource('sounds/ringtone.mp3'));
      } catch (_) {}
    }
  }

  /// Stops incoming call ringtone
  Future<void> stopRingtone() async {
    if (!kIsWeb && Platform.isLinux) {
      try {
        _ringtoneProcess?.kill();
        _ringtoneProcess = null;
      } catch (_) {}
    }
    try {
      await _ringtonePlayer?.stop();
    } catch (_) {}
  }

  /// Plays outgoing call ringback / dialing tone until connected.
  /// Uses downloaded patient waiting loop (call_dialing.mp3 / waiting_loop.mp3).
  Future<void> startDialingTone() async {
    if (!isAudioEnabled) return;

    if (!kIsWeb && Platform.isLinux) {
      try {
        _dialingProcess?.kill();
        _dialingProcess = null;

        final path = _resolveSoundPath('call_dialing.mp3') ??
            _resolveSoundPath('waiting_loop.mp3');

        if (path != null) {
          try {
            final proc = await Process.start('ffplay', [
              '-nodisp',
              '-loop',
              '0',
              '-loglevel',
              'quiet',
              '-nostats',
              path,
            ]);
            _drainProcessOutputs(proc);
            _dialingProcess = proc;
            return;
          } catch (_) {
            final proc = await Process.start('pw-play', [path]);
            _drainProcessOutputs(proc);
            _dialingProcess = proc;
            return;
          }
        }
      } catch (_) {}
    }

    try {
      _dialingPlayer ??= AudioPlayer();
      await _dialingPlayer!.stop();
      await _dialingPlayer!.setReleaseMode(ReleaseMode.loop);
      await _dialingPlayer!.setVolume(0.8);
      await _dialingPlayer!.play(AssetSource('sounds/call_dialing.mp3'));
    } catch (e) {
      debugPrint('CallAudioService startDialingTone error: $e');
    }
  }

  /// Stops outgoing call dialing tone
  Future<void> stopDialingTone() async {
    if (!kIsWeb && Platform.isLinux) {
      try {
        _dialingProcess?.kill();
        _dialingProcess = null;
      } catch (_) {}
    }
    try {
      await _dialingPlayer?.stop();
    } catch (_) {}
  }

  /// Plays busy / call ended signal tone
  Future<void> playBusySignal() async {
    if (!isAudioEnabled) return;

    if (!kIsWeb && Platform.isLinux) {
      try {
        _sfxProcess?.kill();
        _sfxProcess = null;

        final path = _resolveSoundPath('busy_signal.mp3');
        if (path != null) {
          try {
            final proc = await Process.start('pw-play', [path]);
            _drainProcessOutputs(proc);
            _sfxProcess = proc;
            return;
          } catch (_) {
            final proc = await Process.start('ffplay', [
              '-nodisp',
              '-autoexit',
              '-loglevel',
              'quiet',
              '-nostats',
              path,
            ]);
            _drainProcessOutputs(proc);
            _sfxProcess = proc;
            return;
          }
        }
      } catch (_) {}
    }

    try {
      _sfxPlayer ??= AudioPlayer();
      await _sfxPlayer!.stop();
      await _sfxPlayer!.setVolume(0.85);
      await _sfxPlayer!.play(AssetSource('sounds/busy_signal.mp3'));
    } catch (_) {}
  }

  /// Plays chat message notification ding sound (ding.mp3 / message_ding.mp3)
  Future<void> playMessageDing() async {
    if (!isAudioEnabled) return;

    if (!kIsWeb && Platform.isLinux) {
      try {
        _sfxProcess?.kill();
        _sfxProcess = null;

        final path = _resolveSoundPath('message_ding.mp3') ??
            _resolveSoundPath('ding.mp3') ??
            _resolveSoundPath('notification.mp3');

        if (path != null) {
          try {
            final proc = await Process.start('pw-play', [path]);
            _drainProcessOutputs(proc);
            _sfxProcess = proc;
            return;
          } catch (_) {
            final proc = await Process.start('ffplay', [
              '-nodisp',
              '-autoexit',
              '-loglevel',
              'quiet',
              '-nostats',
              path,
            ]);
            _drainProcessOutputs(proc);
            _sfxProcess = proc;
            return;
          }
        }
      } catch (_) {}
    }

    try {
      _sfxPlayer ??= AudioPlayer();
      await _sfxPlayer!.stop();
      await _sfxPlayer!.setVolume(0.9);
      await _sfxPlayer!.play(AssetSource('sounds/message_ding.mp3'));
    } catch (_) {
      try {
        await _sfxPlayer?.play(AssetSource('sounds/ding.mp3'));
      } catch (_) {}
    }
  }

  /// Stops all audio players and processes immediately
  Future<void> stopAll() async {
    await stopRingtone();
    await stopDialingTone();
    try {
      _keypadProcess?.kill();
      _keypadProcess = null;
    } catch (_) {}
    try {
      _sfxProcess?.kill();
      _sfxProcess = null;
    } catch (_) {}
    try {
      await _keypadPlayer?.stop();
      await _sfxPlayer?.stop();
    } catch (_) {}
  }
}
