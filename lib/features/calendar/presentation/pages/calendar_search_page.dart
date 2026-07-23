import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../data/models/calendar_event_model.dart';
import '../providers/calendar_events_notifier.dart';
import '../widgets/event_form_sheet.dart';

/// Search delegate for calendar events.
class CalendarSearchPage extends ConsumerStatefulWidget {
  const CalendarSearchPage({super.key});

  @override
  ConsumerState<CalendarSearchPage> createState() => _CalendarSearchPageState();
}

class _CalendarSearchPageState extends ConsumerState<CalendarSearchPage> {
  final _ctrl = TextEditingController();
  String _query = '';
  String? _filterCategory;
  RecurrenceType? _filterRecurrence;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<CalendarEventModel> _filter(List<CalendarEventModel> events) {
    var result = events;
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      result = result.where((e) =>
        e.title.toLowerCase().contains(q) ||
        (e.description?.toLowerCase().contains(q) ?? false) ||
        (e.location?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    if (_filterCategory != null) {
      result = result.where((e) => e.category == _filterCategory).toList();
    }
    if (_filterRecurrence != null) {
      result = result.where((e) => e.recurrenceType == _filterRecurrence).toList();
    }
    result.sort((a, b) => a.startTime.compareTo(b.startTime));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final eventsAsync = ref.watch(calendarEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search events…',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filters',
            onPressed: () => _showFilters(context, eventsAsync.valueOrNull ?? []),
          ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (events) {
          final results = _filter(events);
          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 56, color: cs.outline.withAlpha(120)),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _query.isEmpty ? 'Type to search events' : 'No events found',
                    style: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: results.length,
            itemBuilder: (ctx, i) {
              final ev = results[i];
              final color = ev.colorHex != null ? Color(int.parse(ev.colorHex!)) : cs.primary;
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                color: cs.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  onTap: () => _openEdit(context, ev),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ev.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(
                                ev.isAllDay
                                    ? DateTimeUtils.toMediumDate(ev.startTime)
                                    : '${DateTimeUtils.toMediumDate(ev.startTime)}  •  ${DateTimeUtils.toTime12(ev.startTime)}',
                                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                              ),
                              if (ev.category != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(20),
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                    border: Border.all(color: color.withAlpha(60)),
                                  ),
                                  child: Text(ev.category!, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openEdit(BuildContext context, CalendarEventModel ev) {
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
        builder: (_, __) => EventFormSheet(initialDate: ev.startTime, editingEvent: ev),
      ),
    );
  }

  void _showFilters(BuildContext context, List<CalendarEventModel> events) {
    // Collect unique categories
    final cats = events.map((e) => e.category).whereType<String>().toSet().toList();

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final theme = Theme.of(ctx);
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filters', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.md),
                Text('Category', style: theme.textTheme.labelMedium),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _filterCategory == null,
                      onSelected: (_) { setModalState(() {}); setState(() => _filterCategory = null); },
                    ),
                    ...cats.map((cat) => FilterChip(
                      label: Text(cat),
                      selected: _filterCategory == cat,
                      onSelected: (_) { setModalState(() {}); setState(() => _filterCategory = _filterCategory == cat ? null : cat); },
                    )),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Recurrence', style: theme.textTheme.labelMedium),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: RecurrenceType.values.map((rt) => FilterChip(
                    label: Text(_rtLabel(rt)),
                    selected: _filterRecurrence == rt,
                    onSelected: (_) { setModalState(() {}); setState(() => _filterRecurrence = _filterRecurrence == rt ? null : rt); },
                  )).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _rtLabel(RecurrenceType rt) {
    return switch (rt) {
      RecurrenceType.none => 'One-time',
      RecurrenceType.daily => 'Daily',
      RecurrenceType.weekly => 'Weekly',
      RecurrenceType.monthly => 'Monthly',
      RecurrenceType.yearly => 'Yearly',
      RecurrenceType.custom => 'Custom',
    };
  }
}
