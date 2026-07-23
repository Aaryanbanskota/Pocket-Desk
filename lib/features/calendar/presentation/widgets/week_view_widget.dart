import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../data/models/calendar_event_model.dart';

class WeekViewWidget extends StatelessWidget {
  const WeekViewWidget({
    super.key,
    required this.focusedDay,
    required this.events,
    required this.onEventTap,
  });

  final DateTime focusedDay;
  final List<CalendarEventModel> events;
  final ValueChanged<CalendarEventModel> onEventTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final startOfWeek = DateTimeUtils.startOfWeek(focusedDay);
    final weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop can fit columns side by side. On mobile, we use a horizontal scroll view.
        final double dayColumnWidth = constraints.maxWidth > 800
            ? (constraints.maxWidth - 60) / 7
            : 120.0; // horizontal scrolling columns on mobile

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: SizedBox(
              height: 1440, // Height of the 24-hour grid
              width: 60 + (dayColumnWidth * 7),
              child: Stack(
                children: [
                  // 1. Hourly Grid Lines and Hour Labels
                  for (int hour = 0; hour < 24; hour++) ...[
                    Positioned(
                      top: hour * 60.0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 60.0,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: colorScheme.outlineVariant.withAlpha(40),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 60,
                              padding: const EdgeInsets.only(top: 4, left: 8),
                              child: Text(
                                _formatHour(hour),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant.withAlpha(150),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(child: Container()),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Vertical separators between columns
                  for (int i = 0; i < 7; i++) ...[
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 60.0 + (i * dayColumnWidth),
                      child: Container(
                        width: 0.5,
                        color: colorScheme.outlineVariant.withAlpha(60),
                      ),
                    ),
                    // Column Header label for the day
                    Positioned(
                      top: 4,
                      left: 60.0 + (i * dayColumnWidth),
                      width: dayColumnWidth,
                      height: 50,
                      child: Container(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateTimeUtils.toDayNameShort(weekDays[i]),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: DateTimeUtils.isToday(weekDays[i])
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                weekDays[i].day.toString(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: DateTimeUtils.isToday(weekDays[i])
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // 2. Events Rendered inside respective columns
                  for (int i = 0; i < 7; i++) ...[
                    for (final event in events.where((e) => DateTimeUtils.isSameDay(e.startTime, weekDays[i]))) ...[
                      _buildEventBlock(context, event, 60.0 + (i * dayColumnWidth), dayColumnWidth, theme, colorScheme),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour == 12) return '12 PM';
    return hour > 12 ? '${hour - 12} PM' : '$hour AM';
  }

  Widget _buildEventBlock(
    BuildContext context,
    CalendarEventModel event,
    double leftPos,
    double columnWidth,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final startMin = event.startTime.hour * 60 + event.startTime.minute;
    final endMin = event.endTime.hour * 60 + event.endTime.minute;
    final durationMin = endMin - startMin > 20 ? endMin - startMin : 30;

    // Shift down slightly because headers occupy the first ~50px
    final topPos = 55.0 + (startMin / 60.0) * 55.0;
    final heightVal = (durationMin / 60.0) * 55.0;

    final eventColor = event.colorHex != null ? Color(int.parse(event.colorHex!)) : colorScheme.primary;

    return Positioned(
      top: topPos + 2,
      left: leftPos + 2,
      width: columnWidth - 4,
      height: heightVal - 4,
      child: Material(
        color: eventColor.withAlpha(30),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onEventTap(event),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border(
                left: BorderSide(
                  color: eventColor,
                  width: 3,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (durationMin >= 45) ...[
                  const SizedBox(height: 1),
                  Text(
                    DateTimeUtils.toTime12(event.startTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withAlpha(160),
                      fontSize: 8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
