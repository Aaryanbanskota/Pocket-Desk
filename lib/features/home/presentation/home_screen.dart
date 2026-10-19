import 'package:flutter/material.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/circular_icon_button.dart';
import '../../../core/design_system/widgets/cream_hero_card.dart';
import '../../../core/design_system/widgets/pill_chip.dart';
import '../../../core/design_system/widgets/stat_tile.dart';
import '../../../core/design_system/widgets/undo_toast.dart';
import '../../../core/design_system/widgets/app_scaffold.dart';
import '../../../core/utils/nepali_calendar_converter.dart';
import '../../auth/data/auth_repository.dart';
import '../../budget/data/budget_repository.dart';
import '../../notes/data/notes_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../tasks/data/tasks_repository.dart';

class HomeScreen extends StatelessWidget {
  final UserSession session;
  final List<MyDayTask> tasks;
  final List<MyDayNote> notes;
  final List<MyDayWallet> wallets;
  final List<MyDayBudget> budgets;
  final Set<String> datesWithTasks;
  final void Function(MyDayNavTab) onNavigate;
  final void Function(MyDayTask) onToggleTask;
  final void Function(MyDayTask) onEditTask;
  final void Function(MyDayTask) onDeleteTask;
  final void Function(MyDayTask) onRunTask;
  final Map<String, int> runningTimers;
  final bool isNepaliCalendar;
  final ValueChanged<bool>? onToggleCalendarSystem;
  final Widget? biometricPromptWidget;

