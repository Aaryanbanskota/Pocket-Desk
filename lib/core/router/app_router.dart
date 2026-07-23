import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_routes.dart';

part 'app_router.g.dart';

// ---------------------------------------------------------------------------
// Placeholder screens (replaced by real screens as milestones complete)
// ---------------------------------------------------------------------------

class _SplashPage extends StatelessWidget {
  const _SplashPage();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _LoginPage extends StatelessWidget {
  const _LoginPage();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Login',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Dashboard',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ),
    );
  }
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('404', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

@riverpod
GoRouter appRouter(Ref ref) {
  // TODO(auth): Replace with real auth state notifier in Milestone 2.
  // Currently always unauthenticated → routes to login.
  const isAuthenticated = false;

  return GoRouter(
    initialLocation: isAuthenticated ? AppRoutes.dashboard : AppRoutes.login, // ignore: dead_code
    debugLogDiagnostics: false,
    errorBuilder: (context, state) => const _NotFoundPage(),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const _LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const _DashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.notFound,
        builder: (context, state) => const _NotFoundPage(),
      ),
    ],
    redirect: (context, state) {
      final onLoginPage = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      if (!isAuthenticated && !onLoginPage) {
        return AppRoutes.login;
      }
      return null;
    },
  );
}
