import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../data/models/calendar_event_model.dart';
import '../../data/models/recurrence_engine.dart';
import '../providers/calendar_events_notifier.dart';
import '../widgets/event_form_sheet.dart';
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
                // Determine range for expansion based on current view type
                late DateTime startRange;
                late DateTime endRange;

                switch (_currentView) {
                  case CalendarViewType.day:
                    startRange = DateTimeUtils.startOfDay(_focusedDay);
                    endRange = DateTimeUtils.endOfDay(_focusedDay);
                    break;
                  case CalendarViewType.week:
                    final startOfWeek = DateTimeUtils.startOfWeek(_focusedDay);
                    startRange = DateTimeUtils.startOfDay(startOfWeek);
                    endRange = DateTimeUtils.endOfDay(startOfWeek.add(const Duration(days: 6)));
                    break;
                  case CalendarViewType.month:
                    final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
                    startRange = DateTimeUtils.startOfDay(startOfMonth.subtract(const Duration(days: 7)));
                    final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
                    endRange = DateTimeUtils.endOfDay(endOfMonth.add(const Duration(days: 7)));
                    break;
                  case CalendarViewType.year:
                    startRange = DateTime(_focusedDay.year, 1, 1);
                    endRange = DateTime(_focusedDay.year, 12, 31, 23, 59, 59);
                    break;
                  case CalendarViewType.agenda:
                    startRange = DateTimeUtils.startOfDay(_focusedDay.subtract(const Duration(days: 30)));
                    endRange = DateTimeUtils.endOfDay(_focusedDay.add(const Duration(days: 365)));
                    break;
                }

                final expandedEvents = RecurrenceEngine.expandEvents(events, startRange, endRange);

                switch (_currentView) {
                  case CalendarViewType.day:
                    return DayViewWidget(
                      focusedDay: _focusedDay,
                      events: expandedEvents,
                      onEventTap: (ev) => _showAddEventDialog(context, editingEvent: ev),
                    );
                  case CalendarViewType.week:
                    return WeekViewWidget(
                      focusedDay: _focusedDay,
                      events: expandedEvents,
                      onEventTap: (ev) => _showAddEventDialog(context, editingEvent: ev),
                    );
                  case CalendarViewType.month:
                    return MonthViewWidget(
                      focusedDay: _focusedDay,
                      events: expandedEvents,
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
                      events: expandedEvents,
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
          initialDate: _focusedDay,
          editingEvent: editingEvent,
        ),
      ),
    );
  }
}