  const HomeScreen({
    super.key,
    required this.session,
    required this.tasks,
    required this.notes,
    required this.wallets,
    required this.budgets,
    required this.datesWithTasks,
    required this.onNavigate,
    required this.onToggleTask,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.onRunTask,
    required this.runningTimers,
    this.isNepaliCalendar = false,
    this.onToggleCalendarSystem,
    this.biometricPromptWidget,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final openTasks = tasks.where((t) => !t.isDone).toList();
    openTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final completedCount = tasks.where((t) => t.isDone).length;
    final completedPercent = tasks.isNotEmpty
        ? ((completedCount / tasks.length) * 100).round()
        : 0;

    final totalNetWorth =
        wallets.fold<int>(0, (sum, w) => sum + w.currentBalance);
    final totalBudgetLimit =
        budgets.fold<int>(0, (sum, b) => sum + b.monthlyLimit);
    final totalBudgetSpent =
        budgets.fold<int>(0, (sum, b) => sum + b.spentThisMonth);
    final budgetUsedPercent = totalBudgetLimit > 0
        ? ((totalBudgetSpent / totalBudgetLimit) * 100).round()
        : 0;

    final currency = wallets.isNotEmpty ? wallets.first.currency : 'Rs';
    final nepaliStr = isNepaliCalendar
        ? NepaliCalendarConverter.formatBSShort(now)
        : null;

    final upNextList = openTasks.take(4).toList();

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(top: 6, bottom: 26),
      children: [
        if (biometricPromptWidget != null) ...[
          biometricPromptWidget!,
          const SizedBox(height: 12),
        ],

        // 1. Cream Hero Card
        CreamHeroCard(
          date: now,
          userName: session.name,
          openTasksCount: openTasks.length,
          notesCount: notes.length,
          datesWithTasks: datesWithTasks,
          tasks: tasks,
          nepaliDateString: nepaliStr,
          isNepaliCalendar: isNepaliCalendar,
          onToggleCalendarSystem: onToggleCalendarSystem,
          onSelectDate: (d) => onNavigate(MyDayNavTab.calendar),
        ),

        const SizedBox(height: 12),

        // 2. Two Tiles: Progress (Completed %) and Net Worth (Gradient)
        Row(
          children: [
            Expanded(
              child: StatTile(
                caption: 'Completed',
                value: '$completedPercent%',
                onTap: () => onNavigate(MyDayNavTab.tasks),
                trailingContent: TenDotProgressRow(
                  completedPercent: completedPercent,
                  dotSize: 12,
                  spacing: 4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                caption: 'Net worth',
                value: BudgetRepository.formatAmount(
                  totalNetWorth,
                  currency: currency,
                ),
                isGradient: true,
                onTap: () => onNavigate(MyDayNavTab.budget),
                subtitle: Text(
                  totalBudgetLimit > 0
                      ? 'Budget used $budgetUsedPercent%'
                      : 'No budgets set',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 3. Up Next Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Up next',
              style: AppTypography.h3.copyWith(color: context.appText),
            ),
            PillChip(
              label: 'See all',
              isSelected: false,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              onTap: () => onNavigate(MyDayNavTab.tasks),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 4. Up Next Tasks Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.appLine, width: 1.0),
          ),
          child: upNextList.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'All done. Enjoy your day.',
                      style: AppTypography.body.copyWith(
                        color: context.appMuted,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < upNextList.length; i++) ...[
                      _buildTaskRow(context, upNextList[i]),
                      if (i < upNextList.length - 1)
                        Divider(color: context.appLine, height: 1),
                    ],
                  ],
                ),
        ),

        const SizedBox(height: 16),

        // 5. Four Navigation Shortcut Tiles (2x2)
        Row(
          children: [
            Expanded(
              child: _buildShortcutTile(
                context,
                icon: AppIcons.notes,
                label: 'Notes',
                onTap: () => onNavigate(MyDayNavTab.notes),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildShortcutTile(
                context,
                icon: AppIcons.calendar,
                label: 'Calendar',
                onTap: () => onNavigate(MyDayNavTab.calendar),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildShortcutTile(
                context,
                icon: AppIcons.clock,
                label: 'Clock',
                onTap: () => onNavigate(MyDayNavTab.clock),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: session.isCloud
                  ? _buildShortcutTile(
                      context,
                      icon: AppIcons.files,
                      label: 'File share',
                      onTap: () => onNavigate(MyDayNavTab.files),
                    )
                  : _buildShortcutTile(
                      context,
                      icon: AppIcons.phone,
                      label: 'Call',
                      onTap: () => onNavigate(MyDayNavTab.call),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShortcutTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.appLine, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.accent, size: 24),
            const SizedBox(height: 12),
            Text(
              label,
              style: AppTypography.bodyBold.copyWith(color: context.appText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskRow(BuildContext context, MyDayTask task) {
    final isRunning = runningTimers.containsKey(task.id);
    final remainingMs = isRunning
        ? runningTimers[task.id]!
        : (task.durationLeftMs > 0 ? task.durationLeftMs : task.minDuration * 60 * 1000);

    final minutes = (remainingMs / 60000).floor().toString().padLeft(2, '0');
    final seconds = ((remainingMs % 60000) / 1000).floor().toString().padLeft(2, '0');
    final timeStr = '$minutes:$seconds';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Check circle button
          if (task.kind == 'todo') ...[
            GestureDetector(
              onTap: () => onToggleTask(task),
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
              onTap: () => onEditTask(task),
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (task.tags.contains('event'))
                        _buildTag(
                          label: 'Event',
                          color: AppColors.accentOrange,
                          bg: AppColors.accentOrange.withValues(alpha: 0.15),
                        ),
                      if (task.isImportant)
                        _buildTag(
                          label: 'Important',
                          color: AppColors.accent,
                          bg: AppColors.accent.withValues(alpha: 0.15),
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
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    task.title,
                    style: AppTypography.h4.copyWith(
                      color: task.isDone ? context.appMuted : context.appText,
                      decoration:
                          task.isDone ? TextDecoration.lineThrough : null,
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
              onTap: () => onRunTask(task),
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
              onDeleteTask(task);
              UndoToast.show(
                context,
                message: 'Moved to Trash',
                onUndo: () => onToggleTask(task),
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
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

class HomePage extends StatefulWidget {
  final UserSession session;
  final TasksRepository tasksRepository;
  final NotesRepository notesRepository;
  final BudgetRepository budgetRepository;
  final AuthRepository? authRepository;
  final ValueChanged<UserSession>? onSessionUpdated;
  final void Function(MyDayNavTab) onNavigate;
  final void Function(MyDayTask) onEditTask;
  final Future<void> Function()? onRefresh;

  const HomePage({
    super.key,
    required this.session,
    required this.tasksRepository,
    required this.notesRepository,
    required this.budgetRepository,
    this.authRepository,
    this.onSessionUpdated,
    required this.onNavigate,
    required this.onEditTask,
    this.onRefresh,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<MyDayTask> _tasks = [];
  List<MyDayNote> _notes = [];
  List<MyDayWallet> _wallets = [];
  List<MyDayBudget> _budgets = [];
  final Map<String, int> _runningTimers = {};
  bool _isNepaliCalendar = false;
  bool _isLoading = true;
  bool _showBiometricBox = false;
  bool _neverShowBiometricAgain = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    if (widget.session.isBioEnabled) {
      if (mounted) setState(() => _showBiometricBox = false);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final neverShow = prefs.getBool('never_show_biometric_${widget.session.accountId}') ?? false;
      if (!neverShow && mounted) {
        setState(() => _showBiometricBox = true);
      }
    } catch (_) {}
  }

  void _dismissBiometricPrompt() async {
    setState(() => _showBiometricBox = false);
    if (_neverShowBiometricAgain) {
      await _saveNeverShowBiometric();
    }
  }

  Future<void> _saveNeverShowBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('never_show_biometric_${widget.session.accountId}', true);
    } catch (_) {}
  }

  Future<void> _enableBiometrics() async {
    final authRepo = widget.authRepository;
    if (authRepo == null) return;

    final available = await authRepo.biometricService.isBiometricAvailable();
    if (!available) {
      if (mounted) {
        UndoToast.show(
          context,
          message: 'Biometric hardware is not enrolled in Android Settings.',
        );
      }
      return;
    }

    try {
      final success = await authRepo.biometricService.authenticate(
        reason: 'Scan fingerprint to enable biometric unlock for MyDay',
      );
      if (success) {
        await authRepo.setBiometricEnabled(widget.session.accountId, true);
        final updated = widget.session.copyWith(isBioEnabled: true);
        widget.onSessionUpdated?.call(updated);
        if (mounted) {
          setState(() {
            _showBiometricBox = false;
          });
          UndoToast.show(context, message: 'Biometric unlock turned ON successfully!');
        }
      } else {
        if (mounted) {
          UndoToast.show(context, message: 'Biometric verification cancelled or failed.');
        }
      }
    } catch (e) {
      if (mounted) {
        UndoToast.show(context, message: 'Could not enable biometrics: $e');
      }
    }
  }

  Widget _buildBiometricPromptBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.fingerprint, color: AppColors.accentOrange, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your biometric is off',
                      style: AppTypography.h4.copyWith(color: context.appText, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Turn on fingerprint or face unlock to access your private desk without entering your PIN every time.',
                      style: AppTypography.captionMuted.copyWith(color: context.appMuted, height: 1.3),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _dismissBiometricPrompt,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 18, color: context.appMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() => _neverShowBiometricAgain = !_neverShowBiometricAgain);
                  if (_neverShowBiometricAgain) {
                    _saveNeverShowBiometric();
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _neverShowBiometricAgain,
                        activeColor: AppColors.accentOrange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) {
                          setState(() => _neverShowBiometricAgain = val ?? false);
                          if (_neverShowBiometricAgain) {
                            _saveNeverShowBiometric();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Never show again',
                      style: TextStyle(fontSize: 11, color: context.appMuted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(AppIcons.fingerprint, size: 15),
                label: const Text('Turn On', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                onPressed: _enableBiometrics,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadData();
  }

  Future<void> _loadData() async {
    final accountId = widget.session.accountId;
    List<MyDayTask> tasks = [];
    List<MyDayNote> notes = [];
    List<MyDayWallet> wallets = [];
    List<MyDayBudget> budgets = [];
    String? calendarPref;

    try {
      try {
        tasks = await widget.tasksRepository
            .getTasks(accountId)
            .timeout(const Duration(seconds: 2));
      } catch (_) {}

      try {
        notes = await widget.notesRepository
            .getNotes(accountId)
            .timeout(const Duration(seconds: 2));
      } catch (_) {}

      try {
        wallets = await widget.budgetRepository
            .getWallets(accountId)
            .timeout(const Duration(seconds: 2));
      } catch (_) {}

      try {
        budgets = await widget.budgetRepository
            .getBudgets(accountId)
            .timeout(const Duration(seconds: 2));
      } catch (_) {}

      try {
        final prefs = await SharedPreferences.getInstance()
            .timeout(const Duration(seconds: 2));
        calendarPref = prefs.getString('myday_calendar_system');
      } catch (_) {}
    } finally {
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _notes = notes;
          _wallets = wallets;
          _budgets = budgets;
          _isNepaliCalendar = calendarPref == 'BS';
          _isLoading = false;
        });
      }
    }
  }

  void _onToggleCalendarSystem(bool isBS) {
    setState(() {
      _isNepaliCalendar = isBS;
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('myday_calendar_system', isBS ? 'BS' : 'AD');
    });
  }

  Future<void> _onToggleTask(MyDayTask task) async {
    await widget.tasksRepository.toggleTaskDone(task);
    _loadData();
  }

  Future<void> _onDeleteTask(MyDayTask task) async {
    await widget.tasksRepository.deleteTask(task.id);
    _loadData();
    if (mounted) {
      UndoToast.show(
        context,
        message: 'Moved to Trash',
        actionLabel: 'Undo',
        onUndo: () async {
          await widget.tasksRepository.restoreTask(task.id);
          _loadData();
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

    final datesWithTasks = _tasks.where((t) => !t.isDone).map((t) => t.dueDate).toSet();

    return RefreshIndicator(
      color: AppColors.accentOrange,
      backgroundColor: context.appSurface,
      onRefresh: () async {
        if (widget.onRefresh != null) {
          await widget.onRefresh!();
        }
        await _loadData();
      },
      child: HomeScreen(
        session: widget.session,
        tasks: _tasks,
        notes: _notes,
        wallets: _wallets,
        budgets: _budgets,
        datesWithTasks: datesWithTasks,
        onNavigate: widget.onNavigate,
        onToggleTask: _onToggleTask,
        onEditTask: widget.onEditTask,
        onDeleteTask: _onDeleteTask,
        onRunTask: _onRunTask,
        runningTimers: _runningTimers,
        isNepaliCalendar: _isNepaliCalendar,
        onToggleCalendarSystem: _onToggleCalendarSystem,
        biometricPromptWidget: _showBiometricBox ? _buildBiometricPromptBox() : null,
      ),
    );
  }
}
