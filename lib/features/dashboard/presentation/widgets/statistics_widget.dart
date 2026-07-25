import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/presentation/providers/tasks_notifier.dart';
import '../../../calendar/data/models/recurrence_engine.dart';
import '../../../calendar/presentation/providers/calendar_events_notifier.dart';

class StatisticsWidget extends ConsumerWidget {
  const StatisticsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();

    final tasksAsync = ref.watch(tasksProvider);
    final eventsAsync = ref.watch(calendarEventsProvider);

    final doneTasksCount = tasksAsync.maybeWhen(
      data: (state) => state.tasks
          .where((t) => t.status == TaskStatus.done)
          .length,
      orElse: () => 0,
    );

    final weeklyEventsCount = eventsAsync.maybeWhen(
      data: (events) {
        final startOfWeek = DateTimeUtils.startOfWeek(now);
        final endOfWeek = DateTimeUtils.endOfWeek(now);
        return RecurrenceEngine.expandEvents(events, startOfWeek, endOfWeek).length;
      },
      orElse: () => 0,
    );

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(50),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Overview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  theme,
                  colorScheme,
                  '$doneTasksCount',
                  'Tasks done',
                  colorScheme.primary,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: colorScheme.outlineVariant.withAlpha(80),
                ),
                _buildStatColumn(
                  theme,
                  colorScheme,
                  '$weeklyEventsCount',
                  'Events',
                  colorScheme.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    ThemeData theme,
    ColorScheme colorScheme,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
