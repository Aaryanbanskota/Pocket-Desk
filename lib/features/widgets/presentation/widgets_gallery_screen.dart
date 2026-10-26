import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_icons.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/widgets/app_scaffold.dart';
import '../../../../core/design_system/widgets/circular_icon_button.dart';
import '../../auth/data/auth_repository.dart';
import '../../tasks/data/tasks_repository.dart';
import 'components/budget_spendee_widget.dart';
import 'components/calendar_month_widget.dart';
import 'components/clock_pie_agenda_widget.dart';
import 'components/dual_date_agenda_widget.dart';
import 'components/focus_pomodoro_widget.dart';
import 'components/quick_actions_widget.dart';
import 'components/quick_notes_widget.dart';
import 'components/task_progress_tracker_widget.dart';
import 'dialogs/add_to_device_dialog.dart';

class WidgetsGalleryScreen extends StatefulWidget {
  final bool initialDarkMode;
  final ValueChanged<MyDayNavTab>? onNavigate;
  final VoidCallback? onBack;
  final TasksRepository? tasksRepository;
  final UserSession? session;

  const WidgetsGalleryScreen({
    super.key,
    this.initialDarkMode = false,
    this.onNavigate,
    this.onBack,
    this.tasksRepository,
    this.session,
  });

  @override
  State<WidgetsGalleryScreen> createState() => _WidgetsGalleryScreenState();
}

