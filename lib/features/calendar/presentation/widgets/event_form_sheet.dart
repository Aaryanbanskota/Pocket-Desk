import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../data/models/calendar_event_model.dart';
import '../providers/calendar_events_notifier.dart';

/// Full-featured event creation/editing bottom sheet.
/// Handles: title, description, location, date/time, all-day, color, category,
/// recurrence type, reminder minutes.
class EventFormSheet extends ConsumerStatefulWidget {
  const EventFormSheet({
    super.key,
    required this.initialDate,
    this.editingEvent,
  });

  final DateTime initialDate;
  final CalendarEventModel? editingEvent;

  @override
  ConsumerState<EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends ConsumerState<EventFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _locCtrl;
  late final TextEditingController _categoryCtrl;

  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;

  bool _isAllDay = false;
  String? _selectedColorHex;
  RecurrenceType _recurrenceType = RecurrenceType.none;
  final List<int> _reminderMinutes = [];

  bool get _isEditing => widget.editingEvent != null;

  // Preset event color options mapped to their hex value
  static const List<_ColorOption> _colorOptions = [
    _ColorOption(color: Color(0xFF4F46E5), label: 'Indigo'),
    _ColorOption(color: Color(0xFF0EA5E9), label: 'Sky'),
    _ColorOption(color: Color(0xFF22C55E), label: 'Green'),
    _ColorOption(color: Color(0xFFF59E0B), label: 'Amber'),
    _ColorOption(color: Color(0xFFEF4444), label: 'Red'),
    _ColorOption(color: Color(0xFF8B5CF6), label: 'Violet'),
    _ColorOption(color: Color(0xFFEC4899), label: 'Pink'),
    _ColorOption(color: Color(0xFF14B8A6), label: 'Teal'),
  ];

  static const List<String> _categories = [
    'Work', 'Personal', 'Health', 'Finance', 'Education', 'Social', 'Other',
  ];

  static const List<_ReminderOption> _reminderOptions = [
    _ReminderOption(minutes: 5, label: '5 min before'),
    _ReminderOption(minutes: 15, label: '15 min before'),
    _ReminderOption(minutes: 30, label: '30 min before'),
    _ReminderOption(minutes: 60, label: '1 hour before'),
    _ReminderOption(minutes: 1440, label: '1 day before'),
  ];

