import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../widgets/calendar_mini_widget.dart';
import '../widgets/notes_widget.dart';
import '../widgets/pinned_widgets.dart';
import '../widgets/quick_actions.dart';
import '../widgets/statistics_widget.dart';
import '../widgets/tasks_widget.dart';
import '../widgets/today_schedule_widget.dart';
import '../widgets/weather_widget.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authNotifierProvider).valueOrNull;
    final user = authState is AuthAuthenticated ? authState.user : null;

    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width > 1000;
    final isTablet = width > 600 && width <= 1000;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PocketDesk',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
              ),
            ),
            Text(
              DateTimeUtils.toFullDate(DateTime.now()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profile',
            onPressed: () => context.push(AppRoutes.settingsProfile),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(theme, user?.displayName ?? user?.username ?? 'User'),
              const SizedBox(height: AppSpacing.md),
              const WeatherWidget(),
              const SizedBox(height: AppSpacing.lg),
              const QuickActions(),
              const SizedBox(height: AppSpacing.xl),
              if (isDesktop)
                _buildDesktopLayout()
              else if (isTablet)
                _buildTabletLayout()
              else
                _buildMobileLayout(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(ThemeData theme, String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, $name',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'Here is your productivity overview for today.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              TodayScheduleWidget(),
              SizedBox(height: AppSpacing.lg),
              TasksWidget(),
              SizedBox(height: AppSpacing.lg),
              NotesWidget(),
            ],
          ),
        ),
        SizedBox(width: AppSpacing.lg),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              CalendarMiniWidget(),
              SizedBox(height: AppSpacing.lg),
              StatisticsWidget(),
              SizedBox(height: AppSpacing.lg),
              PinnedWidgets(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return const Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: TodayScheduleWidget()),
            SizedBox(width: AppSpacing.lg),
            Expanded(child: CalendarMiniWidget()),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: TasksWidget()),
            SizedBox(width: AppSpacing.lg),
            Expanded(child: NotesWidget()),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: StatisticsWidget()),
            SizedBox(width: AppSpacing.lg),
            Expanded(child: PinnedWidgets()),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return const Column(
      children: [
        TodayScheduleWidget(),
        SizedBox(height: AppSpacing.lg),
        CalendarMiniWidget(),
        SizedBox(height: AppSpacing.lg),
        TasksWidget(),
        SizedBox(height: AppSpacing.lg),
        NotesWidget(),
        SizedBox(height: AppSpacing.lg),
        StatisticsWidget(),
        SizedBox(height: AppSpacing.lg),
        PinnedWidgets(),
      ],
    );
  }
}
