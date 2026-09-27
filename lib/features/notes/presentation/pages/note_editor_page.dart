import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketdesk/features/auth/presentation/providers/auth_notifier.dart';
import '../../data/models/note_model.dart';
import '../providers/notes_notifier.dart';
import '../../../settings/presentation/providers/ai_settings_notifier.dart';

/// Full-screen note editor (create & edit) with rich formatting toolbar and media support.
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
  final _contentFocusNode = FocusNode();

  bool _isPinned = false;
  bool _isFavorite = false;
  bool _hasChecklist = false;
  List<String> _tags = [];
  List<String> _checkItems = [];
  List<bool> _checkDone = [];
  List<String> _imagePaths = [];
  bool _dirty = false;
  bool _aiFormatting = false;

  Future<void> _runAIAssistant() async {
    final text = _contentCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write some content first for AI to format/summarize')),
      );
      return;
    }

    final auth = ref.read(authNotifierProvider).valueOrNull;
    final userId = auth is AuthAuthenticated ? auth.user.id : 0;
    final aiSettings = await ref.read(aiSettingsRepositoryProvider.future).then((r) => r.getOrCreateSettings(userId));

    if (!mounted) return;

    if (!aiSettings.isEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pocketdesk AI is turned OFF in Settings → AI.')),
      );
      return;
    }
    if (aiSettings.apiKey.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key missing! Add your OpenRouter key in Settings → AI.')),
      );
      return;
    }
    if (!aiSettings.allowNotesAccess || !aiSettings.noteAssistanceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI Note Assistance is disabled in Settings → AI permissions.')),
      );
      return;
    }

    setState(() => _aiFormatting = true);
    final prompt = 'Format and improve the following note content in clean Markdown syntax:\n\n$text';
    const systemPrompt = 'You are Pocketdesk AI assisting with note formatting and structure. Return only the clean formatted markdown content without commentary.';

    final res = await ref.read(aiSettingsProvider.notifier).generateCompletion(
      prompt: prompt,
      systemPrompt: systemPrompt,
    );

    setState(() => _aiFormatting = false);
    if (res != null && res.isNotEmpty) {
      setState(() {
        _contentCtrl.text = res;
        _dirty = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI formatted your note content!')),
        );
      }
    }
  }

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
      _imagePaths = List.from(n.imagePaths);
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
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _insertMarkdownPrefix(String prefix, {String suffix = ''}) {
    final text = _contentCtrl.text;
    final selection = _contentCtrl.selection;
    if (!selection.isValid) {
      _contentCtrl.text = '$text$prefix$suffix';
      _contentCtrl.selection = TextSelection.collapsed(offset: _contentCtrl.text.length - suffix.length);
    } else {
      final selectedText = selection.textInside(text);
      final newText = text.replaceRange(selection.start, selection.end, '$prefix$selectedText$suffix');
      _contentCtrl.text = newText;
      _contentCtrl.selection = TextSelection.collapsed(offset: selection.start + prefix.length + selectedText.length);
    }
    setState(() => _dirty = true);
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true);
    if (result != null && result.paths.isNotEmpty) {
      setState(() {
        for (final p in result.paths) {
          if (p != null && !_imagePaths.contains(p)) {
            _imagePaths.add(p);
          }
        }
        _dirty = true;
      });
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim().isEmpty ? 'Untitled Note' : _titleCtrl.text.trim();
    final isEditing = widget.note != null;
    final messenger = ScaffoldMessenger.of(context);

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
          imagePaths: _imagePaths,
          noteId: widget.note?.id,
        );

    setState(() => _dirty = false);
    if (mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(isEditing ? 'Note updated successfully!' : 'Note created successfully!')),
      );
      Navigator.of(context).pop();
    }
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

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes in your note. Are you sure you want to leave?'),
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

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _confirmLeave();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _confirmLeave() && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            widget.note == null ? 'New Note' : 'Edit Note',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: _aiFormatting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome_rounded),
              onPressed: _aiFormatting ? null : _runAIAssistant,
              tooltip: 'AI Format Assistant',
            ),
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
            if (widget.note != null)
              IconButton(
                icon: const Icon(Icons.copy_rounded),
                onPressed: () async {
                  await ref.read(notesProvider.notifier).duplicateNote(widget.note!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Note duplicated successfully!')),
                    );
                    Navigator.of(context).pop();
                  }
                },
                tooltip: 'Duplicate Note',
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Formatting Toolbar
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4))),
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  IconButton(
                    icon: const Icon(Icons.format_bold_rounded, size: 20),
                    onPressed: () => _insertMarkdownPrefix('**', suffix: '**'),
                    tooltip: 'Bold',
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_italic_rounded, size: 20),
                    onPressed: () => _insertMarkdownPrefix('*', suffix: '*'),
                    tooltip: 'Italic',
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_underlined_rounded, size: 20),
                    onPressed: () => _insertMarkdownPrefix('<u>', suffix: '</u>'),
                    tooltip: 'Underline',
                  ),
                  IconButton(
                    icon: const Icon(Icons.strikethrough_s_rounded, size: 20),
                    onPressed: () => _insertMarkdownPrefix('~~', suffix: '~~'),
                    tooltip: 'Strikethrough',
                  ),
                  const VerticalDivider(indent: 8, endIndent: 8),
                  IconButton(
                    icon: const Icon(Icons.title_rounded, size: 20),
                    onPressed: () => _insertMarkdownPrefix('# '),
                    tooltip: 'Heading 1',
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_list_bulleted_rounded, size: 20),
                    onPressed: () => _insertMarkdownPrefix('- '),
                    tooltip: 'Bullet List',
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_list_numbered_rounded, size: 20),
                    onPressed: () => _insertMarkdownPrefix('1. '),
                    tooltip: 'Numbered List',
                  ),
                  IconButton(
                    icon: const Icon(Icons.code_rounded, size: 20),
                    onPressed: () => _insertMarkdownPrefix('```\n', suffix: '\n```'),
                    tooltip: 'Code Block',
                  ),
                  const VerticalDivider(indent: 8, endIndent: 8),
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
                    onPressed: _pickImage,
                    tooltip: 'Attach Image',
                  ),
                  IconButton(
                    icon: Icon(
                      _hasChecklist ? Icons.checklist_rtl_rounded : Icons.playlist_add_check_rounded,
                      size: 20,
                      color: _hasChecklist ? cs.primary : null,
                    ),
                    onPressed: () => setState(() { _hasChecklist = !_hasChecklist; _dirty = true; }),
                    tooltip: 'Toggle Checklist Mode',
                  ),
                ],
              ),
            ),

            // Note Content Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  // Title Input
                  TextField(
                    controller: _titleCtrl,
                    autofocus: widget.note == null,
                    style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'Note Title',
                      hintStyle: tt.headlineSmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                        fontWeight: FontWeight.bold,
                      ),
                      border: InputBorder.none,
                    ),
                  ),

                  // Folder & Tag metadata bar
                  Row(
                    children: [
                      Icon(Icons.folder_outlined, size: 16, color: cs.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _folderCtrl,
                          style: tt.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'Folder (e.g. Work, Ideas)',
                            hintStyle: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Attached Images Row
                  if (_imagePaths.isNotEmpty) ...[
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imagePaths.length,
                        itemBuilder: (ctx, i) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(_imagePaths[i]),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _imagePaths.removeAt(i);
                                    _dirty = true;
                                  }),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Checklist Mode or Markdown Content Editor
                  if (_hasChecklist) ...[
                    Text('Checklist Items', style: tt.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
                    const SizedBox(height: 8),
                    ..._checkItems.asMap().entries.map((e) => Card(
                      elevation: 0,
                      color: cs.surfaceContainerLow,
                      margin: const EdgeInsets.only(bottom: 6),
                      child: CheckboxListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
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
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => setState(() {
                            _checkItems.removeAt(e.key);
                            _checkDone.removeAt(e.key);
                            _dirty = true;
                          }),
                        ),
                      ),
                    )),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _checkItemCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Add checklist item…',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              isDense: true,
                            ),
                            onSubmitted: (_) => _addCheckItem(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _addCheckItem,
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                  ] else
                    TextField(
                      controller: _contentCtrl,
                      focusNode: _contentFocusNode,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: tt.bodyMedium?.copyWith(height: 1.5),
                      decoration: InputDecoration(
                        hintText: 'Start writing your note…\n\nSupports Markdown formatting:\n• # Heading\n• **Bold**, *Italic*, ~~Strikethrough~~\n• - Bullet list\n• ```code block```',
                        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                        border: InputBorder.none,
                      ),
                    ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Tags Section
                  Text('Tags', style: tt.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ..._tags.map((tag) => Chip(
                            label: Text(tag, style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close_rounded, size: 14),
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
                            hintText: 'Add tag (e.g. urgent, idea)…',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.local_offer_outlined, size: 18),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _addTag(),
                        ),
                      ),
                      IconButton(onPressed: _addTag, icon: const Icon(Icons.add_circle_outline_rounded)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
