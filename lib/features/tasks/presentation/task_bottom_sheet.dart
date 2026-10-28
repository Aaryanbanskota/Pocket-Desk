import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/app_bottom_sheet.dart';
import '../data/tasks_repository.dart';

class TaskBottomSheet {
  static Future<void> show({
    required BuildContext context,
    MyDayTask? taskToEdit,
    required String defaultDueDate,
    bool isEvent = false,
    required FutureOr<void> Function({
      required String title,
      required String kind,
      required int minDuration,
      required String dueDate,
      required bool isImportant,
      required List<String> tags,
      required String repeatInterval,
      required String note,
    }) onSave,
  }) {
    return AppBottomSheet.show(
      context: context,
      title: taskToEdit != null
          ? (isEvent ? 'Edit Event' : 'Edit task')
          : (isEvent ? 'Add Event' : 'Add task'),
      child: _TaskSheetContent(
        taskToEdit: taskToEdit,
        defaultDueDate: defaultDueDate,
        isEvent: isEvent,
        onSave: onSave,
      ),
    );
  }

  static Future<void> showForAccount({
    required BuildContext context,
    required TasksRepository tasksRepository,
    required String accountId,
    MyDayTask? taskToEdit,
    String? defaultDueDate,
    bool isEvent = false,
    VoidCallback? onSaved,
  }) {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return show(
      context: context,
      taskToEdit: taskToEdit,
      defaultDueDate: defaultDueDate ?? todayStr,
      isEvent: isEvent,
      onSave: ({
        required String title,
        required String kind,
        required int minDuration,
        required String dueDate,
        required bool isImportant,
        required List<String> tags,
        required String repeatInterval,
        required String note,
      }) async {
        if (taskToEdit == null) {
          await tasksRepository.addTask(
            accountId: accountId,
            title: title,
            kind: kind,
            minDuration: minDuration,
            dueDate: dueDate,
            isImportant: isImportant,
            tags: tags,
            repeatInterval: repeatInterval,
            note: note,
          );
        } else {
          final updated = taskToEdit.copyWith(
            title: title,
            kind: kind,
            minDuration: minDuration,
            dueDate: dueDate,
            isImportant: isImportant,
            tags: tags,
            repeatInterval: repeatInterval,
            note: note,
          );
          await tasksRepository.updateTask(updated);
        }
        onSaved?.call();
      },
    );
  }
}

class _TaskSheetContent extends StatefulWidget {
  final MyDayTask? taskToEdit;
  final String defaultDueDate;
  final FutureOr<void> Function({
    required String title,
    required String kind,
    required int minDuration,
    required String dueDate,
    required bool isImportant,
    required List<String> tags,
    required String repeatInterval,
    required String note,
  }) onSave;

  final bool isEvent;

  const _TaskSheetContent({
    this.taskToEdit,
    required this.defaultDueDate,
    this.isEvent = false,
    required this.onSave,
  });

  @override
  State<_TaskSheetContent> createState() => _TaskSheetContentState();
}

