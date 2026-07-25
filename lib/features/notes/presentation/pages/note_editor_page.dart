import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/note_model.dart';
import '../providers/notes_notifier.dart';

/// Full-screen note editor (create & edit).
class NoteEditorPage extends ConsumerStatefulWidget {
  const NoteEditorPage({super.key, this.note});
  final NoteModel? note;

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _folderCtrl = TextEditingController();
  final _checkItemCtrl = TextEditingController();

  bool _isPinned = false;
  bool _isFavorite = false;
  bool _hasChecklist = false;
  List<String> _tags = [];
  List<String> _checkItems = [];
  List<bool> _checkDone = [];
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final n = widget.note;
    if (n != null) {
      _titleCtrl.text = n.title;
      _contentCtrl.text = n.content;
      _folderCtrl.text = n.folderName ?? '';
      _isPinned = n.isPinned;
      _isFavorite = n.isFavorite;
      _hasChecklist = n.hasChecklist;
      _tags = List.from(n.tags);
      _checkItems = List.from(n.checklistItems);
      _checkDone = List.from(n.checklistDone);
    }
    _titleCtrl.addListener(() => setState(() => _dirty = true));
    _contentCtrl.addListener(() => setState(() => _dirty = true));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagCtrl.dispose();
    _folderCtrl.dispose();
    _checkItemCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }
    await ref.read(notesProvider.notifier).saveNote(
          title: title,
          content: _contentCtrl.text,
          folderName: _folderCtrl.text.trim().isEmpty ? null : _folderCtrl.text.trim(),
          tags: _tags,
          isPinned: _isPinned,
          isFavorite: _isFavorite,
          hasChecklist: _hasChecklist,
          checklistItems: _checkItems,
          checklistDone: _checkDone,
          noteId: widget.note?.id,
        );
    if (mounted) Navigator.of(context).pop();
  }

  void _addTag() {
    final t = _tagCtrl.text.trim();
    if (t.isEmpty || _tags.contains(t)) return;
    setState(() { _tags.add(t); _tagCtrl.clear(); _dirty = true; });
  }

  void _addCheckItem() {
    final t = _checkItemCtrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _checkItems.add(t);
      _checkDone.add(false);
      _checkItemCtrl.clear();
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        title: Text(
          widget.note == null ? 'New Note' : 'Edit Note',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: _isPinned ? cs.primary : null),
            onPressed: () => setState(() { _isPinned = !_isPinned; _dirty = true; }),
            tooltip: 'Pin',
          ),
          IconButton(
            icon: Icon(_isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: _isFavorite ? Colors.amber : null),
            onPressed: () => setState(() { _isFavorite = !_isFavorite; _dirty = true; }),
            tooltip: 'Favorite',
          ),
          FilledButton(
            onPressed: _dirty ? _save : null,
            child: const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // Title
          TextField(
            controller: _titleCtrl,
            autofocus: widget.note == null,
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Title',
              hintStyle: tt.headlineSmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                fontWeight: FontWeight.bold,
              ),
              border: InputBorder.none,
            ),
          ),
          // Folder
          TextField(
            controller: _folderCtrl,
            style: tt.bodySmall?.copyWith(color: cs.primary),
            decoration: InputDecoration(
              hintText: 'Folder (optional)',
              hintStyle: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
              prefixIcon: Icon(Icons.folder_outlined, size: 16, color: cs.primary),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
          const Divider(height: 24),

          // Checklist toggle
          Row(
            children: [
              FilterChip(
                label: const Text('Checklist'),
                selected: _hasChecklist,
                onSelected: (v) => setState(() { _hasChecklist = v; _dirty = true; }),
                avatar: Icon(
                  _hasChecklist ? Icons.check_box_outlined : Icons.check_box_outline_blank,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Content or Checklist
          if (_hasChecklist) ...[
            ..._checkItems.asMap().entries.map((e) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _checkDone[e.key],
                  onChanged: (v) => setState(() {
                    _checkDone[e.key] = v ?? false;
                    _dirty = true;
                  }),
                  title: Text(
                    e.value,
                    style: TextStyle(
                      decoration: _checkDone[e.key] ? TextDecoration.lineThrough : null,
                      color: _checkDone[e.key] ? cs.onSurfaceVariant : cs.onSurface,
                    ),
                  ),
                  secondary: IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() {
                      _checkItems.removeAt(e.key);
                      _checkDone.removeAt(e.key);
                      _dirty = true;
                    }),
                  ),
                )),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _checkItemCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Add item…',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.add, size: 18),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addCheckItem(),
                  ),
                ),
                IconButton(onPressed: _addCheckItem, icon: const Icon(Icons.add_circle_outline)),
              ],
            ),
          ] else
            TextField(
              controller: _contentCtrl,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: tt.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Start writing… (Markdown supported)',
                hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                border: InputBorder.none,
              ),
            ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Tags
          Text('Tags', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              ..._tags.map((tag) => Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() { _tags.remove(tag); _dirty = true; }),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Add tag…',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.label_outline, size: 16),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              IconButton(onPressed: _addTag, icon: const Icon(Icons.add_circle_outline)),
            ],
          ),
        ],
      ),
    );
  }
}
