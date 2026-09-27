import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../data/models/calendar_event_model.dart';
import '../providers/calendar_events_notifier.dart';
import 'event_form_sheet.dart';

class EventPreviewDialog extends ConsumerWidget {
  const EventPreviewDialog({super.key, required this.event});
  final CalendarEventModel event;

  static void show(BuildContext context, CalendarEventModel event) {
    showDialog<void>(
      context: context,
      builder: (ctx) => EventPreviewDialog(event: event),
    );
  }

  Color _parseColor(String? hex, Color defaultColor) {
    if (hex == null || hex.isEmpty) return defaultColor;
    try {
      final hexVal = hex.replaceAll('#', '');
      if (hexVal.length == 6) {
        return Color(int.parse('FF$hexVal', radix: 16));
      } else if (hexVal.length == 8) {
        return Color(int.parse(hexVal, radix: 16));
      }
    } catch (_) {}
    return defaultColor;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final eventColor = _parseColor(event.colorHex, cs.primary);
    final timeString = event.isAllDay
        ? 'All Day (${DateTimeUtils.toFullDate(event.startTime)})'
        : '${DateTimeUtils.toFullDate(event.startTime)} • ${DateTimeUtils.toTime12(event.startTime)} - ${DateTimeUtils.toTime12(event.endTime)}';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 12,
            height: 24,
            decoration: BoxDecoration(
              color: eventColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              event.title,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Event',
            onPressed: () {
              Navigator.pop(context);
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (_) => DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: 0.85,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  builder: (_, scrollController) => EventFormSheet(
                    initialDate: event.startTime,
                    editingEvent: event,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: cs.error),
            tooltip: 'Delete Event',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Event?'),
                  content: Text('Are you sure you want to delete "${event.title}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(backgroundColor: cs.error),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(calendarEventsProvider.notifier).deleteEvent(event.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    timeString,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            if (event.location != null && event.location!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.location!,
                      style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ],
            if (event.category != null && event.category!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.label_outline, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(event.category!, style: const TextStyle(fontSize: 12)),
                    backgroundColor: eventColor.withAlpha(25),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
            if (event.description != null && event.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Description',
                style: tt.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                event.description!,
                style: tt.bodyMedium,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
