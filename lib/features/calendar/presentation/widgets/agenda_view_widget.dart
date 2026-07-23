import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../data/models/calendar_event_model.dart';

class AgendaViewWidget extends StatelessWidget {
  const AgendaViewWidget({
    super.key,
    required this.events,
    required this.onEventTap,
  });

  final List<CalendarEventModel> events;
  final ValueChanged<CalendarEventModel> onEventTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_rounded, size: 64, color: colorScheme.outline.withAlpha(100)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No upcoming events',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Sort events by startTime
    final sortedEvents = List<CalendarEventModel>.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Group events by date string
    final Map<String, List<CalendarEventModel>> grouped = {};
    for (final ev in sortedEvents) {
      final dateStr = DateTimeUtils.toIsoDate(ev.startTime);
      grouped.putIfAbsent(dateStr, () => []).add(ev);
    }

    final datesKeys = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: datesKeys.length,
      itemBuilder: (context, dateIdx) {
        final dateKey = datesKeys[dateIdx];
        final dayEvs = grouped[dateKey] ?? [];
        final parsedDate = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                children: [
                  Text(
                    DateTimeUtils.toRelativeLabel(parsedDate),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '•  ${DateTimeUtils.toFullDate(parsedDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),

            // Events List under this date
            ...dayEvs.map((ev) {
              final eventColor = ev.colorHex != null ? Color(int.parse(ev.colorHex!)) : colorScheme.primary;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                color: colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  side: BorderSide(color: colorScheme.outlineVariant.withAlpha(50)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  onTap: () => onEventTap(ev),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 36,
                          decoration: BoxDecoration(
                            color: eventColor,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ev.title,
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 12, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(
                                    ev.isAllDay
                                        ? 'All Day'
                                        : '${DateTimeUtils.toTime12(ev.startTime)} - ${DateTimeUtils.toTime12(ev.endTime)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (ev.location != null && ev.location!.isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    Icon(Icons.location_on_outlined, size: 12, color: colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        ev.location!,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
