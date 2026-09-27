import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/utils/nepali_date.dart';
import '../../data/models/calendar_event_model.dart';

class MonthViewWidget extends StatelessWidget {
  const MonthViewWidget({
    super.key,
    required this.focusedDay,
    required this.events,
    required this.onDayTap,
    required this.onEventTap,
    this.isBsCalendar = true,
  });

  final DateTime focusedDay;
  final List<CalendarEventModel> events;
  final ValueChanged<DateTime> onDayTap;
  final ValueChanged<CalendarEventModel> onEventTap;
  final bool isBsCalendar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<DateTime> gridDays = [];

    if (isBsCalendar) {
      final nepaliFocused = NepaliDate.fromDateTime(focusedDay);
      final firstDayOfBsMonth = NepaliDate(year: nepaliFocused.year, month: nepaliFocused.month, day: 1);
      final daysInBsMonth = NepaliDate.getDaysInBsMonth(nepaliFocused.year, nepaliFocused.month);

      final firstDayWeekday = firstDayOfBsMonth.weekday; // 1 = Mon, 7 = Sun
      final int leadingEmptyDays = firstDayWeekday % 7;
      final firstDayAd = firstDayOfBsMonth.toDateTime();

      for (int i = leadingEmptyDays; i > 0; i--) {
        gridDays.add(firstDayAd.subtract(Duration(days: i)));
      }
      for (int i = 0; i < daysInBsMonth; i++) {
        gridDays.add(firstDayAd.add(Duration(days: i)));
      }
    } else {
      final firstDayOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
      final lastDayOfMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0);

      final int leadingEmptyDays = firstDayOfMonth.weekday % 7; // 0 = Sun
      final prevMonthLastDay = DateTime(focusedDay.year, focusedDay.month, 0);

      for (int i = leadingEmptyDays - 1; i >= 0; i--) {
        gridDays.add(prevMonthLastDay.subtract(Duration(days: i)));
      }
      for (int i = 1; i <= lastDayOfMonth.day; i++) {
        gridDays.add(DateTime(focusedDay.year, focusedDay.month, i));
      }
    }

    final totalGridCells = ((gridDays.length / 7).ceil()) * 7;
    final remainingCells = totalGridCells - gridDays.length;
    final lastDayAd = gridDays.last;
    for (int i = 1; i <= remainingCells; i++) {
      gridDays.add(lastDayAd.add(Duration(days: i)));
    }

    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Column(
      children: [
        // Week headers
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((d) {
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1),

        // Grid View
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellHeight = constraints.maxHeight / (totalGridCells / 7);

              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: constraints.maxWidth / 7 / cellHeight,
                ),
                itemCount: totalGridCells,
                itemBuilder: (context, idx) {
                  final date = gridDays[idx];

                  final isCurrentMonth = isBsCalendar
                      ? (NepaliDate.fromDateTime(date).month == NepaliDate.fromDateTime(focusedDay).month &&
                          NepaliDate.fromDateTime(date).year == NepaliDate.fromDateTime(focusedDay).year)
                      : (date.month == focusedDay.month && date.year == focusedDay.year);
                  final dayText = isBsCalendar ? NepaliDate.fromDateTime(date).day.toString() : date.day.toString();
                  final isToday = DateTimeUtils.isToday(date);
                  final isFocused = DateTimeUtils.isSameDay(date, focusedDay);
                  final dayEvents = events.where((e) => DateTimeUtils.isSameDay(e.startTime, date)).toList();

                  return InkWell(
                    onTap: () => onDayTap(date),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.outlineVariant.withAlpha(30),
                          width: 0.5,
                        ),
                        color: isFocused
                            ? colorScheme.primaryContainer.withAlpha(40)
                            : Colors.transparent,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 4),
                          // Day Number label
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isToday ? colorScheme.primary : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                dayText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isToday
                                      ? colorScheme.onPrimary
                                      : isCurrentMonth
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurfaceVariant.withAlpha(100),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Events snippet list for this day
                          Expanded(
                            child: ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              itemCount: dayEvents.length > 2 ? 3 : dayEvents.length,
                              itemBuilder: (context, eventIdx) {
                                if (eventIdx == 2 && dayEvents.length > 2) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                    child: Text(
                                      '+${dayEvents.length - 2} more',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  );
                                }

                                final ev = dayEvents[eventIdx];
                                final evColor = ev.colorHex != null ? Color(int.parse(ev.colorHex!)) : colorScheme.primary;

                                return InkWell(
                                  onTap: () => onEventTap(ev),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 1),
                                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: evColor.withAlpha(20),
                                      borderRadius: BorderRadius.circular(2),
                                      border: Border(
                                        left: BorderSide(
                                          color: evColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      ev.title,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
