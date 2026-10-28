import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/database/myday_database.dart';
import 'core/error/global_error_boundary.dart';
import 'core/logging/app_logger.dart';
import 'core/notifications/local_notification_service.dart';
import 'core/services/supabase_auth_service.dart';
import 'myday_app.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      try {
        await LocalNotificationService.initialize()
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        AppLogger.w('LocalNotificationService initialization non-fatal: $e');
      }

      AppLogger.setMinLevel(LogLevel.warning);
      AppLogger.i('MyDay starting', tag: 'main');

      try {
        await Supabase.initialize(
          url: SupabaseAuthService.supabaseUrl,
          anonKey: SupabaseAuthService.anonKey,
        ).timeout(const Duration(seconds: 4));
      } catch (e) {
        AppLogger.w('Supabase initialization offline/cached: $e');
      }

      final database = MyDayDatabase.create();
      try {
        await database.initDatabase().timeout(const Duration(seconds: 4));
      } catch (e) {
        AppLogger.e('Database schema initialization non-fatal: $e');
      }

      runApp(
        ProviderScope(
          child: GlobalErrorBoundary(
            child: MyDayApp(database: database),
          ),
        ),
      );
    },
    (error, stack) {
      AppLogger.fatal('Unhandled zone error',
          tag: 'main', error: error, st: stack);
    },
  );
}
