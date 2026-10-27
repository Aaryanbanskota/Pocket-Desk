import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_icons.dart';
import 'calendar_month_widget.dart';

class WidgetTaskItem {
  final String id;
  final String title;
  final bool isDone;
  final String priority; // 'high', 'medium', 'low'
  final String time;

  const WidgetTaskItem({
    required this.id,
    required this.title,
    required this.isDone,
    this.priority = 'medium',
    this.time = '',
  });
}

/// Task Widget showing Task completion percentage and little tasks underneath
/// Supports Small (2x2), Medium (4x2), and Large (4x4) in Light & Dark modes
class TaskProgressTrackerWidget extends StatefulWidget {
  final WidgetSize size;
  final bool isDarkMode;
  final List<WidgetTaskItem>? tasks;
  final VoidCallback? onAddTask;
  final VoidCallback? onTap;

  const TaskProgressTrackerWidget({
    super.key,
    this.size = WidgetSize.medium,
    this.isDarkMode = false,
    this.tasks,
    this.onAddTask,
    this.onTap,
  });

  @override
  State<TaskProgressTrackerWidget> createState() => _TaskProgressTrackerWidgetState();
}

class _TaskProgressTrackerWidgetState extends State<TaskProgressTrackerWidget> {
  late List<WidgetTaskItem> _items;

  @override
  void initState() {
    super.initState();
    _initTasks();
  }

