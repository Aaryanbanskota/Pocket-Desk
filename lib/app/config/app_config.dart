import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnvironment {
  development,
  production,
}

class AppConfig {
  final AppEnvironment environment;
  final String apiVersion;
  final int defaultSyncPort;
  final bool enableLogging;
  final bool enableDevTools;

  const AppConfig({
    required this.environment,
    this.apiVersion = 'v1',
    this.defaultSyncPort = 4040,
    required this.enableLogging,
    required this.enableDevTools,
  });

  factory AppConfig.fromEnvironment() {
    // Read environment variables passed via --dart-define or --dart-define-from-file
    const envString = String.fromEnvironment('APP_ENV', defaultValue: 'development');
    final environment = envString.toLowerCase() == 'production'
        ? AppEnvironment.production
        : AppEnvironment.development;

    const syncPortString = String.fromEnvironment('SYNC_PORT', defaultValue: '4040');
    final defaultSyncPort = int.tryParse(syncPortString) ?? 4040;

    final isDev = environment == AppEnvironment.development;

    const enableLoggingString = String.fromEnvironment('ENABLE_LOGGING');
    final enableLogging = enableLoggingString.isNotEmpty
        ? enableLoggingString.toLowerCase() == 'true'
        : isDev;

    const enableDevToolsString = String.fromEnvironment('ENABLE_DEV_TOOLS');
    final enableDevTools = enableDevToolsString.isNotEmpty
        ? enableDevToolsString.toLowerCase() == 'true'
        : isDev;

    return AppConfig(
      environment: environment,
      defaultSyncPort: defaultSyncPort,
      enableLogging: enableLogging,
      enableDevTools: enableDevTools,
    );
  }

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isProduction => environment == AppEnvironment.production;

  @override
  String toString() {
    return 'AppConfig(environment: $environment, apiVersion: $apiVersion, defaultSyncPort: $defaultSyncPort, enableLogging: $enableLogging, enableDevTools: $enableDevTools)';
  }
}

// Provider for global config access
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});
