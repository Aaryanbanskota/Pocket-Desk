import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/presentation/providers/tasks_notifier.dart';
import '../../../tasks/presentation/widgets/task_form_sheet.dart';

class TasksWidget extends ConsumerWidget {
  const TasksWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tasksAsync = ref.watch(tasksProvider);

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
                  onPressed: () => context.push(AppRoutes.tasks),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            tasksAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(child: Text('Error loading tasks: $err')),
              data: (state) {
                // Show non-archived tasks on dashboard
                final tasks = state.tasks
                    .where((t) => t.status != TaskStatus.archived)
                    .toList();

                if (tasks.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.playlist_add_check_rounded,
                            size: 48,
                            color: colorScheme.onSurfaceVariant.withAlpha(100),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'No tasks for today',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Show top 4 tasks
                final displayedTasks = tasks.take(4).toList();

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedTasks.length,
                  separatorBuilder: (_, __) => Divider(
                    color: colorScheme.outlineVariant.withAlpha(30),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final task = displayedTasks[index];
                    final isCompleted = task.status == TaskStatus.done;

                    return InkWell(
                      onTap: () {
                        // Open task preview dialog
                        showDialog<void>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      decoration: isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Edit',
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    TaskFormSheet.show(context, task: task);
                                  },
                                ),
                              ],
                            ),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (task.description != null &&
                                      task.description!.isNotEmpty) ...[
                                    Text(
                                      task.description!,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      if (task.priority != TaskPriority.none)
                                        Chip(
                                          label: Text(task.priority.name),
                                          padding: EdgeInsets.zero,
                                        ),
                                      if (task.dueDate != null)
                                        Chip(
                                          avatar: const Icon(Icons.calendar_today_outlined, size: 14),
                                          label: Text('Due: ${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}'),
                                          padding: EdgeInsets.zero,
                                        ),
                                      if (task.listName != null && task.listName!.isNotEmpty)
                                        Chip(
                                          avatar: const Icon(Icons.list_outlined, size: 14),
                                          label: Text(task.listName!),
                                          padding: EdgeInsets.zero,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Close'),
                              ),
                              FilledButton.icon(
                                onPressed: () {
                                  ref.read(tasksProvider.notifier).updateStatus(
                                        task.id,
                                        isCompleted
                                            ? TaskStatus.todo
                                            : TaskStatus.done,
                                      );
                                  Navigator.pop(ctx);
                                },
                                icon: Icon(isCompleted ? Icons.undo : Icons.check),
                                label: Text(isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
                              ),
                            ],
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                          horizontal: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                isCompleted
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: isCompleted
                                    ? colorScheme.primary
                                    : colorScheme.outline,
                                size: 20,
                              ),
                              onPressed: () {
                                ref.read(tasksProvider.notifier).updateStatus(
                                      task.id,
                                      isCompleted
                                          ? TaskStatus.todo
                                          : TaskStatus.done,
                                    );
                              },
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                task.title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isCompleted
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              tooltip: 'Edit Task',
                              onPressed: () => TaskFormSheet.show(context, task: task),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              tooltip: 'Delete Task',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Task?'),
                                    content: Text('Are you sure you want to delete "${task.title}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref.read(tasksProvider.notifier).deleteTask(task.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
