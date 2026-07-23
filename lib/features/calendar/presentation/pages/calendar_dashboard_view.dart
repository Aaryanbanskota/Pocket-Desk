import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../data/models/calendar_event_model.dart';
import '../providers/calendar_events_notifier.dart';
import '../widgets/agenda_view_widget.dart';
import '../widgets/day_view_widget.dart';
import '../widgets/month_view_widget.dart';
import '../widgets/week_view_widget.dart';
import '../widgets/year_view_widget.dart';

enum CalendarViewType { day, week, month, year, agenda }

class CalendarDashboardView extends ConsumerStatefulWidget {
  const CalendarDashboardView({super.key});

  @override
  ConsumerState<CalendarDashboardView> createState() => _CalendarDashboardViewState();
}

class _CalendarDashboardViewState extends ConsumerState<CalendarDashboardView> {
  DateTime _focusedDay = DateTime.now();
  CalendarViewType _currentView = CalendarViewType.month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventsAsync = ref.watch(calendarEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded),
            tooltip: 'Go to Today',
            onPressed: () => setState(() => _focusedDay = DateTime.now()),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Event',
            onPressed: () => _showAddEventDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Selector segment for Calendar Views
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: SegmentedButton<CalendarViewType>(
              segments: const [
                ButtonSegment(
                  value: CalendarViewType.day,
                  label: Text('Day'),
                  icon: Icon(Icons.view_day_outlined),
                ),
                ButtonSegment(
                  value: CalendarViewType.week,
                  label: Text('Week'),
                  icon: Icon(Icons.view_week_outlined),
                ),
                ButtonSegment(
                  value: CalendarViewType.month,
                  label: Text('Month'),
                  icon: Icon(Icons.calendar_view_month_outlined),
                ),
                ButtonSegment(
                  value: CalendarViewType.year,
                  label: Text('Year'),
                  icon: Icon(Icons.calendar_today_outlined),
                ),
                ButtonSegment(
                  value: CalendarViewType.agenda,
                  label: Text('Agenda'),
                  icon: Icon(Icons.view_agenda_outlined),
                ),
              ],
              selected: {_currentView},
              onSelectionChanged: (Set<CalendarViewType> selection) {
                setState(() {
                  _currentView = selection.first;
                });
              },
            ),
          ),

          // 2. Month Navigation Header (hidden for Year/Agenda views to save vertical space if needed, or shown generally)
          if (_currentView != CalendarViewType.year && _currentView != CalendarViewType.agenda)
            _buildMonthHeader(theme),

          const Divider(height: 1),

          // 3. Main View Render
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (events) {
                switch (_currentView) {
                  case CalendarViewType.day:
                    return DayViewWidget(
                      focusedDay: _focusedDay,
                      events: events,
                      onEventTap: (ev) => _showAddEventDialog(context, editingEvent: ev),
                    );
                  case CalendarViewType.week:
                    return WeekViewWidget(
                      focusedDay: _focusedDay,
                      events: events,
                      onEventTap: (ev) => _showAddEventDialog(context, editingEvent: ev),
                    );
                  case CalendarViewType.month:
                    return MonthViewWidget(
                      focusedDay: _focusedDay,
                      events: events,
                      onDayTap: (date) => setState(() {
                        _focusedDay = date;
                      }),
                      onEventTap: (ev) => _showAddEventDialog(context, editingEvent: ev),
                    );
                  case CalendarViewType.year:
                    return YearViewWidget(
                      focusedDay: _focusedDay,
                      onMonthDayTap: (date) => setState(() {
                        _focusedDay = date;
                        _currentView = CalendarViewType.day; // switch to day view for tapped date
                      }),
                    );
                  case CalendarViewType.agenda:
                    return AgendaViewWidget(
                      events: events,
                      onEventTap: (ev) => _showAddEventDialog(context, editingEvent: ev),
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
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
                  if (_currentView == CalendarViewType.day) {
                    _focusedDay = _focusedDay.subtract(const Duration(days: 1));
                  } else if (_currentView == CalendarViewType.week) {
                    _focusedDay = _focusedDay.subtract(const Duration(days: 7));
                  } else {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, _focusedDay.day);
                  }
                }),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => setState(() {
                  if (_currentView == CalendarViewType.day) {
                    _focusedDay = _focusedDay.add(const Duration(days: 1));
                  } else if (_currentView == CalendarViewType.week) {
                    _focusedDay = _focusedDay.add(const Duration(days: 7));
                  } else {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, _focusedDay.day);
                  }
                }),
              ),
            ],
          ),
        ],
      ),
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
          if (editingEvent != null)
            TextButton(
              onPressed: () {
                ref.read(calendarEventsProvider.notifier).deleteEvent(editingEvent.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted "${editingEvent.title}"')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'),
            ),
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
