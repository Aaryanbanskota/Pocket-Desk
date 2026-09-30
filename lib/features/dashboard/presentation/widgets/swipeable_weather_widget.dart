import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/services/account_plan_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../calendar/data/models/calendar_event_model.dart';
import '../../../calendar/presentation/providers/calendar_events_notifier.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/presentation/providers/tasks_notifier.dart';

class MouseScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class SwipeableWeatherWidget extends StatefulWidget {
  const SwipeableWeatherWidget({super.key});

  @override
  State<SwipeableWeatherWidget> createState() => _SwipeableWeatherWidgetState();
}

class _SwipeableWeatherWidgetState extends State<SwipeableWeatherWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        SizedBox(
          height: 154,
          child: ScrollConfiguration(
            behavior: MouseScrollBehavior(),
            child: PageView(
              controller: _pageController,
              onPageChanged: (idx) {
                setState(() => _currentPage = idx);
              },
              children: const [
                WeatherWidget(),
                ProgressStorageWidget(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _currentPage == 0 ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == 0
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _currentPage == 1 ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == 1
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class WeatherWidget extends StatelessWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '24°C Sunny',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kathmandu, Nepal • Clear Sky',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.swipe_left_rounded, color: colorScheme.primary.withAlpha(150), size: 22),
        ],
      ),
    );
  }
}

class ProgressStorageWidget extends ConsumerWidget {
  const ProgressStorageWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final planState = ref.watch(accountPlanProvider);
    final tasksState = ref.watch(tasksProvider).valueOrNull;
    final eventsAsync = ref.watch(calendarEventsProvider);
    final eventsState = eventsAsync.valueOrNull ?? <CalendarEventModel>[];

    final tasks = tasksState?.tasks ?? [];
    final totalTasks = tasks.length;
    final completedTasks = tasks.where((t) => t.status == TaskStatus.done).length;
    final taskProgress = totalTasks > 0 ? (completedTasks / totalTasks).clamp(0.0, 1.0) : 0.0;

    final isCloud = planState.accountType == AccountType.cloud;

    // Upcoming important event calculation
    final now = DateTime.now();
    final upcomingEvents = eventsState
        .where((e) => e.startTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final nextEvent = upcomingEvents.isNotEmpty ? upcomingEvents.first : null;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                isCloud ? Icons.cloud_done_rounded : Icons.storage_rounded,
                color: colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isCloud
                      ? 'Cloud Plan (${planState.cloudPlan == CloudPlan.free ? "Free Tier" : "Pro 10GB"})'
                      : 'Local Plan (Unlimited Storage)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.subscriptionPlan),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium_rounded, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Cloud Pro',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 1. Task Completion Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Task Completion',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '$completedTasks / $totalTasks done (${(taskProgress * 100).toInt()}%)',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: taskProgress,
              minHeight: 5,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),

          const SizedBox(height: 6),

          // 2. Storage / Backup Info OR Next Event Banner
          if (nextEvent != null)
            Row(
              children: [
                Icon(Icons.event_note_rounded, size: 14, color: colorScheme.secondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Next: ${nextEvent.title} (${nextEvent.startTime.day}/${nextEvent.startTime.month} at ${nextEvent.startTime.hour.toString().padLeft(2, '0')}:${nextEvent.startTime.minute.toString().padLeft(2, '0')})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: colorScheme.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isCloud ? 'Cloud Sync Status' : 'Local Storage Mode',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  isCloud
                      ? (planState.cloudPlan == CloudPlan.free ? '500MB Free Cloud' : '10GB Pro Cloud')
                      : 'Unlimited Local (No Online Backup)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: isCloud ? Colors.green : Colors.amber.shade900,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
