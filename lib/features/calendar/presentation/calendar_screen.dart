import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/calendar_event_indicators.dart';
import '../../../core/design_system/widgets/calendar_system_toggle.dart';
import '../../../core/design_system/widgets/circular_icon_button.dart';
import '../../../core/design_system/widgets/undo_toast.dart';
import '../../../core/utils/nepali_calendar_converter.dart';
import '../../budget/data/budget_repository.dart';
import '../../feed/data/feed_repository.dart';
import '../../notes/data/notes_repository.dart';
import '../../tasks/data/tasks_repository.dart';
import '../../tasks/presentation/task_bottom_sheet.dart';

export '../../../core/design_system/calendar_event_indicators.dart';

class CalendarScreen extends StatefulWidget {
  final List<MyDayTask> allTasks;
  final List<MyDayNote> allNotes;
  final List<MyDayFeedPost> allPosts;
  final List<MyDayTransaction> allTransactions;
  final Set<String> datesWithTasks;
  final void Function(MyDayTask) onToggleTask;
  final void Function(MyDayTask) onEditTask;
  final void Function(MyDayTask) onDeleteTask;
  final VoidCallback onAddTaskForSelectedDate;
  final void Function(MyDayNote)? onOpenNote;
  final bool isNepaliCalendar;
  final ValueChanged<bool>? onCalendarSystemChanged;
  final ValueChanged<String> onDateSelected;
  final String initialSelectedDate;

  const CalendarScreen({
    super.key,
    required this.allTasks,
    required this.allNotes,
    required this.allPosts,
    required this.allTransactions,
    required this.datesWithTasks,
    required this.onToggleTask,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.onAddTaskForSelectedDate,
    required this.onDateSelected,
    this.onOpenNote,
    this.initialSelectedDate = '',
    this.isNepaliCalendar = false,
    this.onCalendarSystemChanged,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late bool _isNepaliCalendar;
  late DateTime _displayedADMonth;
  late NepaliDateTime _displayedBSMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = widget.initialSelectedDate.isNotEmpty
        ? DateTime.tryParse(widget.initialSelectedDate) ?? now
        : now;
    _isNepaliCalendar = widget.isNepaliCalendar;

    _displayedADMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final bsDate = NepaliCalendarConverter.toBS(_selectedDate);
    _displayedBSMonth = NepaliDateTime(bsDate.year, bsDate.month, 1);

    _loadSavedCalendarPref();
  }

  Future<void> _loadSavedCalendarPref() async {
    final prefs = await SharedPreferences.getInstance();
    final pref = prefs.getString('myday_calendar_system');
    if (pref != null && mounted) {
      final isBS = pref == 'BS';
      if (isBS != _isNepaliCalendar) {
        setState(() {
          _isNepaliCalendar = isBS;
          if (isBS) {
            final bsDate = NepaliCalendarConverter.toBS(_selectedDate);
            _displayedBSMonth = NepaliDateTime(bsDate.year, bsDate.month, 1);
          } else {
            _displayedADMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
          }
        });
      }
    }
  }

  void _setCalendarSystem(bool isBS) {
    setState(() {
      _isNepaliCalendar = isBS;
      if (isBS) {
        final bsDate = NepaliCalendarConverter.toBS(_selectedDate);
        _displayedBSMonth = NepaliDateTime(bsDate.year, bsDate.month, 1);
      } else {
        _displayedADMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
      }
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('myday_calendar_system', isBS ? 'BS' : 'AD');
    });
    widget.onCalendarSystemChanged?.call(isBS);
  }

  void _changeMonth(int delta) {
    setState(() {
      if (_isNepaliCalendar) {
        int nextM = _displayedBSMonth.month + delta;
        int nextY = _displayedBSMonth.year;
        if (nextM > 12) {
          nextY += 1;
          nextM = 1;
        } else if (nextM < 1) {
          nextY -= 1;
          nextM = 12;
        }
        _displayedBSMonth = NepaliDateTime(nextY, nextM, 1);
      } else {
        _displayedADMonth = DateTime(
          _displayedADMonth.year,
          _displayedADMonth.month + delta,
          1,
        );
      }
    });
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDate = day;
      if (_isNepaliCalendar) {
        final bs = NepaliCalendarConverter.toBS(day);
        if (_displayedBSMonth.year != bs.year || _displayedBSMonth.month != bs.month) {
          _displayedBSMonth = NepaliDateTime(bs.year, bs.month, 1);
        }
      } else {
        if (_displayedADMonth.year != day.year || _displayedADMonth.month != day.month) {
          _displayedADMonth = DateTime(day.year, day.month, 1);
        }
      }
    });
    final iso = DateFormat('yyyy-MM-dd').format(day);
    widget.onDateSelected(iso);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayIso = DateFormat('yyyy-MM-dd').format(now);
    final selectedIso = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // 1. Tasks / Events for Day
    final tasksForDay = widget.allTasks.where((t) => t.dueDate == selectedIso).toList();
    final eventsRemaining = tasksForDay.where((t) => !t.isDone).toList();
    final eventsCompleted = tasksForDay.where((t) => t.isDone).toList();

