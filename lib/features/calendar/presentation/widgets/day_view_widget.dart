import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../data/models/calendar_event_model.dart';

class DayViewWidget extends StatelessWidget {
  const DayViewWidget({
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

    // Filter events for this day
    final dayEvents = events.where((e) => DateTimeUtils.isSameDay(e.startTime, focusedDay)).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: SizedBox(
            height: 1400, // height of 24 hours grid
            child: Stack(
              children: [
                // 1. Grid of hours
                for (int hour = 0; hour < 24; hour++) ...[
                  Positioned(
                    top: hour * 58.0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 58.0,
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
                            padding: const EdgeInsets.only(top: 8, left: 8),
                            child: Text(
                              _formatHour(hour),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withAlpha(180),
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

                // 2. Events positioned relative to hours
                for (final event in dayEvents) ...[
                  _buildEventBlock(context, event, theme, colorScheme),
                ],
              ],
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
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final startMin = event.startTime.hour * 60 + event.startTime.minute;
    final endMin = event.endTime.hour * 60 + event.endTime.minute;
    final durationMin = endMin - startMin > 15 ? endMin - startMin : 30; // Min 30 mins display size

    final topPos = (startMin / 60.0) * 58.0;
    final heightVal = (durationMin / 60.0) * 58.0;

    final eventColor = event.colorHex != null ? Color(int.parse(event.colorHex!)) : colorScheme.primary;

    return Positioned(
      top: topPos + 4,
      left: 70,
      right: 16,
      height: heightVal - 8,
      child: Material(
        color: eventColor.withAlpha(25),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onEventTap(event),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border(
                left: BorderSide(
                  color: eventColor,
                  width: 4,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (durationMin >= 45) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${DateTimeUtils.toTime12(event.startTime)} - ${DateTimeUtils.toTime12(event.endTime)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withAlpha(180),
                      fontSize: 10,
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
