import 'package:flutter/material.dart';

import '../logging/app_logger.dart';

/// Catches unhandled widget-tree exceptions and displays a fallback UI.
///
/// Wrap the root widget with this to prevent a blank/crash screen.
class GlobalErrorBoundary extends StatefulWidget {
  const GlobalErrorBoundary({required this.child, super.key});

  final Widget child;

  @override
  State<GlobalErrorBoundary> createState() => _GlobalErrorBoundaryState();
}

class _GlobalErrorBoundaryState extends State<GlobalErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    // Override FlutterError handler to capture widget errors.
    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.e(
        'Unhandled Flutter error',
        tag: 'ErrorBoundary',
        error: details.exception,
        st: details.stack,
      );
      if (mounted) {
        setState(() {
          _error = details.exception;
          _stackTrace = details.stack;
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorFallbackScreen(
        error: _error!,
        stackTrace: _stackTrace,
        onRetry: () => setState(() {
          _error = null;
          _stackTrace = null;
        }),
      );
    }
    return widget.child;
  }
}

/// Full-screen fallback shown when an unhandled error is caught.
class _ErrorFallbackScreen extends StatelessWidget {
  const _ErrorFallbackScreen({
    required this.error,
    required this.onRetry,
    this.stackTrace,
  });

  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 72, color: theme.colorScheme.error),
                const SizedBox(height: 24),
                Text(
                  'Something went wrong',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  error.toString(),
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
