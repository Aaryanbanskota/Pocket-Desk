import 'dart:async';

enum PlayerState { playing, paused, stopped, completed }

class DeviceFileSource {
  final String path;
  const DeviceFileSource(this.path);
}

class AudioPlayer {
  Stream<Duration> get onDurationChanged => const Stream.empty();
  Stream<Duration> get onPositionChanged => const Stream.empty();
  Stream<PlayerState> get onPlayerStateChanged => const Stream.empty();

  Future<void> setSource(dynamic source) async {}
  Future<void> play(dynamic source) async {}
  Future<void> pause() async {}
  Future<void> resume() async {}
  Future<void> stop() async {}
  Future<void> seek(Duration position) async {}
  void dispose() {}
}
