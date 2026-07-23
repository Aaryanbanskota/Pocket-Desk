import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/error/global_error_boundary.dart';
import 'core/logging/app_logger.dart';
import 'core/services/notification_service.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await NotificationService.instance.initialize();
      AppLogger.setMinLevel(LogLevel.warning);
      AppLogger.i('PocketDesk [PROD] starting', tag: 'main');
      runApp(
        const ProviderScope(
          child: GlobalErrorBoundary(
            child: PocketDeskApp(),
          ),
        ),
      );
    },
    (error, stack) {
      AppLogger.fatal('Unhandled zone error', tag: 'main', error: error, st: stack);
    },
  );
}