  @override
  void didUpdateWidget(covariant TaskProgressTrackerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tasks != oldWidget.tasks && widget.tasks != null) {
      _items = List.from(widget.tasks!);
    }
  }

  void _initTasks() {
    _items = widget.tasks ?? [
      const WidgetTaskItem(
        id: '1',
        title: 'Review System Design & Roadmap',
        isDone: true,
        priority: 'high',
        time: '10:00 AM',
      ),
      const WidgetTaskItem(
        id: '2',
        title: 'Spendee Financial Allocation',
        isDone: true,
        priority: 'medium',
        time: '01:30 PM',
      ),
      const WidgetTaskItem(
        id: '3',
        title: 'Complete MyDay Widget Implementation',
        isDone: true,
        priority: 'high',
        time: '03:00 PM',
      ),
      const WidgetTaskItem(
        id: '4',
        title: 'Evening Workout & Cardio Run',
        isDone: false,
        priority: 'low',
        time: '06:00 PM',
      ),
    ];
  }

  void _toggleTask(int index) {
    setState(() {
      final t = _items[index];
      _items[index] = WidgetTaskItem(
        id: t.id,
        title: t.title,
        isDone: !t.isDone,
        priority: t.priority,
        time: t.time,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDarkMode ? const Color(0xFF1E1E22) : const Color(0xFFFFFDF9);
    final textPrimary = widget.isDarkMode ? Colors.white : const Color(0xFF1C1917);
    final textMuted = widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF78716C);
    final borderColor = widget.isDarkMode ? const Color(0xFF2E2E34) : const Color(0xFFE7E5E4);
    final surface2 = widget.isDarkMode ? const Color(0xFF282830) : const Color(0xFFF5F3EF);

    final doneCount = _items.where((t) => t.isDone).length;
    final totalCount = _items.isEmpty ? 1 : _items.length;
    final percent = ((doneCount / totalCount) * 100).round();

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.35 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _buildLayout(
          context,
          doneCount,
          totalCount,
          percent,
          textPrimary,
          textMuted,
          borderColor,
          surface2,
        ),
      ),
    );
  }

  Widget _buildLayout(
    BuildContext context,
    int doneCount,
    int totalCount,
    int percent,
    Color textPrimary,
    Color textMuted,
    Color borderColor,
    Color surface2,
  ) {
    switch (widget.size) {
      case WidgetSize.small:
        return _buildSmall(doneCount, totalCount, percent, textPrimary, textMuted, surface2);
      case WidgetSize.medium:
        return _buildMedium(
          doneCount,
          totalCount,
          percent,
          textPrimary,
          textMuted,
          borderColor,
          surface2,
        );
      case WidgetSize.large:
        return _buildLarge(
          doneCount,
          totalCount,
          percent,
          textPrimary,
          textMuted,
          borderColor,
          surface2,
        );
    }
  }

  // --- Small (2x2): Prominent Percentage Ring + 1 Little Task ---
  Widget _buildSmall(
    int doneCount,
    int totalCount,
    int percent,
    Color textPrimary,
    Color textMuted,
    Color surface2,
  ) {
    final nextPending = _items.firstWhere(
      (t) => !t.isDone,
      orElse: () => _items.isNotEmpty ? _items.first : const WidgetTaskItem(id: '0', title: 'All done!', isDone: true),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(AppIcons.tasks, size: 14, color: AppColors.accentOrange),
                const SizedBox(width: 5),
                Text(
                  'Today Tasks',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              '$doneCount/$totalCount',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textMuted),
            ),
          ],
        ),

        // Center Percentage
        Row(
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: doneCount / totalCount,
                    strokeWidth: 5.5,
                    backgroundColor: surface2,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
                  ),
                  Center(
                    child: Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    percent == 100 ? 'All Completed!' : 'In Progress',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: percent == 100 ? const Color(0xFF10B981) : AppColors.accentOrange,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${totalCount - doneCount} remaining',
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Little Task Underneath
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: surface2,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                nextPending.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 13,
                color: nextPending.isDone ? const Color(0xFF10B981) : AppColors.accentOrange,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  nextPending.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Medium (4x2): Progress Ring on Left + Little Tasks Underneath on Right ---
  Widget _buildMedium(
    int doneCount,
    int totalCount,
    int percent,
    Color textPrimary,
    Color textMuted,
    Color borderColor,
    Color surface2,
  ) {
    return Row(
      children: [
        // Left Column: Progress Ring & Stats
        Expanded(
          flex: 9,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(AppIcons.tasks, size: 14, color: AppColors.accentOrange),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      "Today's Tasks",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: doneCount / totalCount,
                          strokeWidth: 5.0,
                          backgroundColor: surface2,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
                        ),
                        Center(
                          child: Text(
                            '$percent%',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$doneCount of $totalCount',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Completed',
                          style: TextStyle(fontSize: 10.5, color: textMuted),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.accentOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${totalCount - doneCount} Left',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),
        VerticalDivider(color: borderColor, width: 1),
        const SizedBox(width: 8),

        // Right Column: Little Tasks Checklist Underneath
        Expanded(
          flex: 11,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Tasks',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  if (widget.onAddTask != null)
                    GestureDetector(
                      onTap: widget.onAddTask,
                      child: const Icon(AppIcons.plus, size: 14, color: AppColors.accentOrange),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              for (int i = 0; i < (_items.length > 3 ? 3 : _items.length); i++) ...[
                _buildTaskRow(_items[i], i, textPrimary, textMuted, surface2),
                if (i < 2 && i < _items.length - 1) const SizedBox(height: 5),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // --- Large (4x4): Full Progress Header + Scrollable Little Tasks Checklist ---
  Widget _buildLarge(
    int doneCount,
    int totalCount,
    int percent,
    Color textPrimary,
    Color textMuted,
    Color borderColor,
    Color surface2,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(AppIcons.tasks, size: 18, color: AppColors.accentOrange),
                const SizedBox(width: 8),
                Text(
                  'Task Progress & Goals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$doneCount / $totalCount Done',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: doneCount / totalCount,
            minHeight: 8,
            backgroundColor: surface2,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$percent% of daily tasks accomplished',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted),
            ),
            Text(
              '${totalCount - doneCount} remaining',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accentOrange),
            ),
          ],
        ),

        const SizedBox(height: 12),
        Divider(color: borderColor, height: 1),
        const SizedBox(height: 8),

        Text(
          'Tasks for Today',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 6),

        // List of little tasks
        Expanded(
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, idx) {
              return _buildTaskRow(_items[idx], idx, textPrimary, textMuted, surface2);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskRow(
    WidgetTaskItem task,
    int index,
    Color textPrimary,
    Color textMuted,
    Color surface2,
  ) {
    Color priorityColor;
    switch (task.priority) {
      case 'high':
        priorityColor = const Color(0xFFEF4444);
        break;
      case 'medium':
        priorityColor = const Color(0xFFF59E0B);
        break;
      default:
        priorityColor = const Color(0xFF3B82F6);
    }

    return InkWell(
      onTap: () => _toggleTask(index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: surface2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isDone ? const Color(0xFF10B981) : Colors.transparent,
                border: Border.all(
                  color: task.isDone ? const Color(0xFF10B981) : textMuted,
                  width: 1.5,
                ),
              ),
              child: task.isDone
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),

            // Priority dot
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: priorityColor,
              ),
            ),
            const SizedBox(width: 6),

            // Title
            Expanded(
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: task.isDone ? FontWeight.w500 : FontWeight.w600,
                  color: task.isDone ? textMuted : textPrimary,
                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),

            if (task.time.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                task.time,
                style: TextStyle(fontSize: 10, color: textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
