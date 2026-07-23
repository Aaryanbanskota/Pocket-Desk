import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class TasksWidget extends StatelessWidget {
  const TasksWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    const mockTasks = [
      _TaskMock(title: 'Review codebase security standards', completed: false),
      _TaskMock(title: 'Design database schema additions', completed: true),
      _TaskMock(title: 'Setup routing tests', completed: false),
    ];

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tasks',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mockTasks.length,
              separatorBuilder: (_, __) => Divider(
                color: colorScheme.outlineVariant.withAlpha(30),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final task = mockTasks[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Icon(
                        task.completed
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: task.completed ? colorScheme.primary : colorScheme.outline,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          task.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            decoration: task.completed ? TextDecoration.lineThrough : null,
                            color: task.completed ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskMock {
  const _TaskMock({
    required this.title,
    required this.completed,
  });

  final String title;
  final bool completed;
}
