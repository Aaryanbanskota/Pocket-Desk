import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

/// Log levels for structured logging.
enum LogLevel { verbose, debug, info, warning, error, fatal }

/// Central logger for PocketDesk.
///
/// In debug mode: prints to console.
/// In production: writes to local crash log file (file I/O added when
/// path_provider is initialised in the bootstrap phase).
abstract final class AppLogger {
  static LogLevel _minLevel =
      kDebugMode ? LogLevel.verbose : LogLevel.warning;

  static void setMinLevel(LogLevel level) => _minLevel = level;

  static void v(String message, {String? tag, Object? error, StackTrace? st}) =>
      _log(LogLevel.verbose, message, tag: tag, error: error, st: st);

  static void d(String message, {String? tag, Object? error, StackTrace? st}) =>
      _log(LogLevel.debug, message, tag: tag, error: error, st: st);

  static void i(String message, {String? tag, Object? error, StackTrace? st}) =>
      _log(LogLevel.info, message, tag: tag, error: error, st: st);

  static void w(String message, {String? tag, Object? error, StackTrace? st}) =>
      _log(LogLevel.warning, message, tag: tag, error: error, st: st);

  static void e(String message, {String? tag, Object? error, StackTrace? st}) =>
      _log(LogLevel.error, message, tag: tag, error: error, st: st);

  static void fatal(String message,
          {String? tag, Object? error, StackTrace? st}) =>
      _log(LogLevel.fatal, message, tag: tag, error: error, st: st);

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? st,
  }) {
    if (level.index < _minLevel.index) return;

    final prefix = _prefix(level);
    final scope = tag != null ? '[$tag] ' : '';
    final timestamp = DateTime.now().toIso8601String();
    final line = '$timestamp $prefix $scope$message';

    dev.log(
      line,
      name: 'PocketDesk',
      level: _dartLogLevel(level),
      error: error,
      stackTrace: st,
    );
  }

  static String _prefix(LogLevel level) => switch (level) {
        LogLevel.verbose => '🔍 VERBOSE',
        LogLevel.debug => '🐛 DEBUG  ',
        LogLevel.info => 'ℹ️  INFO   ',
        LogLevel.warning => '⚠️  WARN   ',
        LogLevel.error => '❌ ERROR  ',
        LogLevel.fatal => '💥 FATAL  ',
      };

  static int _dartLogLevel(LogLevel level) => switch (level) {
        LogLevel.verbose => 0,
        LogLevel.debug => 300,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
        LogLevel.fatal => 1200,
      };
}