    // 2. Notes for Day
    final notesForDay = widget.allNotes.where((n) {
      final createdIso = DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(n.createdAt));
      final updatedIso = DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(n.updatedAt));
      return createdIso == selectedIso || updatedIso == selectedIso;
    }).toList();

    // 3. Posts / Moments for Day
    final postsForDay = widget.allPosts.where((p) {
      final createdIso = DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(p.createdAt));
      return createdIso == selectedIso;
    }).toList();

    // 4. Transactions for Day
    final txsForDay = widget.allTransactions.where((t) {
      final txIso = DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(t.transactionTime));
      return txIso == selectedIso;
    }).toList();

    final creamBg = context.appCream;
    final creamText = context.appCreamText;
    final creamBorder = context.appCreamBorder;

    final int firstDay;
    final int daysInMonth;
    final List<String> weekdayHeaders;
    final String monthDisplayTitle;
    final String yearDisplaySubtitle;
    final String selectedSecondaryDate;
    final int displayDayNum;

    if (_isNepaliCalendar) {
      weekdayHeaders = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
      firstDay = (NepaliCalendarConverter.getNepaliMonthStartWeekday(
            _displayedBSMonth.year,
            _displayedBSMonth.month,
          ) - 1) % 7;
      daysInMonth = NepaliCalendarConverter.getDaysInNepaliMonth(
        _displayedBSMonth.year,
        _displayedBSMonth.month,
      );
      monthDisplayTitle = NepaliCalendarConverter.getNepaliMonthName(_displayedBSMonth.month).toUpperCase();
      yearDisplaySubtitle = '${_displayedBSMonth.year} BS';
      final selectedBS = NepaliCalendarConverter.toBS(_selectedDate);
      displayDayNum = selectedBS.day;
      selectedSecondaryDate = DateFormat('MMMM d, yyyy').format(_selectedDate);
    } else {
      weekdayHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      firstDay = (DateTime(_displayedADMonth.year, _displayedADMonth.month, 1).weekday - 1) % 7;
      daysInMonth = DateTime(_displayedADMonth.year, _displayedADMonth.month + 1, 0).day;
      monthDisplayTitle = DateFormat('MMMM').format(_displayedADMonth).toUpperCase();
      yearDisplaySubtitle = '${_displayedADMonth.year}';
      displayDayNum = _selectedDate.day;
      selectedSecondaryDate = NepaliCalendarConverter.formatBSShort(_selectedDate);
    }

    final hasAnyActivity = tasksForDay.isNotEmpty ||
        notesForDay.isNotEmpty ||
        postsForDay.isNotEmpty ||
        txsForDay.isNotEmpty;

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(top: 6, bottom: 26),
      children: [
        // 1. Cream Month Card with Calendar Grid
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: creamBg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large Day Number & Calendar System Toggle (AD / BS)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$displayDayNum',
                    style: AppTypography.bigDisplay.copyWith(color: creamText),
                  ),
                  CalendarSystemToggle(
                    isBS: _isNepaliCalendar,
                    onChanged: _setCalendarSystem,
                    isCreamContext: true,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Month / Year / Weekday Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthDisplayTitle,
                        style: AppTypography.h3.copyWith(
                          color: creamText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$yearDisplaySubtitle · $selectedSecondaryDate',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    DateFormat('EEE').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: creamText,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Navigation arrows
              Row(
                children: [
                  CircularIconButton(
                    icon: AppIcons.back,
                    customColor: Colors.transparent,
                    iconColor: creamText,
                    size: 32,
                    onPressed: () => _changeMonth(-1),
                  ),
                  const SizedBox(width: 8),
                  CircularIconButton(
                    icon: AppIcons.forward,
                    customColor: Colors.transparent,
                    iconColor: creamText,
                    size: 32,
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Weekday Headers Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: weekdayHeaders
                    .map(
                      (w) => SizedBox(
                        width: 32,
                        child: Text(
                          w,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: (_isNepaliCalendar && w == 'S' && weekdayHeaders.indexOf(w) == 6)
                                ? AppColors.accent
                                : creamText.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),

              // Grid items with Multi-Event Segmented Rings
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 1.0,
                ),
                itemCount: firstDay + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < firstDay) {
                    return const SizedBox();
                  }

                  final dayNum = index - firstDay + 1;
                  final DateTime dayDate;
                  final String dayIso;

                  if (_isNepaliCalendar) {
                    final bsDay = NepaliDateTime(
                      _displayedBSMonth.year,
                      _displayedBSMonth.month,
                      dayNum,
                    );
                    dayDate = NepaliCalendarConverter.toAD(bsDay);
                    dayIso = DateFormat('yyyy-MM-dd').format(dayDate);
                  } else {
                    dayDate = DateTime(
                      _displayedADMonth.year,
                      _displayedADMonth.month,
                      dayNum,
                    );
                    dayIso = DateFormat('yyyy-MM-dd').format(dayDate);
                  }

                  final isToday = dayIso == todayIso;
                  final isSelected = dayIso == selectedIso;

                  // Find all events for this specific date
                  final dayTasks = widget.allTasks.where((t) => t.dueDate == dayIso).toList();
                  final eventColors = dayTasks.map(getEventColor).toList();

                  Color fillBg = Colors.transparent;
                  Color textC = creamText;

                  if (isToday) {
                    if (eventColors.isNotEmpty) {
                      fillBg = isSelected
                          ? AppColors.accent.withValues(alpha: 0.22)
                          : AppColors.accent.withValues(alpha: 0.12);
                      textC = isSelected ? creamText : AppColors.accent;
                    } else {
                      fillBg = AppColors.accent;
                      textC = Colors.white;
                    }
                  } else if (isSelected) {
                    fillBg = creamText.withValues(alpha: 0.14);
                    textC = creamText;
                  }

                  return GestureDetector(
                    onTap: () => _selectDay(dayDate),
                    behavior: HitTestBehavior.opaque,
                    child: CustomPaint(
                      foregroundPainter: eventColors.isNotEmpty
                          ? SegmentedRingPainter(
                              colors: eventColors,
                              strokeWidth: isSelected ? 2.8 : 2.2,
                            )
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: fillBg,
                          border: eventColors.isEmpty
                              ? Border.all(
                                  color: isSelected ? AppColors.accent : creamBorder,
                                  width: isSelected ? 2.0 : 1.2,
                                )
                              : (isSelected
                                  ? Border.all(
                                      color: creamText.withValues(alpha: 0.45),
                                      width: 1.2,
                                    )
                                  : null),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$dayNum',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: (isToday || isSelected)
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: textC,
                                ),
                              ),
                              if (isToday && eventColors.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 1),
                                  width: 3.5,
                                  height: 3.5,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.accent,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Selected Day Header with "Event" Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isNepaliCalendar
                      ? '${NepaliCalendarConverter.formatBSShort(_selectedDate)} (${selectedIso == todayIso ? "Today" : selectedIso})'
                      : (selectedIso == todayIso ? 'Today • $selectedIso' : selectedIso),
                  style: AppTypography.h3.copyWith(color: context.appText),
                ),
                const SizedBox(height: 2),
                Text(
                  '${tasksForDay.length} events · ${notesForDay.length} notes · ${postsForDay.length} moments',
                  style: AppTypography.captionMuted.copyWith(color: context.appMuted),
                ),
              ],
            ),
            Tooltip(
              message: 'Add Event',
              child: CircularIconButton(
                icon: AppIcons.plus,
                isSolidWhite: true,
                onPressed: widget.onAddTaskForSelectedDate,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // 3. Unified Day Log Content
        if (!hasAnyActivity) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.appLine, width: 1.0),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(AppIcons.calendar, size: 36, color: context.appMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: 10),
                  Text(
                    'Nothing recorded on this date',
                    style: AppTypography.body.copyWith(
                      color: context.appText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap the + button to add an event for this day.',
                    style: AppTypography.captionMuted.copyWith(color: context.appMuted),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          // --- A. Events Section ---
          if (tasksForDay.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              title: 'Events & Tasks',
              count: tasksForDay.length,
              icon: AppIcons.tasks,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.appLine, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (eventsRemaining.isNotEmpty) ...[
                    for (int i = 0; i < eventsRemaining.length; i++) ...[
                      _buildTaskItem(context, eventsRemaining[i]),
                      if (i < eventsRemaining.length - 1 || eventsCompleted.isNotEmpty)
                        Divider(color: context.appLine, height: 1),
                    ],
                  ],
                  if (eventsCompleted.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 6),
                      child: Text(
                        'Completed (${eventsCompleted.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.appMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    for (int i = 0; i < eventsCompleted.length; i++) ...[
                      _buildTaskItem(context, eventsCompleted[i]),
                      if (i < eventsCompleted.length - 1)
                        Divider(color: context.appLine, height: 1),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // --- B. Notes Section ---
          if (notesForDay.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              title: 'Notes & Thoughts',
              count: notesForDay.length,
              icon: AppIcons.notes,
            ),
            const SizedBox(height: 8),
            for (final note in notesForDay) ...[
              GestureDetector(
                onTap: () => widget.onOpenNote?.call(note),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.appLine, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.accentOrange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(AppIcons.notes, color: AppColors.accentOrange, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.title.isNotEmpty ? note.title : 'Untitled Note',
                              style: AppTypography.h4.copyWith(color: context.appText),
                            ),
                            if (note.body.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                note.body.replaceAll('\n', ' '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.captionMuted.copyWith(color: context.appMuted),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(AppIcons.forward, size: 16, color: context.appMuted),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],

          // --- C. Moments & Posts Section ---
          if (postsForDay.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              title: 'Moments & Posts',
              count: postsForDay.length,
              icon: AppIcons.feed,
            ),
            const SizedBox(height: 8),
            for (final post in postsForDay) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: context.appLine, width: 1.0),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.imagePath.isNotEmpty && File(post.imagePath).existsSync()) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(post.imagePath),
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Moment',
                            style: TextStyle(
                              color: context.appText,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            post.text.isNotEmpty ? post.text : 'Photo update',
                            style: TextStyle(
                              color: context.appText.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('h:mm a').format(DateTime.fromMillisecondsSinceEpoch(post.createdAt)),
                            style: AppTypography.captionMuted.copyWith(color: context.appMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],

          // --- D. Financial Activity Section ---
          if (txsForDay.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              title: 'Financial Activity',
              count: txsForDay.length,
              icon: AppIcons.wallet,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.appLine, width: 1.0),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < txsForDay.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: txsForDay[i].type == 'Income'
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : AppColors.danger.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              AppIcons.getCategoryIcon(txsForDay[i].category),
                              color: txsForDay[i].type == 'Income'
                                  ? AppColors.success
                                  : AppColors.danger,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  txsForDay[i].category,
                                  style: TextStyle(
                                    color: context.appText,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (txsForDay[i].note.isNotEmpty) ...[
                                  Text(
                                    txsForDay[i].note,
                                    style: TextStyle(color: context.appMuted, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            '${txsForDay[i].type == "Income" ? "+" : "-"} ${BudgetRepository.formatAmount(txsForDay[i].amount)}',
                            style: TextStyle(
                              color: txsForDay[i].type == 'Income'
                                  ? AppColors.success
                                  : context.appText,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < txsForDay.length - 1)
                      Divider(color: context.appLine, height: 1),
                  ],
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.accentOrange),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: context.appText,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: context.appSurface2,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.appMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, MyDayTask task) {
    final eventColor = getEventColor(task);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Event color indicator bar
          Container(
            width: 3.5,
            height: 28,
            decoration: BoxDecoration(
              color: eventColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),

          // Check circle button
          GestureDetector(
            onTap: () => widget.onToggleTask(task),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isDone ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color: task.isDone ? AppColors.success : context.appMuted,
                  width: 2.0,
                ),
              ),
              child: task.isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Title & Note
          Expanded(
            child: GestureDetector(
              onTap: () => widget.onEditTask(task),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      style: AppTypography.captionMuted.copyWith(color: context.appMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Edit Event
          CircularIconButton(
            icon: AppIcons.edit,
            size: 30,
            iconSize: 15,
            iconColor: context.appMuted,
            customColor: Colors.transparent,
            onPressed: () => widget.onEditTask(task),
          ),
          const SizedBox(width: 4),

          // Trash
          CircularIconButton(
            icon: AppIcons.trash,
            size: 30,
            iconSize: 15,
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
}

class CalendarPage extends StatefulWidget {
  final TasksRepository tasksRepository;
  final NotesRepository notesRepository;
  final FeedRepository feedRepository;
  final BudgetRepository budgetRepository;
  final String accountId;
  final void Function(MyDayTask)? onEditTask;
  final VoidCallback? onAddTask;
  final void Function(MyDayNote)? onOpenNote;
  final bool isNepaliCalendar;
  final ValueChanged<bool>? onCalendarSystemChanged;
  final Future<void> Function()? onRefresh;

  const CalendarPage({
    super.key,
    required this.tasksRepository,
    required this.notesRepository,
    required this.feedRepository,
    required this.budgetRepository,
    required this.accountId,
    this.onEditTask,
    this.onAddTask,
    this.onOpenNote,
    this.isNepaliCalendar = false,
    this.onCalendarSystemChanged,
    this.onRefresh,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  List<MyDayTask> _allTasks = [];
  List<MyDayNote> _allNotes = [];
  List<MyDayFeedPost> _allPosts = [];
  List<MyDayTransaction> _allTransactions = [];
  String _selectedDate = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().toIso8601String().substring(0, 10);
    _loadData();
  }

  @override
  void didUpdateWidget(covariant CalendarPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final tasks = await widget.tasksRepository
          .getTasks(widget.accountId)
          .timeout(const Duration(seconds: 2));
      final notes = await widget.notesRepository
          .getNotes(widget.accountId)
          .timeout(const Duration(seconds: 2));
      final posts = await widget.feedRepository
          .getPosts(widget.accountId)
          .timeout(const Duration(seconds: 2));
      final txs = await widget.budgetRepository
          .getTransactions(accountId: widget.accountId)
          .timeout(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _allTasks = tasks;
          _allNotes = notes;
          _allPosts = posts;
          _allTransactions = txs;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentOrange));
    }

    final datesWithTasks = _allTasks.map((t) => t.dueDate).toSet();

    return RefreshIndicator(
      color: AppColors.accentOrange,
      backgroundColor: context.appSurface,
      onRefresh: () async {
        if (widget.onRefresh != null) {
          await widget.onRefresh!();
        }
        await _loadData();
      },
      child: CalendarScreen(
        allTasks: _allTasks,
        allNotes: _allNotes,
        allPosts: _allPosts,
        allTransactions: _allTransactions,
        datesWithTasks: datesWithTasks,
        onToggleTask: _onToggleTask,
        onEditTask: (task) {
          TaskBottomSheet.showForAccount(
            context: context,
            tasksRepository: widget.tasksRepository,
            accountId: widget.accountId,
            taskToEdit: task,
            defaultDueDate: task.dueDate,
            isEvent: true, // Renamed to Event for Calendar!
            onSaved: _loadData,
          );
        },
        onDeleteTask: _onDeleteTask,
        onOpenNote: widget.onOpenNote,
        isNepaliCalendar: widget.isNepaliCalendar,
        onCalendarSystemChanged: widget.onCalendarSystemChanged,
        onAddTaskForSelectedDate: () {
          TaskBottomSheet.showForAccount(
            context: context,
            tasksRepository: widget.tasksRepository,
            accountId: widget.accountId,
            defaultDueDate: _selectedDate,
            isEvent: true, // Renamed to Event for Calendar!
            onSaved: _loadData,
          );
        },
        onDateSelected: (date) => setState(() => _selectedDate = date),
        initialSelectedDate: _selectedDate,
      ),
    );
  }
}
