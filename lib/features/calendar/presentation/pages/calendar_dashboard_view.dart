import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../data/models/calendar_event_model.dart';
import '../providers/calendar_events_notifier.dart';

class CalendarDashboardView extends ConsumerStatefulWidget {
  const CalendarDashboardView({super.key});

  @override
  ConsumerState<CalendarDashboardView> createState() => _CalendarDashboardViewState();
}

class _CalendarDashboardViewState extends ConsumerState<CalendarDashboardView> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final eventsAsync = ref.watch(calendarEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddEventDialog(context),
          ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (events) {
          final dayEvents = events.where((e) => DateTimeUtils.isSameDay(e.startTime, _focusedDay)).toList();

          return Column(
            children: [
              _buildMonthHeader(theme),
              _buildWeekStrip(colorScheme),
              const Divider(height: 1),
              Expanded(
                child: dayEvents.isEmpty
                    ? _buildEmptyState(theme, colorScheme)
                    : _buildEventsList(dayEvents, theme, colorScheme),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateTimeUtils.toMonthYear(_focusedDay),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setState(() {
                  _focusedDay = _focusedDay.subtract(const Duration(days: 30));
                }),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => setState(() {
                  _focusedDay = _focusedDay.add(const Duration(days: 30));
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStrip(ColorScheme colorScheme) {
    final startOfWeek = DateTimeUtils.startOfWeek(_focusedDay);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final date = startOfWeek.add(Duration(days: i));
          final isSelected = DateTimeUtils.isSameDay(date, _focusedDay);

          return InkWell(
            onTap: () => setState(() => _focusedDay = date),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: isSelected
                    ? null
                    : Border.all(
                        color: colorScheme.outlineVariant.withAlpha(50),
                      ),
              ),
              child: Column(
                children: [
                  Text(
                    DateTimeUtils.toDayNameShort(date),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 64, color: colorScheme.outline.withAlpha(100)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No events scheduled',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap the + button to add a new event.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<CalendarEventModel> events, ThemeData theme, ColorScheme colorScheme) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final ev = events[index];
        final eventColor = ev.colorHex != null ? Color(int.parse(ev.colorHex!)) : colorScheme.primary;

        return Dismissible(
          key: Key('event-${ev.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            decoration: BoxDecoration(
              color: colorScheme.error,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: const Icon(Icons.delete_forever_rounded, color: Colors.white),
          ),
          onDismissed: (_) {
            ref.read(calendarEventsProvider.notifier).deleteEvent(ev.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Deleted "${ev.title}"')),
            );
          },
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              side: BorderSide(color: colorScheme.outlineVariant.withAlpha(50)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              onTap: () => _showAddEventDialog(context, editingEvent: ev),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 48,
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
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                '${DateTimeUtils.toTime12(ev.startTime)} - ${DateTimeUtils.toTime12(ev.endTime)}',
                                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                          if (ev.location != null && ev.location!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    ev.location!,
                                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddEventDialog(BuildContext context, {CalendarEventModel? editingEvent}) {
    final titleController = TextEditingController(text: editingEvent?.title);
    final descController = TextEditingController(text: editingEvent?.description);
    final locController = TextEditingController(text: editingEvent?.location);

    TimeOfDay startTime = TimeOfDay.fromDateTime(editingEvent?.startTime ?? DateTime.now());
    TimeOfDay endTime = TimeOfDay.fromDateTime(editingEvent?.endTime ?? DateTime.now().add(const Duration(hours: 1)));

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(editingEvent == null ? 'Add Event' : 'Edit Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: locController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Start Time: ${startTime.format(ctx)}'),
                  TextButton(
                    onPressed: () async {
                      final picked = await showTimePicker(context: ctx, initialTime: startTime);
                      if (picked != null) {
                        startTime = picked;
                      }
                    },
                    child: const Text('Pick'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('End Time: ${endTime.format(ctx)}'),
                  TextButton(
                    onPressed: () async {
                      final picked = await showTimePicker(context: ctx, initialTime: endTime);
                      if (picked != null) {
                        endTime = picked;
                      }
                    },
                    child: const Text('Pick'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;

              final startDateTime = DateTime(
                _focusedDay.year,
                _focusedDay.month,
                _focusedDay.day,
                startTime.hour,
                startTime.minute,
              );
              final endDateTime = DateTime(
                _focusedDay.year,
                _focusedDay.month,
                _focusedDay.day,
                endTime.hour,
                endTime.minute,
              );

              ref.read(calendarEventsProvider.notifier).addOrUpdateEvent(
                    title: titleController.text.trim(),
                    startTime: startDateTime,
                    endTime: endDateTime,
                    description: descController.text.trim(),
                    location: locController.text.trim(),
                    eventId: editingEvent?.id,
                  );

              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
