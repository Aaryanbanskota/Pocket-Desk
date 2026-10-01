import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final networkConnectivityProvider = StreamProvider<bool>((ref) {
  final controller = StreamController<bool>();
  
  // Initial check
  Future<void> checkConnection() async {
    try {
      final result = await InternetAddress.lookup('dns.google').timeout(const Duration(seconds: 3));
      if (controller.isClosed) return;
      controller.add(result.isNotEmpty && result[0].rawAddress.isNotEmpty);
    } catch (_) {
      if (controller.isClosed) return;
      controller.add(false);
    }
  }

  checkConnection();

  // Periodic heartbeat every 5 seconds
  final timer = Timer.periodic(const Duration(seconds: 5), (_) {
    checkConnection();
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
