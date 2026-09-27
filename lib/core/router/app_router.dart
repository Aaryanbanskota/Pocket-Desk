import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/qr_login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/setup_onboarding_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/calendar/presentation/pages/calendar_dashboard_view.dart';
import '../../features/tasks/presentation/pages/tasks_dashboard_view.dart';
import '../../features/notes/presentation/pages/notes_dashboard_view.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/file_share/presentation/pages/file_share_page.dart';
import '../../features/posts/presentation/pages/posts_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/money_tracker/presentation/pages/money_tracker_page.dart';
import '../../features/clock/presentation/pages/clock_page.dart';
import '../../features/settings/presentation/pages/about_app_page.dart';
import '../../features/settings/presentation/pages/legal_document_page.dart';
import '../../features/trash/presentation/pages/trash_page.dart';
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
        path: AppRoutes.qrLogin,
        builder: (context, state) => const QrLoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.setupOnboarding,
        builder: (context, state) => const SetupOnboardingPage(),
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
        path: AppRoutes.notes,
        builder: (context, state) => const NotesDashboardView(),
      ),
      GoRoute(
        path: AppRoutes.settingsProfile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.fileShare,
        builder: (context, state) => const FileSharePage(),
      ),
      GoRoute(
        path: AppRoutes.posts,
        builder: (context, state) => const PostsPage(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) => const ChatPage(),
      ),
      GoRoute(
        path: AppRoutes.moneyTracker,
        builder: (context, state) => const MoneyTrackerPage(),
      ),
      GoRoute(
        path: AppRoutes.clock,
        builder: (context, state) => const ClockPage(),
      ),
      GoRoute(
        path: AppRoutes.aboutApp,
        builder: (context, state) => const AboutAppPage(),
      ),
      GoRoute(
        path: AppRoutes.termsAndConditions,
        builder: (context, state) => const TermsAndConditionsPage(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: AppRoutes.licenses,
        builder: (context, state) => const PocketDeskLicensesPage(),
      ),
      GoRoute(
        path: AppRoutes.trash,
        builder: (context, state) => const TrashPage(),
      ),
      GoRoute(
        path: AppRoutes.notFound,
        builder: (context, state) => const _NotFoundPage(),
      ),
    ],
    redirect: (context, state) {
      if (isLoading) return AppRoutes.splash;

      final location = state.matchedLocation;
      final authState = authAsync.valueOrNull;
      final isNewRegistration =
          authState is AuthAuthenticated && authState.isNewRegistration;

      final onAuthPage = location == AppRoutes.login ||
          location == AppRoutes.qrLogin ||
          location == AppRoutes.register;

      // 1. Unauthenticated users must be on login or register
      if (!isAuthenticated) {
        if (onAuthPage) return null;
        return AppRoutes.login;
      }

      // 2. Authenticated users on splash screen
      if (location == AppRoutes.splash) {
        return isNewRegistration
            ? AppRoutes.setupOnboarding
            : AppRoutes.dashboard;
      }

      // 3. Authenticated users submitting login or register forms
      if (onAuthPage) {
        return isNewRegistration
            ? AppRoutes.setupOnboarding
            : AppRoutes.dashboard;
      }

      // 4. Authenticated users already on setup page or inner dashboard pages
      return null;
    },
  );
}
