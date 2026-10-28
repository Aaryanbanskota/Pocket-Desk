import 'package:flutter/material.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/circular_icon_button.dart';
import '../../../core/design_system/widgets/pill_chip.dart';
import '../../../core/design_system/widgets/stat_tile.dart';
import '../../../core/design_system/widgets/undo_toast.dart';
import '../data/tasks_repository.dart';
import 'task_bottom_sheet.dart';

class TasksScreen extends StatefulWidget {
  final List<MyDayTask> tasks;
  final void Function(String filter) onFilterChanged;
  final String activeFilter;
  final void Function(MyDayTask) onToggleTask;
  final void Function(MyDayTask) onEditTask;
  final void Function(MyDayTask) onDeleteTask;
  final void Function(MyDayTask) onRunTask;
  final Map<String, int> runningTimers;

  final int? totalCount;
  final int? completedCount;
  final VoidCallback? onAddTask;
  final VoidCallback? onAddEvent;

  const TasksScreen({
    super.key,
    required this.tasks,
    required this.onFilterChanged,
    required this.activeFilter,
    required this.onToggleTask,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.onRunTask,
    required this.runningTimers,
    this.totalCount,
    this.completedCount,
    this.onAddTask,
    this.onAddEvent,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  Widget build(BuildContext context) {
    final completedCount = widget.completedCount ?? widget.tasks.where((t) => t.isDone).length;
    final totalCount = widget.totalCount ?? widget.tasks.length;
    final percent = totalCount > 0 ? ((completedCount / totalCount) * 100).round() : 0;

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(top: 6, bottom: 26),
      children: [
        // 1. Progress Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appLine, width: 1.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PROGRESS',
                    style: AppTypography.caption.copyWith(color: context.appMuted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$percent%',
                    style: AppTypography.progressBig.copyWith(color: context.appText),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$completedCount/$totalCount DONE',
                    style: AppTypography.caption.copyWith(color: context.appMuted),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 100,
                    child: TenDotProgressRow(
                      completedPercent: percent,
                      dotSize: 13,
                      spacing: 5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. Filter Chips and Add Task Button
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Row(
                  children: [
                    _buildChip('today', 'Today'),
                    const SizedBox(width: 8),
                    _buildChip('upcoming', 'Upcoming'),
                    const SizedBox(width: 8),
                    _buildChip('events', 'Events'),
                    const SizedBox(width: 8),
                    _buildChip('all', 'All'),
                    const SizedBox(width: 8),
                    _buildChip('done', 'Done'),
                  ],
                ),
              ),
            ),
            if (widget.onAddEvent != null) ...[
              const SizedBox(width: 8),
              PillChip(
                label: '+ Event',
                isSelected: false,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                onTap: widget.onAddEvent!,
              ),
            ],
            if (widget.onAddTask != null) ...[
              const SizedBox(width: 8),
              CircularIconButton(
                icon: AppIcons.plus,
                size: 38,
                iconSize: 20,
                onPressed: widget.onAddTask,
              ),
            ],
          ],
        ),

        const SizedBox(height: 14),

        // 3. Task List Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appLine, width: 1.0),
          ),
          child: widget.tasks.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Text(
                      'Nothing here',
                      style: AppTypography.body.copyWith(color: context.appMuted),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < widget.tasks.length; i++) ...[
                      _buildTaskItem(context, widget.tasks[i]),
                      if (i < widget.tasks.length - 1)
                        Divider(color: context.appLine, height: 1),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildChip(String filterKey, String label) {
    final isSelected = widget.activeFilter == filterKey;
    return PillChip(
      label: label,
      isSelected: isSelected,
      onTap: () => widget.onFilterChanged(filterKey),
    );
  }

  Widget _buildTaskItem(BuildContext context, MyDayTask task) {
    final isRunning = widget.runningTimers.containsKey(task.id);
    final remainingMs = isRunning
        ? widget.runningTimers[task.id]!
        : (task.durationLeftMs > 0 ? task.durationLeftMs : task.minDuration * 60 * 1000);

    final minutes = (remainingMs / 60000).floor().toString().padLeft(2, '0');
    final seconds = ((remainingMs % 60000) / 1000).floor().toString().padLeft(2, '0');
    final timeStr = '$minutes:$seconds';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Checkbox circle
          if (task.kind == 'todo') ...[
            GestureDetector(
              onTap: () => widget.onToggleTask(task),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.isDone ? AppColors.success : Colors.transparent,
                  border: Border.all(
                    color: task.isDone ? AppColors.success : context.appMuted,
                    width: 2.0,
                  ),
                ),
                child: AnimatedScale(
                  scale: task.isDone ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: const Icon(Icons.check, size: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],

          // Task details
          Expanded(
            child: GestureDetector(
              onTap: () => widget.onEditTask(task),
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (task.isImportant)
                        _buildTag(
                          label: 'Important',
                          color: AppColors.accent,
                          bg: AppColors.accent.withValues(alpha: 0.15),
                        ),
                      if (task.tags.contains('event'))
                        _buildTag(
                          label: 'Event',
                          color: AppColors.accentOrange,
                          bg: AppColors.accentOrange.withValues(alpha: 0.15),
                        ),
                      if (!task.tags.contains('event'))
                        _buildTag(
                          label: task.kind == 'timed'
                              ? '${task.minDuration} min'
                              : 'To-do',
                          color: context.appMuted,
                          bg: context.appSurface2,
                        ),
                      _buildTag(
                        label: task.dueDate,
                        color: context.appMuted,
                        bg: context.appSurface2,
                      ),
                      if (task.repeatInterval != 'none')
                        _buildTag(
                          label: task.repeatInterval,
                          color: context.appMuted,
                          bg: context.appSurface2,
                        ),
                      for (final tag in task.tags)
                        if (tag != 'event')
                          _buildTag(
                            label: tag,
                            color: context.appText,
                            bg: context.appSurface2,
                            dotColor: AppColors.tags[tag],
                          ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    task.title,
                    style: AppTypography.h4.copyWith(
                      color: task.isDone ? context.appMuted : context.appText,
                      decoration: task.isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (task.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.note,
                      style: AppTypography.captionMuted.copyWith(
                        color: context.appMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Timed countdown action button
          if (task.kind == 'timed') ...[
            GestureDetector(
              onTap: () => widget.onRunTask(task),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRunning
                      ? AppColors.accent
                      : (task.isDone ? AppColors.success : context.appSurface2),
                ),
                child: Center(
                  child: task.isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isRunning ? Colors.white : context.appText,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Trash Button
          CircularIconButton(
            icon: AppIcons.trash,
            size: 32,
            iconSize: 16,
            iconColor: context.appMuted,
            customColor: Colors.transparent,
            onPressed: () {
              widget.onDeleteTask(task);
              UndoToast.show(
                context,
                message: 'Moved to Trash',
                onUndo: () => widget.onToggleTask(task),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTag({
    required String label,
    required Color color,
    required Color bg,
    Color? dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class TasksPage extends StatefulWidget {
  final TasksRepository tasksRepository;
  final String accountId;
  final void Function(MyDayTask)? onEditTask;
  final VoidCallback? onAddTask;
  final VoidCallback? onAddEvent;
  final Future<void> Function()? onRefresh;

  const TasksPage({
    super.key,
    required this.tasksRepository,
    required this.accountId,
    this.onEditTask,
    this.onAddTask,
    this.onAddEvent,
    this.onRefresh,
  });

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<MyDayTask> _tasks = [];
  int _totalCount = 0;
  int _completedCount = 0;
  String _activeFilter = 'today';
  final Map<String, int> _runningTimers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void didUpdateWidget(covariant TasksPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final all = await widget.tasksRepository
          .getTasks(widget.accountId, filter: 'all')
          .timeout(const Duration(seconds: 2));
      final tasks = await widget.tasksRepository
          .getTasks(widget.accountId, filter: _activeFilter)
          .timeout(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _totalCount = all.length;
          _completedCount = all.where((t) => t.isDone).length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onFilterChanged(String filter) {
    setState(() => _activeFilter = filter);
    _loadTasks();
  }

  Future<void> _onToggleTask(MyDayTask task) async {
    await widget.tasksRepository.toggleTaskDone(task);
    _loadTasks();
  }

  Future<void> _onDeleteTask(MyDayTask task) async {
    await widget.tasksRepository.deleteTask(task.id);
    _loadTasks();
    if (mounted) {
      UndoToast.show(
        context,
        message: 'Moved to Trash',
        actionLabel: 'Undo',
        onUndo: () async {
          await widget.tasksRepository.restoreTask(task.id);
          _loadTasks();
        },
      );
    }
  }

  void _onRunTask(MyDayTask task) {
    setState(() {
      if (_runningTimers.containsKey(task.id)) {
        _runningTimers.remove(task.id);
      } else {
        _runningTimers[task.id] =
            DateTime.now().millisecondsSinceEpoch + (task.minDuration * 60 * 1000);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentOrange));
    }

    return RefreshIndicator(
      color: AppColors.accentOrange,
      backgroundColor: context.appSurface,
      onRefresh: () async {
        if (widget.onRefresh != null) {
          await widget.onRefresh!();
        }
        await _loadTasks();
      },
      child: TasksScreen(
        tasks: _tasks,
        totalCount: _totalCount,
        completedCount: _completedCount,
        activeFilter: _activeFilter,
        onFilterChanged: _onFilterChanged,
        onToggleTask: _onToggleTask,
        onEditTask: widget.onEditTask ?? (_) {},
        onDeleteTask: _onDeleteTask,
        onRunTask: _onRunTask,
        runningTimers: _runningTimers,
        onAddTask: widget.onAddTask ?? () {
          TaskBottomSheet.showForAccount(
            context: context,
            tasksRepository: widget.tasksRepository,
            accountId: widget.accountId,
            isEvent: false,
            onSaved: _loadTasks,
          );
        },
        onAddEvent: widget.onAddEvent ?? () {
          TaskBottomSheet.showForAccount(
            context: context,
            tasksRepository: widget.tasksRepository,
            accountId: widget.accountId,
            isEvent: true,
            onSaved: _loadTasks,
          );
        },
      ),
    );
  }
}