class _TaskSheetContentState extends State<_TaskSheetContent> {
  late String _kind;
  late bool _isEvent;
  late TextEditingController _titleController;
  late TextEditingController _durationController;
  late TextEditingController _noteController;
  late String _dueDate;
  late bool _isImportant;
  late List<String> _selectedTags;
  late String _repeatInterval;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final t = widget.taskToEdit;
    _isEvent = widget.isEvent || (t?.tags.contains('event') ?? false);
    _kind = t?.kind ?? 'todo';
    _titleController = TextEditingController(text: t?.title ?? '');
    _durationController =
        TextEditingController(text: (t?.minDuration ?? 25).toString());
    _noteController = TextEditingController(text: t?.note ?? '');
    _dueDate = t?.dueDate ?? widget.defaultDueDate;
    _isImportant = t?.isImportant ?? false;
    _selectedTags = List<String>.from(t?.tags ?? []);
    _repeatInterval = t?.repeatInterval ?? 'none';
  }

  void _onClear() {
    setState(() {
      _titleController.clear();
      _noteController.clear();
      _durationController.text = '25';
      _isImportant = false;
      _selectedTags.clear();
      _repeatInterval = 'none';
      _dueDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _errorMessage = null;
    });
  }

  Future<void> _onSavePressed() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorMessage = 'Give your ${_isEvent ? "event" : "task"} a name');
      return;
    }

    final duration = int.tryParse(_durationController.text) ?? 25;

    final tags = List<String>.from(_selectedTags);
    if (_isEvent && !tags.contains('event')) {
      tags.add('event');
    } else if (!_isEvent && tags.contains('event')) {
      tags.remove('event');
    }

    await widget.onSave(
      title: title,
      kind: _kind,
      minDuration: _kind == 'timed' ? duration : 0,
      dueDate: _dueDate,
      isImportant: _isImportant,
      tags: tags,
      repeatInterval: _repeatInterval,
      note: _noteController.text.trim(),
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildSegmentBtn({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? context.appSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? context.appText : context.appMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Segmented Toggle [To-do | Timed task | Event]
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.appSurface2,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                _buildSegmentBtn(
                  label: 'To-do',
                  isSelected: !_isEvent && _kind == 'todo',
                  onTap: () => setState(() {
                    _kind = 'todo';
                    _isEvent = false;
                  }),
                ),
                _buildSegmentBtn(
                  label: 'Timed',
                  isSelected: !_isEvent && _kind == 'timed',
                  onTap: () => setState(() {
                    _kind = 'timed';
                    _isEvent = false;
                  }),
                ),
                _buildSegmentBtn(
                  label: 'Event',
                  isSelected: _isEvent,
                  onTap: () => setState(() {
                    _kind = 'todo';
                    _isEvent = true;
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Name Input
          TextField(
            controller: _titleController,
            style: TextStyle(color: context.appText),
            decoration: InputDecoration(
              hintText: _isEvent
                  ? 'Event title (e.g. Team Meeting, Doctor, Birthday)'
                  : (_kind == 'timed'
                      ? 'Name (e.g. Code for 3 h)'
                      : 'What needs to be done?'),
              hintStyle: TextStyle(
                color: context.appMuted.withValues(alpha: 0.6),
              ),
              filled: true,
              fillColor: context.appSurface2,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          if (_kind == 'timed') ...[
            const SizedBox(height: 14),
            Text(
              'Duration (minutes)',
              style: AppTypography.captionMuted.copyWith(
                color: context.appMuted,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: context.appText),
              decoration: InputDecoration(
                filled: true,
                fillColor: context.appSurface2,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Date Picker Field
          Text(
            'Date',
            style: AppTypography.captionMuted.copyWith(color: context.appMuted),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.tryParse(_dueDate) ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: AppColors.accent,
                        onPrimary: Colors.white,
                        surface: context.appSurface,
                        onSurface: context.appText,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _dueDate = DateFormat('yyyy-MM-dd').format(picked);
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: context.appSurface2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_dueDate, style: TextStyle(color: context.appText)),
                  Icon(Icons.calendar_today, size: 18, color: context.appMuted),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Mark as Important Switch Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mark as important',
                style: AppTypography.body.copyWith(color: context.appText),
              ),
              Switch(
                value: _isImportant,
                activeThumbColor: AppColors.success,
                activeTrackColor: AppColors.success.withValues(alpha: 0.4),
                inactiveThumbColor: context.appText,
                inactiveTrackColor: context.appSurface2,
                onChanged: (val) => setState(() => _isImportant = val),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Tags Selection
          Text(
            'Tags',
            style: AppTypography.captionMuted.copyWith(color: context.appMuted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppColors.tags.keys.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTags.remove(tag);
                    } else {
                      _selectedTags.add(tag);
                    }
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.appSurface2,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected ? context.appText : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.tags[tag],
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        tag,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.appText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Repeat Selection
          Text(
            'Repeat',
            style: AppTypography.captionMuted.copyWith(color: context.appMuted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildRepeatOption('none', 'Once'),
              _buildRepeatOption('daily', 'Daily'),
              _buildRepeatOption('weekly', 'Weekly'),
            ],
          ),

          const SizedBox(height: 16),

          // Note Field
          Text(
            'Note',
            style: AppTypography.captionMuted.copyWith(color: context.appMuted),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _noteController,
            maxLines: 2,
            style: TextStyle(color: context.appText),
            decoration: InputDecoration(
              hintText: 'Optional',
              hintStyle: TextStyle(
                color: context.appMuted.withValues(alpha: 0.6),
              ),
              filled: true,
              fillColor: context.appSurface2,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],

          const SizedBox(height: 20),

          // Action Buttons: Clear & Save/Add
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.appSurface2,
                    foregroundColor: context.appText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _onClear,
                  child: const Text(
                    'Clear',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.isDarkMode
                        ? AppColors.darkText
                        : AppColors.lightText,
                    foregroundColor: context.isDarkMode
                        ? AppColors.darkBg
                        : AppColors.lightBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _onSavePressed,
                  child: Text(
                    widget.taskToEdit != null
                        ? 'Save'
                        : (_isEvent ? 'Add Event' : 'Add'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatOption(String value, String label) {
    final isSelected = _repeatInterval == value;
    return GestureDetector(
      onTap: () => setState(() => _repeatInterval = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: context.appSurface2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? context.appText : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.appText,
          ),
        ),
      ),
    );
  }
}
