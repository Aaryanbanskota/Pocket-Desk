import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart';

import '../../../features/tasks/data/tasks_repository.dart';
import '../../utils/nepali_calendar_converter.dart';
import '../app_colors.dart';
import '../calendar_event_indicators.dart';
import 'calendar_system_toggle.dart';

/// Cream Hero Card (.card.cream.hero in prototype)
class CreamHeroCard extends StatelessWidget {
  final DateTime date;
  final String userName;
  final int openTasksCount;
  final int notesCount;
  final Set<String> datesWithTasks;
  final List<MyDayTask>? tasks;
  final String? nepaliDateString;
  final bool isNepaliCalendar;
  final ValueChanged<bool>? onToggleCalendarSystem;
  final ValueChanged<DateTime>? onSelectDate;

  const CreamHeroCard({
    super.key,
    required this.date,
    required this.userName,
    required this.openTasksCount,
    required this.notesCount,
    required this.datesWithTasks,
    this.tasks,
    this.nepaliDateString,
    this.isNepaliCalendar = false,
    this.onToggleCalendarSystem,
    this.onSelectDate,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final creamBg = context.appCream;
    final creamText = context.appCreamText;
    final creamBorder = context.appCreamBorder;

    final now = DateTime.now();
    final todayIso = DateFormat('yyyy-MM-dd').format(now);

    final String monthName;
    final String secondaryDateString;
    final int leadingBlanks;
    final int daysInMonth;
    final List<String> weekdayHeaders;
    final NepaliDateTime bsNow = NepaliCalendarConverter.toBS(date);

    if (isNepaliCalendar) {
      monthName = NepaliCalendarConverter.getNepaliMonthName(bsNow.month).toUpperCase();
      secondaryDateString = DateFormat('MMMM d, yyyy').format(date);
      weekdayHeaders = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
      leadingBlanks = (NepaliCalendarConverter.getNepaliMonthStartWeekday(bsNow.year, bsNow.month) - 1) % 7;
      daysInMonth = NepaliCalendarConverter.getDaysInNepaliMonth(bsNow.year, bsNow.month);
    } else {
      monthName = DateFormat('MMMM').format(date).toUpperCase();
      secondaryDateString = NepaliCalendarConverter.formatBSShort(date);
      weekdayHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      leadingBlanks = (DateTime(date.year, date.month, 1).weekday - 1) % 7;
      daysInMonth = DateTime(date.year, date.month + 1, 0).day;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: creamBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Greeting / status and Calendar switch toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '${_getGreeting()}, $userName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: creamText,
                  ),
                ),
              ),
              if (onToggleCalendarSystem != null)
                CalendarSystemToggle(
                  isBS: isNepaliCalendar,
                  onChanged: onToggleCalendarSystem!,
                  isCreamContext: true,
                ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side: Prominent Dual Date Display (Larger text: 19 October 2026 Monday · Kartik 2 2083)
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isNepaliCalendar
                          ? '${bsNow.day} $monthName ${bsNow.year}'
                          : '${date.day} $monthName ${date.year}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: creamText,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isNepaliCalendar
                          ? '${DateFormat('EEEE').format(date)} · $secondaryDateString'
                          : '${DateFormat('EEEE').format(date)} · $secondaryDateString',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      NepaliCalendarConverter.formatBSDevanagari(date),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: creamText.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Right side: Compact Mini calendar grid (Decreased button size)
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    // Weekday headers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: weekdayHeaders
                          .map(
                            (w) => SizedBox(
                              width: 14,
                              child: Text(
                                w,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w700,
                                  color: (isNepaliCalendar && w == 'S' && weekdayHeaders.indexOf(w) == 6)
                                      ? AppColors.accent
                                      : creamText.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 4),

                    // Grid days
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: leadingBlanks + daysInMonth,
                      itemBuilder: (context, index) {
                        if (index < leadingBlanks) {
                          return const SizedBox();
                        }

                        final dayInt = index - leadingBlanks + 1;
                        final DateTime dayDate;
                        final String dayIso;

                        if (isNepaliCalendar) {
                          final bsDay = NepaliDateTime(bsNow.year, bsNow.month, dayInt);
                          dayDate = NepaliCalendarConverter.toAD(bsDay);
                          dayIso = DateFormat('yyyy-MM-dd').format(dayDate);
                        } else {
                          dayDate = DateTime(date.year, date.month, dayInt);
                          dayIso = DateFormat('yyyy-MM-dd').format(dayDate);
                        }

                        final isToday = dayIso == todayIso;
                        final dayTasks = tasks?.where((t) => t.dueDate == dayIso).toList() ?? [];
                        final eventColors = dayTasks.map(getEventColor).toList();
                        final hasTasks = eventColors.isNotEmpty || datesWithTasks.contains(dayIso);

                        return _buildMiniDayNode(
                          day: dayInt,
                          dayDate: dayDate,
                          isToday: isToday,
                          hasTasks: hasTasks,
                          eventColors: eventColors,
                          creamText: creamText,
                          creamBorder: creamBorder,
                          onTap: onSelectDate != null ? () => onSelectDate!(dayDate) : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Summary (small, clean text)
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 11,
                color: creamText.withValues(alpha: 0.85),
                height: 1.25,
              ),
              children: [
                TextSpan(text: 'Hey $userName, you have '),
                TextSpan(
                  text: '$openTasksCount open ${openTasksCount == 1 ? 'task' : 'tasks'}',
                  style: TextStyle(fontWeight: FontWeight.w700, color: creamText),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: '$notesCount ${notesCount == 1 ? 'note' : 'notes'}',
                  style: TextStyle(fontWeight: FontWeight.w700, color: creamText),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniDayNode({
    required int day,
    required DateTime dayDate,
    required bool isToday,
    required bool hasTasks,
    required List<Color> eventColors,
    required Color creamText,
    required Color creamBorder,
    VoidCallback? onTap,
  }) {
    Color nodeBg = Colors.transparent;
    Color nodeBorder = creamBorder;
    Color textC = creamText.withValues(alpha: 0.7);

    if (isToday) {
      if (eventColors.isNotEmpty) {
        nodeBg = AppColors.accent.withValues(alpha: 0.16);
        nodeBorder = Colors.transparent;
        textC = AppColors.accent;
      } else {
        nodeBg = AppColors.accent;
        nodeBorder = AppColors.accent;
        textC = Colors.white;
      }
    } else if (hasTasks && eventColors.isEmpty) {
      nodeBg = creamText.withValues(alpha: 0.15);
      nodeBorder = creamText.withValues(alpha: 0.5);
      textC = creamText;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        foregroundPainter: eventColors.isNotEmpty
            ? SegmentedRingPainter(
                colors: eventColors,
                strokeWidth: isToday ? 1.4 : 1.1,
                gap: 0.18,
              )
            : null,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: nodeBg,
            border: eventColors.isEmpty
                ? Border.all(color: nodeBorder, width: isToday ? 1.2 : 0.8)
                : null,
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 7.5,
                fontWeight: (isToday || hasTasks) ? FontWeight.w700 : FontWeight.w500,
                color: textC,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
