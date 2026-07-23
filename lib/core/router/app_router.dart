import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/calendar/presentation/pages/calendar_dashboard_view.dart';
import '../../features/tasks/presentation/pages/tasks_dashboard_view.dart';
import 'app_routes.dart';

part 'app_router.g.dart';

// ---------------------------------------------------------------------------
// Placeholder screens (replaced in later milestones)
// ---------------------------------------------------------------------------

class _SplashPage extends StatelessWidget {
  const _SplashPage();
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}



class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('404', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 16),
              Text('Page not found',
                  style: Theme.of(context).textTheme.bodyLarge),
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

// ---------------------------------------------------------------------------
// Router provider — auth-aware redirect
// ---------------------------------------------------------------------------

@riverpod
GoRouter appRouter(Ref ref) {
  final authAsync = ref.watch(authNotifierProvider);

  final isAuthenticated = authAsync.maybeWhen(
    data: (state) => state is AuthAuthenticated,
    orElse: () => false,
  );

  final isLoading = authAsync.maybeWhen(
    loading: () => true,
    data: (state) => state is AuthLoading,
    orElse: () => false,
  );

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    errorBuilder: (context, state) => const _NotFoundPage(),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.calendar,
        builder: (context, state) => const CalendarDashboardView(),
      ),
      GoRoute(
        path: AppRoutes.tasks,
        builder: (context, state) => const TasksDashboardView(),
      ),
      GoRoute(
        path: AppRoutes.settingsProfile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.notFound,
        builder: (context, state) => const _NotFoundPage(),
      ),
    ],
    redirect: (context, state) {
      if (isLoading) return AppRoutes.splash;

      final onAuthPage = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.splash;

      if (!isAuthenticated && !onAuthPage) return AppRoutes.login;
      if (isAuthenticated && onAuthPage) return AppRoutes.dashboard;
      return null;
    },
  );
}
