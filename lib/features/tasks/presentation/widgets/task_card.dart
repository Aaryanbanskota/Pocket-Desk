import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          onTap: () => TaskFormSheet.show(context, task: task),
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
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? cs.onSurfaceVariant : cs.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (task.description != null && task.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            task.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
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
                          if (task.listName != null && task.listName!.isNotEmpty)
                            _InfoChip(
                              icon: Icons.list_outlined,
                              label: task.listName!,
                              color: cs.onSurfaceVariant,
                            ),
                          if (task.category != null && task.category!.isNotEmpty)
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

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  bool _isOverdue(DateTime d) =>
      d.isBefore(DateTime.now().subtract(const Duration(hours: 24)));
}

// ─── Tiny helper widgets ─────────────────────────────────────────────────────

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge(this.priority);
  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (priority) {
      TaskPriority.low => ('Low', Colors.blue),
      TaskPriority.medium => ('Medium', Colors.orange),
      TaskPriority.high => ('High', Colors.red),
      TaskPriority.urgent => ('Urgent', Colors.purple),
      TaskPriority.none => ('', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
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