class _WidgetsGalleryScreenState extends State<WidgetsGalleryScreen> {
  late bool _previewDarkMode;
  WidgetSize _selectedSize = WidgetSize.medium;
  String _selectedCategory = 'all';
  List<WidgetTaskItem>? _realTasks;
  List<WidgetAgendaItem>? _realEvents;

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'label': 'All Widgets'},
    {'id': 'clock', 'label': 'Clock & Dial'},
    {'id': 'notes', 'label': 'Notes & Voice'},
    {'id': 'calendar', 'label': 'Calendar'},
    {'id': 'tasks', 'label': 'Tasks & Goals'},
    {'id': 'dual', 'label': 'AD · BS Date'},
    {'id': 'actions', 'label': 'Quick Capture'},
    {'id': 'budget', 'label': 'Financial Glance'},
    {'id': 'focus', 'label': 'Focus Timer'},
  ];

  @override
  void initState() {
    super.initState();
    _previewDarkMode = widget.initialDarkMode;
    _loadUserRealData();
  }

  Future<void> _loadUserRealData() async {
    if (widget.tasksRepository == null || widget.session == null) return;
    try {
      final tasks = await widget.tasksRepository!.getTasks(widget.session!.accountId);
      final active = tasks.where((t) => !t.isDeleted).toList();

      final todos = active.where((t) => !t.tags.contains('event')).toList();
      final events = active.where((t) => t.tags.contains('event') || t.kind == 'timed').toList();

      if (mounted) {
        setState(() {
          _realTasks = todos.map((t) => WidgetTaskItem(
            id: t.id,
            title: t.title,
            isDone: t.isDone,
            priority: t.isImportant ? 'high' : 'medium',
            time: t.dueDate,
          )).toList();

          _realEvents = events.map((e) => WidgetAgendaItem(
            id: e.id,
            title: e.title,
            time: e.dueDate.isNotEmpty ? e.dueDate : 'Today',
            isDone: e.isDone,
          )).toList();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appBg,
      child: Column(
        children: [
          // Top App Bar
          _buildTopBar(context),

            // Controls Bar: Theme Switcher & Size Selector
            _buildControlsBar(context),

            // Category Chips
            _buildCategoryFilter(context),

            const SizedBox(height: 8),

            // Main Widget Showcase List
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  // 1. Dual Date Widget
                  if (_shouldShow('dual') || _shouldShow('calendar')) ...[
                    _buildWidgetShowcaseCard(
                      title: 'Dual Date & Agenda Widget',
                      identifier: '.dualCalendarWidget',
                      subtitle: 'Real user agenda & events with dual AD/BS calendar dates',
                      tag: 'Featured · AD & BS',
                      widget: DualDateAgendaWidget(
                        size: _selectedSize,
                        isDarkMode: _previewDarkMode,
                        events: _realEvents,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 2. Circular Clock-Like Pie Agenda Widget ("Day Dial")
                  if (_shouldShow('clock') || _shouldShow('tasks') || _shouldShow('calendar')) ...[
                    _buildWidgetShowcaseCard(
                      title: 'Day Dial Clock & Pie Agenda',
                      identifier: '.clockPieAgendaWidget',
                      subtitle: '12-hour circular clock face with live accurate hands & colored task pie sectors',
                      tag: 'New · Clock Pie',
                      widget: ClockPieAgendaWidget(
                        size: _selectedSize,
                        isDarkMode: _previewDarkMode,
                        onTap: () => widget.onNavigate?.call(MyDayNavTab.clock),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 2. Calendar Month Widget: .calendarWidget
                  if (_shouldShow('calendar')) ...[
                    _buildWidgetShowcaseCard(
                      title: 'Monthly Calendar Grid',
                      identifier: '.calendarWidget',
                      subtitle: 'Interactive month grid with event indicators and today schedule',
                      tag: 'Core .calendarWidget',
                      widget: CalendarMonthWidget(
                        size: _selectedSize,
                        isDarkMode: _previewDarkMode,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 3. Task Progress Tracker Widget
                  if (_shouldShow('tasks')) ...[
                    _buildWidgetShowcaseCard(
                      title: 'Task Completion Tracker',
                      identifier: '.taskTrackerWidget',
                      subtitle: 'Task percentage ring with actionable little tasks underneath',
                      tag: 'Top Productivity',
                      widget: TaskProgressTrackerWidget(
                        size: _selectedSize,
                        isDarkMode: _previewDarkMode,
                        tasks: _realTasks,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 4. Quick Actions Capture Widget
                  if (_shouldShow('actions')) ...[
                    _buildWidgetShowcaseCard(
                      title: 'Quick Capture Action Pad',
                      identifier: '.quickActionsWidget',
                      subtitle: '1-tap home screen shortcuts for +Task, +Note, +Moment, +Expense',
                      tag: 'Fast Capture',
                      widget: QuickActionsWidget(
                        size: _selectedSize,
                        isDarkMode: _previewDarkMode,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 5. Spendee Financial Glance Widget
                  if (_shouldShow('budget')) ...[
                    _buildWidgetShowcaseCard(
                      title: 'Spendee Financial Glance',
                      identifier: '.spendeeBudgetWidget',
                      subtitle: 'Total net balance, today spend vs limit, and recent expense feed',
                      tag: 'Financial Insights',
                      widget: BudgetSpendeeWidget(
                        size: _selectedSize,
                        isDarkMode: _previewDarkMode,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 6. Focus Pomodoro Timer Widget
                  if (_shouldShow('focus')) ...[
                    _buildWidgetShowcaseCard(
                      title: 'Focus Pomodoro & Clock',
                      identifier: '.focusPomodoroWidget',
                      subtitle: '25-minute deep focus dial with start/pause and live progress ring',
                      tag: 'Time Management',
                      widget: FocusPomodoroWidget(
                        size: _selectedSize,
                        isDarkMode: _previewDarkMode,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 7. Quick Notes & Voice Memo Widget: .notesWidget
                  if (_shouldShow('notes')) ...[
                    _buildWidgetShowcaseCard(
                      title: 'Quick Notes & Voice Memo',
                      identifier: '.notesWidget',
                      subtitle: 'Recent notes overview with 1-tap New Note and Voice Note capture',
                      tag: 'Notes & Dictation',
                      widget: QuickNotesWidget(
                        size: _selectedSize,
                        isDarkMode: _previewDarkMode,
                        onNewNote: () => widget.onNavigate?.call(MyDayNavTab.notes),
                        onVoiceNote: () => widget.onNavigate?.call(MyDayNavTab.notes),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
  }

  bool _shouldShow(String category) {
    if (_selectedCategory == 'all') return true;
    return _selectedCategory == category;
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          if (widget.onBack != null) ...[
            CircularIconButton(
              icon: AppIcons.back,
              size: 36,
              iconSize: 18,
              onPressed: widget.onBack,
            ),
            const SizedBox(width: 8),
          ],
          const Icon(AppIcons.widget, size: 22, color: AppColors.accentOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device Widgets',
                  style: AppTypography.h3.copyWith(color: context.appText),
                ),
                Text(
                  'Phone Home Screen & Lock Screen Gadgets',
                  style: AppTypography.captionMuted.copyWith(color: context.appMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appLine, width: 1.0),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Preview Theme Toggle
              Row(
                children: [
                  Icon(
                    _previewDarkMode ? AppIcons.moon : AppIcons.sun,
                    size: 16,
                    color: AppColors.accentOrange,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _previewDarkMode ? 'Dark' : 'Light',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.appText,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch.adaptive(
                      value: _previewDarkMode,
                      activeTrackColor: AppColors.accentOrange,
                      onChanged: (val) => setState(() => _previewDarkMode = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Size Selector
              Row(
                children: [
                  _buildSizeOption('2×2', WidgetSize.small),
                  const SizedBox(width: 4),
                  _buildSizeOption('4×2', WidgetSize.medium),
                  const SizedBox(width: 4),
                  _buildSizeOption('4×4', WidgetSize.large),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSizeOption(String label, WidgetSize size) {
    final isSelected = _selectedSize == size;
    return InkWell(
      onTap: () => setState(() => _selectedSize = size),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : context.appMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final c = _categories[idx];
          final isSelected = _selectedCategory == c['id'];
          return InkWell(
            onTap: () => setState(() => _selectedCategory = c['id']!),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentOrange : context.appSurface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? AppColors.accentOrange : context.appLine,
                ),
              ),
              child: Text(
                c['label']!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : context.appText,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWidgetShowcaseCard({
    required String title,
    required String identifier,
    required String subtitle,
    required String tag,
    required Widget widget,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appLine, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: context.appText,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentOrange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11.5, color: context.appMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(AppIcons.plus, size: 14),
                label: const Text(
                  'Add',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                onPressed: () {
                  AddToDeviceDialog.show(
                    context,
                    widgetTitle: title,
                    widgetIdentifier: identifier,
                    size: _selectedSize,
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Rendered Widget Frame Preview (matching OS widget dimensions)
          SizedBox(
            width: double.infinity,
            height: _selectedSize == WidgetSize.large
                ? 360
                : (_selectedSize == WidgetSize.small ? 170 : 205),
            child: widget,
          ),
        ],
      ),
    );
  }
}
