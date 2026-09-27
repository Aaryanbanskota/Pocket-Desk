import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task_model.dart';
import '../providers/tasks_notifier.dart';

class TaskFormSheet extends ConsumerStatefulWidget {
  const TaskFormSheet({super.key, this.task});
  final TaskModel? task;

  static bool get _isDesktop =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  static Future<void> show(BuildContext context, {TaskModel? task}) {
    if (_isDesktop) {
      return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
            child: TaskFormSheet(task: task),
          ),
        ),
      );
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskFormSheet(task: task),
    );
  }

  @override
  ConsumerState<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _listCtrl = TextEditingController();
  final _folderCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _subtaskCtrl = TextEditingController();

  TaskPriority _priority = TaskPriority.none;
  DateTime? _dueDate;
  bool _isRecurring = false;
  String? _recurrenceRule;
  final List<String> _subtasks = [];

  static const _recurrenceOptions = ['DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'];

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    if (t != null) {
      _titleCtrl.text = t.title;
      _descCtrl.text = t.description ?? '';
      _listCtrl.text = t.listName ?? '';
      _folderCtrl.text = t.folderName ?? '';
      _categoryCtrl.text = t.category ?? '';
      _priority = t.priority;
      _dueDate = t.dueDate;
      _isRecurring = t.isRecurring;
      _recurrenceRule = t.recurrenceRule;
      _subtasks.addAll(t.subtaskTitles);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _listCtrl.dispose();
    _folderCtrl.dispose();
    _categoryCtrl.dispose();
    _subtaskCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _addSubtask() {
    final text = _subtaskCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks.add(text);
      _subtaskCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(tasksProvider.notifier);
    await notifier.addOrUpdateTask(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      priority: _priority,
      dueDate: _dueDate,
      category: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
      listName: _listCtrl.text.trim().isEmpty ? null : _listCtrl.text.trim(),
      folderName: _folderCtrl.text.trim().isEmpty ? null : _folderCtrl.text.trim(),
      subtaskTitles: List.from(_subtasks),
      isRecurring: _isRecurring,
      recurrenceRule: _isRecurring ? _recurrenceRule : null,
      taskId: widget.task?.id,
    );
    if (mounted) Navigator.of(context).pop();
  }

  bool get _isDirty {
    if (widget.task == null) {
      return _titleCtrl.text.isNotEmpty ||
          _descCtrl.text.isNotEmpty ||
          _listCtrl.text.isNotEmpty ||
          _folderCtrl.text.isNotEmpty ||
          _categoryCtrl.text.isNotEmpty ||
          _subtasks.isNotEmpty ||
          _dueDate != null;
    }
    final t = widget.task!;
    return _titleCtrl.text != t.title ||
        _descCtrl.text != (t.description ?? '') ||
        _listCtrl.text != (t.listName ?? '') ||
        _folderCtrl.text != (t.folderName ?? '') ||
        _categoryCtrl.text != (t.category ?? '') ||
        _priority != t.priority ||
        _dueDate != t.dueDate ||
        _isRecurring != t.isRecurring ||
        _subtasks.length != t.subtaskTitles.length;
  }

  Future<bool> _confirmLeave() async {
    if (!_isDirty) return true;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDesktop = TaskFormSheet._isDesktop;

    // On desktop we render directly as a Column inside the Dialog.
    // On mobile we use a DraggableScrollableSheet.
    if (isDesktop) {
      return PopScope(
        canPop: !_isDirty,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await _confirmLeave();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(
                    widget.task == null ? 'New Task' : 'Edit Task',
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () async {
                      if (await _confirmLeave() && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: _buildFormFields(cs, tt),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _confirmLeave();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      widget.task == null ? 'New Task' : 'Edit Task',
                      style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        if (await _confirmLeave() && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    FilledButton(
                      onPressed: _submit,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollCtrl,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    children: _buildFormFields(cs, tt),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shared list of form field widgets used by both desktop and mobile builds.
  List<Widget> _buildFormFields(ColorScheme cs, TextTheme tt) {
    return [
      // Title
      TextFormField(
        controller: _titleCtrl,
        autofocus: widget.task == null,
        decoration: const InputDecoration(
          labelText: 'Task title *',
          prefixIcon: Icon(Icons.task_alt_outlined),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
      const SizedBox(height: 12),
      // Description
      TextFormField(
        controller: _descCtrl,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Description',
          prefixIcon: Icon(Icons.notes_outlined),
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 16),
      // Priority chips
      Text('Priority', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: TaskPriority.values.map((p) {
          final selected = _priority == p;
          return ChoiceChip(
            label: Text(_priorityLabel(p)),
            selected: selected,
            selectedColor: _priorityColor(p).withOpacity(0.2),
            side: BorderSide(
              color: selected ? _priorityColor(p) : cs.outline,
            ),
            labelStyle: TextStyle(
              color: selected ? _priorityColor(p) : cs.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : null,
            ),
            onSelected: (_) => setState(() => _priority = p),
          );
        }).toList(),
      ),
      const SizedBox(height: 16),
      // Due date
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.calendar_today_outlined, color: cs.primary),
        title: Text(_dueDate == null
            ? 'No due date'
            : 'Due: ${_dueDate!.toLocal().toString().split(' ')[0]}'),
        trailing: _dueDate != null
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _dueDate = null),
              )
            : null,
        onTap: _pickDate,
      ),
      const SizedBox(height: 8),
      // List / Folder / Category
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _listCtrl,
              decoration: const InputDecoration(
                labelText: 'List',
                prefixIcon: Icon(Icons.list_outlined),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _folderCtrl,
              decoration: const InputDecoration(
                labelText: 'Folder',
                prefixIcon: Icon(Icons.folder_outlined),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _categoryCtrl,
        decoration: const InputDecoration(
          labelText: 'Category',
          prefixIcon: Icon(Icons.label_outline),
        ),
      ),
      const SizedBox(height: 16),
      // Recurring
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Recurring Task'),
        secondary: Icon(Icons.repeat, color: cs.primary),
        value: _isRecurring,
        onChanged: (v) => setState(() => _isRecurring = v),
      ),
      if (_isRecurring) ...[
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _recurrenceRule,
          decoration: const InputDecoration(labelText: 'Repeat'),
          items: _recurrenceOptions
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: (v) => setState(() => _recurrenceRule = v),
        ),
      ],
      const SizedBox(height: 16),
      // Subtasks
      Text('Subtasks', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
      const SizedBox(height: 8),
      ..._subtasks.asMap().entries.map((e) => ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.radio_button_unchecked, size: 18),
            title: Text(e.value),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _subtasks.removeAt(e.key)),
            ),
          )),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _subtaskCtrl,
              decoration: const InputDecoration(
                hintText: 'Add subtask…',
                prefixIcon: Icon(Icons.add, size: 18),
              ),
              onFieldSubmitted: (_) => _addSubtask(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _addSubtask,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      const SizedBox(height: 24),
      if (widget.task != null) ...[
        FilledButton.tonal(
          onPressed: () async {
            final title = widget.task!.title;
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);
            await ref.read(tasksProvider.notifier).deleteTask(widget.task!.id);
            if (context.mounted) {
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(content: Text('Deleted "$title"')),
              );
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: cs.errorContainer,
            foregroundColor: cs.onErrorContainer,
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text('Delete Task'),
        ),
      ],
    ];
  }

  String _priorityLabel(TaskPriority p) => switch (p) {
        TaskPriority.none => 'None',
        TaskPriority.low => 'Low',
        TaskPriority.medium => 'Medium',
        TaskPriority.high => 'High',
        TaskPriority.urgent => 'Urgent',
      };

  Color _priorityColor(TaskPriority p) => switch (p) {
        TaskPriority.none => Colors.grey,
        TaskPriority.low => Colors.blue,
        TaskPriority.medium => Colors.orange,
        TaskPriority.high => Colors.red,
        TaskPriority.urgent => Colors.purple,
      };
}
