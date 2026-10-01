import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/task_model.dart';
import '../providers/tasks_notifier.dart';
import 'task_form_sheet.dart';

/// Displays a single task card with swipe-to-complete and long-press-to-delete.
class TaskCard extends ConsumerWidget {
  const TaskCard({super.key, required this.task});
  final TaskModel task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final notifier = ref.read(tasksProvider.notifier);
    final isDone = task.status == TaskStatus.done;

    return Dismissible(
      key: ValueKey(task.id),
      background: _swipeBg(cs, done: true),
      secondaryBackground: _swipeBg(cs, done: false),
      onDismissed: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          await notifier.updateStatus(task.id, TaskStatus.done);
        } else {
          await notifier.deleteTask(task.id);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showTaskPreview(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () => notifier.updateStatus(
                    task.id,
                    isDone ? TaskStatus.todo : TaskStatus.done,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 2, right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? cs.primary : Colors.transparent,
                      border: Border.all(
                        color: isDone ? cs.primary : cs.outline,
                        width: 2,
                      ),
                    ),
                    child: isDone
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: tt.bodyMedium?.copyWith(
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          decorationThickness: 2.0,
                          decorationColor: cs.primary,
                          color: isDone ? cs.onSurfaceVariant : cs.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (task.description != null &&
                          task.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            task.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              decoration:
                                  isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (isDone)
                            _InfoChip(
                              icon: Icons.check_circle_rounded,
                              label: 'Completed',
                              color: cs.tertiary,
                            ),
                          if (task.priority != TaskPriority.none)
                            _PriorityBadge(task.priority),
                          if (task.dueDate != null)
                            _InfoChip(
                              icon: Icons.calendar_today_outlined,
                              label: _formatDate(task.dueDate!),
                              color: _isOverdue(task.dueDate!) && !isDone
                                  ? cs.error
                                  : cs.onSurfaceVariant,
                            ),
                          if (task.listName != null &&
                              task.listName!.isNotEmpty)
                            _InfoChip(
                              icon: Icons.list_outlined,
                              label: task.listName!,
                              color: cs.onSurfaceVariant,
                            ),
                          if (task.category != null &&
                              task.category!.isNotEmpty)
                            _InfoChip(
                              icon: Icons.label_outline,
                              label: task.category!,
                              color: cs.onSurfaceVariant,
                            ),
                          if (task.subtaskTitles.isNotEmpty)
                            _InfoChip(
                              icon: Icons.check_box_outline_blank,
                              label:
                                  '${task.subtaskDone.where((d) => d).length}/${task.subtaskTitles.length}',
                              color: cs.onSurfaceVariant,
                            ),
                          if (task.isRecurring)
                            _InfoChip(
                              icon: Icons.repeat,
                              label: task.recurrenceRule ?? 'Recurring',
                              color: cs.primary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions (Edit & Delete small icons)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: 'Edit task',
                      onPressed: () => TaskFormSheet.show(context, task: task),
                    ),
                    IconButton(
                      icon:
                          Icon(Icons.delete_outline, size: 18, color: cs.error),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: 'Delete task',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Task?'),
                            content: Text(
                                'Are you sure you want to delete "${task.title}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: FilledButton.styleFrom(
                                    backgroundColor: cs.error),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await notifier.deleteTask(task.id);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _swipeBg(ColorScheme cs, {required bool done}) => Container(
        alignment: done ? Alignment.centerLeft : Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: done ? cs.tertiary : cs.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          done ? Icons.check : Icons.delete_outline,
          color: Colors.white,
        ),
      );

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  bool _isOverdue(DateTime d) =>
      d.isBefore(DateTime.now().subtract(const Duration(hours: 24)));

  void _showTaskPreview(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDone = task.status == TaskStatus.done;
    final notifier = ref.read(tasksProvider.notifier);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Expanded(
              child: Text(
                task.title,
                style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  decoration: isDone ? TextDecoration.lineThrough : null,
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
              if (task.description != null && task.description!.isNotEmpty) ...[
                Text(
                  task.description!,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (task.priority != TaskPriority.none)
                    _PriorityBadge(task.priority),
                  if (task.dueDate != null)
                    _InfoChip(
                      icon: Icons.calendar_today_outlined,
                      label: 'Due: ${_formatDate(task.dueDate!)}',
                      color: _isOverdue(task.dueDate!) && !isDone
                          ? cs.error
                          : cs.onSurfaceVariant,
                    ),
                  if (task.listName != null && task.listName!.isNotEmpty)
                    _InfoChip(
                      icon: Icons.list_outlined,
                      label: 'List: ${task.listName!}',
                      color: cs.onSurfaceVariant,
                    ),
                  if (task.folderName != null && task.folderName!.isNotEmpty)
                    _InfoChip(
                      icon: Icons.folder_outlined,
                      label: 'Folder: ${task.folderName!}',
                      color: cs.onSurfaceVariant,
                    ),
                  if (task.category != null && task.category!.isNotEmpty)
                    _InfoChip(
                      icon: Icons.label_outline,
                      label: 'Category: ${task.category!}',
                      color: cs.onSurfaceVariant,
                    ),
                ],
              ),
              if (task.subtaskTitles.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Subtasks (${task.subtaskDone.where((d) => d).length}/${task.subtaskTitles.length})',
                  style: tt.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                ...task.subtaskTitles.asMap().entries.map((e) {
                  final subDone = task.subtaskDone.length > e.key
                      ? task.subtaskDone[e.key]
                      : false;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          subDone
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 16,
                          color: subDone ? cs.primary : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.value,
                            style: tt.bodySmall?.copyWith(
                              decoration:
                                  subDone ? TextDecoration.lineThrough : null,
                              color:
                                  subDone ? cs.onSurfaceVariant : cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
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
              notifier.updateStatus(
                task.id,
                isDone ? TaskStatus.todo : TaskStatus.done,
              );
              Navigator.pop(ctx);
            },
            icon: Icon(isDone ? Icons.undo : Icons.check),
            label: Text(isDone ? 'Mark Incomplete' : 'Mark Complete'),
          ),
        ],
      ),
    );
  }
}

// ─── Tiny helper widgets ─────────────────────────────────────────────────────

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge(this.priority);
  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (label, color) = switch (priority) {
      TaskPriority.low => (
          'Low',
          isDark ? const Color(0xFF4ADE80) : AppColors.priorityLow
        ),
      TaskPriority.medium => (
          'Medium',
          isDark ? const Color(0xFFFBBF24) : AppColors.priorityMedium
        ),
      TaskPriority.high => (
          'High',
          isDark ? const Color(0xFFFB923C) : AppColors.priorityHigh
        ),
      TaskPriority.urgent => (
          'Urgent',
          isDark ? const Color(0xFFF87171) : AppColors.priorityUrgent
        ),
      TaskPriority.none => ('', Theme.of(context).colorScheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      );
}