  @override
  void initState() {
    super.initState();
    final ev = widget.editingEvent;
    _titleCtrl = TextEditingController(text: ev?.title);
    _descCtrl = TextEditingController(text: ev?.description);
    _locCtrl = TextEditingController(text: ev?.location);
    _categoryCtrl = TextEditingController(text: ev?.category);

    _startDate = ev?.startTime ?? widget.initialDate;
    _startTime = TimeOfDay.fromDateTime(_startDate);
    _endDate = ev?.endTime ?? widget.initialDate.add(const Duration(hours: 1));
    _endTime = TimeOfDay.fromDateTime(_endDate);

    _isAllDay = ev?.isAllDay ?? false;
    _selectedColorHex = ev?.colorHex;
    _recurrenceType = ev?.recurrenceType ?? RecurrenceType.none;
    if (ev?.reminderMinutes != null) {
      _reminderMinutes.addAll(ev!.reminderMinutes);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedColor = _selectedColorHex != null
        ? Color(int.parse(_selectedColorHex!))
        : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),

          // Top Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                Expanded(
                  child: Text(
                    _isEditing ? 'Edit Event' : 'New Event',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: _saveEvent,
                  style: FilledButton.styleFrom(
                    backgroundColor: selectedColor,
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable form body
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // ── Color Strip at the top ──────────────────────────────
                  _ColorPicker(
                    options: _colorOptions,
                    selectedHex: _selectedColorHex,
                    onSelect: (hex) => setState(() => _selectedColorHex = hex),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Title ────────────────────────────────────────────────
                  TextFormField(
                    controller: _titleCtrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Event title',
                      hintStyle: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface.withAlpha(80),
                        fontWeight: FontWeight.bold,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: selectedColor, width: 2),
                      ),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Title is required' : null,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Section: Date & Time ────────────────────────────────
                  const _SectionHeader(icon: Icons.schedule_rounded, label: 'Date & Time'),
                  const SizedBox(height: AppSpacing.sm),

                  // All Day toggle
                  _FormRow(
                    child: Row(
                      children: [
                        const Icon(Icons.wb_sunny_outlined, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'All Day',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Switch(
                          value: _isAllDay,
                          onChanged: (v) => setState(() => _isAllDay = v),
                          activeColor: selectedColor,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Start date/time row
                  _FormRow(
                    child: Row(
                      children: [
                        const Icon(Icons.play_arrow_rounded, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Starts',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        _DateChip(
                          date: _startDate,
                          onTap: () => _pickDate(isStart: true),
                          color: selectedColor,
                        ),
                        if (!_isAllDay) ...[
                          const SizedBox(width: AppSpacing.sm),
                          _TimeChip(
                            time: _startTime,
                            onTap: () => _pickTime(isStart: true),
                            color: selectedColor,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // End date/time row
                  _FormRow(
                    child: Row(
                      children: [
                        const Icon(Icons.stop_rounded, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Ends',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        _DateChip(
                          date: _endDate,
                          onTap: () => _pickDate(isStart: false),
                          color: selectedColor,
                        ),
                        if (!_isAllDay) ...[
                          const SizedBox(width: AppSpacing.sm),
                          _TimeChip(
                            time: _endTime,
                            onTap: () => _pickTime(isStart: false),
                            color: selectedColor,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Recurrence ─────────────────────────────────────────
                  const _SectionHeader(icon: Icons.repeat_rounded, label: 'Repeat'),
                  const SizedBox(height: AppSpacing.sm),
                  _FormRow(
                    child: DropdownButtonFormField<RecurrenceType>(
                      value: _recurrenceType,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      isExpanded: true,
                      items: RecurrenceType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_recurrenceLabel(type)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _recurrenceType = val);
                      },
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Reminders ──────────────────────────────────────────
                  const _SectionHeader(icon: Icons.notifications_outlined, label: 'Reminders'),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: _reminderOptions.map((opt) {
                      final selected = _reminderMinutes.contains(opt.minutes);
                      return FilterChip(
                        label: Text(opt.label),
                        selected: selected,
                        selectedColor: selectedColor.withAlpha(30),
                        checkmarkColor: selectedColor,
                        side: BorderSide(
                          color: selected
                              ? selectedColor
                              : colorScheme.outlineVariant,
                        ),
                        onSelected: (on) {
                          setState(() {
                            if (on) {
                              _reminderMinutes.add(opt.minutes);
                            } else {
                              _reminderMinutes.remove(opt.minutes);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Location ───────────────────────────────────────────
                  const _SectionHeader(icon: Icons.location_on_outlined, label: 'Location'),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _locCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Add a location or link',
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Category ───────────────────────────────────────────
                  const _SectionHeader(icon: Icons.label_outline_rounded, label: 'Category'),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: _categories.map((cat) {
                      final selected = _categoryCtrl.text == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: selected,
                        selectedColor: selectedColor.withAlpha(30),
                        side: BorderSide(
                          color: selected
                              ? selectedColor
                              : colorScheme.outlineVariant,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _categoryCtrl.text = selected ? '' : cat;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Description ────────────────────────────────────────
                  const _SectionHeader(icon: Icons.notes_rounded, label: 'Description'),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Add notes or description...',
                      alignLabelWithHint: true,
                    ),
                  ),

                  // ── Delete button (edit mode only) ─────────────────────
                  if (_isEditing) ...[
                    const SizedBox(height: AppSpacing.x2l),
                    FilledButton.tonal(
                      onPressed: _deleteEvent,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.errorContainer,
                        foregroundColor: colorScheme.onErrorContainer,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Delete Event'),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.x4l),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _recurrenceLabel(RecurrenceType type) {
    return switch (type) {
      RecurrenceType.none => 'Does not repeat',
      RecurrenceType.daily => 'Daily',
      RecurrenceType.weekly => 'Weekly',
      RecurrenceType.monthly => 'Monthly',
      RecurrenceType.yearly => 'Annually',
      RecurrenceType.custom => 'Custom',
    };
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        // Auto-advance end date if it's before the new start date
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(hours: 1));
          _endTime = TimeOfDay.fromDateTime(_endDate);
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  DateTime _combine(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  void _saveEvent() {
    if (!_formKey.currentState!.validate()) return;

    final startDateTime = _isAllDay
        ? DateTimeUtils.startOfDay(_startDate)
        : _combine(_startDate, _startTime);
    final endDateTime = _isAllDay
        ? DateTimeUtils.endOfDay(_endDate)
        : _combine(_endDate, _endTime);

    if (!_isAllDay && endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    ref.read(calendarEventsProvider.notifier).addOrUpdateEvent(
          title: _titleCtrl.text.trim(),
          startTime: startDateTime,
          endTime: endDateTime,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          location: _locCtrl.text.trim().isEmpty ? null : _locCtrl.text.trim(),
          isAllDay: _isAllDay,
          category: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
          colorHex: _selectedColorHex,
          recurrenceType: _recurrenceType,
          reminderMinutes: List.from(_reminderMinutes),
          eventId: widget.editingEvent?.id,
        );

    Navigator.pop(context);
  }

  void _deleteEvent() {
    if (widget.editingEvent == null) return;
    ref.read(calendarEventsProvider.notifier).deleteEvent(widget.editingEvent!.id);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted "${widget.editingEvent!.title}"')),
    );
  }
}

// ─── Private Sub-Widgets ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: child,
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.onTap,
    required this.color,
  });
  final DateTime date;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Text(
          DateTimeUtils.toMediumDate(date),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.time,
    required this.onTap,
    required this.color,
  });
  final TimeOfDay time;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Text(
          time.format(context),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.options,
    required this.selectedHex,
    required this.onSelect,
  });
  final List<_ColorOption> options;
  final String? selectedHex;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: options.map((opt) {
        final hex = '0x${opt.color.value.toRadixString(16).toUpperCase().padLeft(8, '0')}';
        final isSelected = selectedHex == hex;
        return GestureDetector(
          onTap: () => onSelect(hex),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: opt.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: opt.color.withAlpha(100), blurRadius: 8, spreadRadius: 2)]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _ColorOption {
  const _ColorOption({required this.color, required this.label});
  final Color color;
  final String label;
}

class _ReminderOption {
  const _ReminderOption({required this.minutes, required this.label});
  final int minutes;
  final String label;
}
