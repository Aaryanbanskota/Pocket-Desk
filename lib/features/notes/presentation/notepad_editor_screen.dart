import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:file_picker/file_picker.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/app_bottom_sheet.dart';
import '../../../core/design_system/widgets/circular_icon_button.dart';
import '../../../core/design_system/widgets/undo_toast.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/services/speech_to_text_service.dart';
import '../data/notes_repository.dart';

enum NotePaperStyle {
  plain,
  lined,
  grid,
  book,
}

class NoteColorTheme {
  final String name;
  final Color darkBg;
  final Color lightBg;
  final Color darkText;
  final Color lightText;
  final Color previewColor;

  const NoteColorTheme({
    required this.name,
    required this.darkBg,
    required this.lightBg,
    required this.darkText,
    required this.lightText,
    required this.previewColor,
  });
}

const List<NoteColorTheme> noteColorThemes = [
  NoteColorTheme(
    name: 'Default',
    darkBg: Color(0xFF141518),
    lightBg: Color(0xFFF9FAFB),
    darkText: Color(0xFFF3F4F6),
    lightText: Color(0xFF111827),
    previewColor: Color(0xFF4B5563),
  ),
  NoteColorTheme(
    name: 'Warm Cream',
    darkBg: Color(0xFF221F1B),
    lightBg: Color(0xFFFAF6EE),
    darkText: Color(0xFFFAF0E6),
    lightText: Color(0xFF2C241B),
    previewColor: Color(0xFFD4A373),
  ),
  NoteColorTheme(
    name: 'Midnight Navy',
    darkBg: Color(0xFF161E2E),
    lightBg: Color(0xFFEEF4FF),
    darkText: Color(0xFFF0F6FF),
    lightText: Color(0xFF1E293B),
    previewColor: Color(0xFF3B82F6),
  ),
  NoteColorTheme(
    name: 'Lavender Purple',
    darkBg: Color(0xFF22182E),
    lightBg: Color(0xFFF8F0FF),
    darkText: Color(0xFFFAF0FF),
    lightText: Color(0xFF331B4D),
    previewColor: Color(0xFF8B5CF6),
  ),
  NoteColorTheme(
    name: 'Sage Forest',
    darkBg: Color(0xFF14241C),
    lightBg: Color(0xFFEFF8F3),
    darkText: Color(0xFFE8F7EE),
    lightText: Color(0xFF133824),
    previewColor: Color(0xFF10B981),
  ),
];

/// Custom text editing controller that formats standard document elements
/// (Headings, Bold, Italic, Underline, Strikethrough, Checklists) directly inline
/// without exposing raw markdown markers to the user.
class RichDocumentEditingController extends TextEditingController {
  double baseFontSize;
  NotePaperStyle paperStyle;
  Color textColor;
  Color accentColor;
  Color mutedColor;

  RichDocumentEditingController({
    super.text,
    this.baseFontSize = 16.5,
    this.paperStyle = NotePaperStyle.plain,
    required this.textColor,
    required this.accentColor,
    required this.mutedColor,
  });

  void updateTheme({
    required Color textColor,
    required Color accentColor,
    required Color mutedColor,
    required double baseFontSize,
    required NotePaperStyle paperStyle,
  }) {
    this.textColor = textColor;
    this.accentColor = accentColor;
    this.mutedColor = mutedColor;
    this.baseFontSize = baseFontSize;
    this.paperStyle = paperStyle;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final isBook = paperStyle == NotePaperStyle.book;
    final effectiveStyle = (style ?? const TextStyle()).copyWith(
      fontSize: baseFontSize,
      color: textColor,
      fontFamily: isBook ? 'Georgia' : null,
      height: 1.6,
    );

    final lines = text.split('\n');
    final spans = <InlineSpan>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      _parseLine(line, effectiveStyle, spans);

      if (i < lines.length - 1) {
        spans.add(TextSpan(text: '\n', style: effectiveStyle));
      }
    }

    return TextSpan(children: spans, style: effectiveStyle);
  }

  void _parseLine(String line, TextStyle defaultStyle, List<InlineSpan> spans) {
    TextStyle lineStyle = defaultStyle;
    String content = line;

    // Line-level heading / list styles
    if (content.startsWith('# ')) {
      spans.add(const TextSpan(
        text: '# ',
        style: TextStyle(fontSize: 0.01, color: Colors.transparent),
      ));
      content = content.substring(2);
      lineStyle = defaultStyle.copyWith(
        fontSize: baseFontSize + 8,
        fontWeight: FontWeight.w800,
        height: 1.3,
      );
    } else if (content.startsWith('## ')) {
      spans.add(const TextSpan(
        text: '## ',
        style: TextStyle(fontSize: 0.01, color: Colors.transparent),
      ));
      content = content.substring(3);
      lineStyle = defaultStyle.copyWith(
        fontSize: baseFontSize + 4,
        fontWeight: FontWeight.w700,
        height: 1.35,
      );
    } else if (content.startsWith('### ')) {
      spans.add(const TextSpan(
        text: '### ',
        style: TextStyle(fontSize: 0.01, color: Colors.transparent),
      ));
      content = content.substring(4);
      lineStyle = defaultStyle.copyWith(
        fontSize: baseFontSize + 2,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );
    } else if (content.startsWith('- [ ] ')) {
      spans.add(const TextSpan(
        text: '- ',
        style: TextStyle(fontSize: 0.01, color: Colors.transparent),
      ));
      spans.add(TextSpan(
        text: '[ ] ',
        style: defaultStyle.copyWith(
          color: accentColor,
          fontWeight: FontWeight.w800,
        ),
      ));
      content = content.substring(6);
    } else if (content.startsWith('- [x] ')) {
      spans.add(const TextSpan(
        text: '- ',
        style: TextStyle(fontSize: 0.01, color: Colors.transparent),
      ));
      spans.add(TextSpan(
        text: '[x] ',
        style: defaultStyle.copyWith(
          color: Colors.green,
          fontWeight: FontWeight.w800,
        ),
      ));
      content = content.substring(6);
      lineStyle = defaultStyle.copyWith(
        decoration: TextDecoration.lineThrough,
        color: mutedColor,
      );
    } else if (content.startsWith('> ')) {
      spans.add(TextSpan(
        text: '> ',
        style: defaultStyle.copyWith(
          color: accentColor,
          fontWeight: FontWeight.bold,
        ),
      ));
      content = content.substring(2);
      lineStyle = defaultStyle.copyWith(
        fontStyle: FontStyle.italic,
        color: textColor.withValues(alpha: 0.85),
      );
    } else if (content.startsWith('• ')) {
      spans.add(TextSpan(
        text: '• ',
        style: defaultStyle.copyWith(
          color: accentColor,
          fontWeight: FontWeight.bold,
        ),
      ));
      content = content.substring(2);
    } else {
      final numMatch = RegExp(r'^\d+\.\s+').firstMatch(content);
      if (numMatch != null) {
        final prefixText = content.substring(0, numMatch.end);
        spans.add(TextSpan(
          text: prefixText,
          style: defaultStyle.copyWith(
            color: accentColor,
            fontWeight: FontWeight.w700,
          ),
        ));
        content = content.substring(numMatch.end);
      }
    }

    _parseInlineFormatted(content, lineStyle, spans);
  }

  void _parseInlineFormatted(String text, TextStyle currentStyle, List<InlineSpan> spans) {
    if (text.isEmpty) return;

    // Pattern for **bold**, __underline__, ~~strike~~, *italic*
    final regex = RegExp(r'(\*\*(.*?)\*\*)|(__(.*?)__)|(~~(.*?)~~)|(\*(.*?)\*)');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: currentStyle,
        ));
      }

      if (match.group(1) != null) {
        // **bold**
        spans.add(const TextSpan(text: '**', style: TextStyle(fontSize: 0.01, color: Colors.transparent)));
        spans.add(TextSpan(
          text: match.group(2) ?? '',
          style: currentStyle.copyWith(fontWeight: FontWeight.bold),
        ));
        spans.add(const TextSpan(text: '**', style: TextStyle(fontSize: 0.01, color: Colors.transparent)));
      } else if (match.group(3) != null) {
        // __underline__
        spans.add(const TextSpan(text: '__', style: TextStyle(fontSize: 0.01, color: Colors.transparent)));
        spans.add(TextSpan(
          text: match.group(4) ?? '',
          style: currentStyle.copyWith(decoration: TextDecoration.underline),
        ));
        spans.add(const TextSpan(text: '__', style: TextStyle(fontSize: 0.01, color: Colors.transparent)));
      } else if (match.group(5) != null) {
        // ~~strike~~
        spans.add(const TextSpan(text: '~~', style: TextStyle(fontSize: 0.01, color: Colors.transparent)));
        spans.add(TextSpan(
          text: match.group(6) ?? '',
          style: currentStyle.copyWith(decoration: TextDecoration.lineThrough),
        ));
        spans.add(const TextSpan(text: '~~', style: TextStyle(fontSize: 0.01, color: Colors.transparent)));
      } else if (match.group(7) != null) {
        // *italic*
        spans.add(const TextSpan(text: '*', style: TextStyle(fontSize: 0.01, color: Colors.transparent)));
        spans.add(TextSpan(
          text: match.group(8) ?? '',
          style: currentStyle.copyWith(fontStyle: FontStyle.italic),
        ));
        spans.add(const TextSpan(text: '*', style: TextStyle(fontSize: 0.01, color: Colors.transparent)));
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: currentStyle,
      ));
    }
  }
}

/// Paper background painter for Ruled Notebook, Grid, and Book Reader modes
class PaperBackgroundPainter extends CustomPainter {
  final NotePaperStyle style;
  final Color lineColor;
  final double lineHeight;

  PaperBackgroundPainter({
    required this.style,
    required this.lineColor,
    this.lineHeight = 28.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (style == NotePaperStyle.plain) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    if (style == NotePaperStyle.lined) {
      for (double y = lineHeight; y < size.height; y += lineHeight) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else if (style == NotePaperStyle.grid) {
      const step = 24.0;
      for (double x = 0; x < size.width; x += step) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y < size.height; y += step) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else if (style == NotePaperStyle.book) {
      final marginPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.7)
        ..strokeWidth = 1.2;
      canvas.drawLine(const Offset(24, 0), Offset(24, size.height), marginPaint);
      canvas.drawLine(const Offset(27, 0), Offset(27, size.height), marginPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PaperBackgroundPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.lineHeight != lineHeight;
  }
}

class NotepadEditorScreen extends StatefulWidget {
  final MyDayNote note;
  final FutureOr<dynamic> Function(MyDayNote) onSaveNote;
  final void Function(MyDayNote) onDeleteNote;
  final VoidCallback onBack;

  const NotepadEditorScreen({
    super.key,
    required this.note,
    required this.onSaveNote,
    required this.onDeleteNote,
    required this.onBack,
  });

  static Future<void> open(
    BuildContext context, {
    required NotesRepository notesRepository,
    required String accountId,
    MyDayNote? note,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final noteToEdit = note ??
        MyDayNote(
          id: '',
          accountId: accountId,
          title: '',
          body: '',
          isPinned: false,
          colorIndex: 0,
          createdAt: nowMs,
          updatedAt: nowMs,
        );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => NotepadEditorScreen(
          note: noteToEdit,
          onSaveNote: (saved) async {
            if (saved.id.isEmpty) {
              if (saved.title.trim().isNotEmpty || saved.body.trim().isNotEmpty) {
                final created = await notesRepository.createNote(
                  accountId: accountId,
                  title: saved.title,
                  body: saved.body,
                  isPinned: saved.isPinned,
                  colorIndex: saved.colorIndex,
                );
                return created.id;
              }
              return '';
            } else {
              await notesRepository.updateNote(saved);
              return saved.id;
            }
          },
          onDeleteNote: (toDelete) async {
            if (toDelete.id.isNotEmpty) {
              await notesRepository.deleteNote(toDelete.id);
            }
          },
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  State<NotepadEditorScreen> createState() => _NotepadEditorScreenState();
}

class _NotepadEditorScreenState extends State<NotepadEditorScreen> {
  late String _noteId;
  late TextEditingController _titleController;
  late RichDocumentEditingController _bodyController;
  late FocusNode _titleFocusNode;
  late FocusNode _bodyFocusNode;

  late bool _isPinned;
  late int _colorIndex;
  NotePaperStyle _paperStyle = NotePaperStyle.plain;
  double _baseFontSize = 16.5;

  // Attached Voice Memos (saved audio files)
  final List<String> _attachedVoiceNotes = [];
  String? _currentlyPlayingAudio;
  Process? _sysAudioProcess;
  Timer? _audioPlaybackTimer;
  int _audioPlayProgressSec = 0;

  // Attached Tags and Photos (Pocketdesk Notepad features)
  final List<String> _tags = [];
  final List<String> _attachedImages = [];

  // Silent Auto-save
  Timer? _debounceTimer;
  int _lastSavedAt = 0;

  // Find & Replace
  bool _showFindBar = false;
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  final bool _caseSensitive = false;
  int _currentMatchIndex = 0;
  List<int> _matches = [];

  // Undo / Redo history
  final List<String> _undoStack = [];
  int _undoIndex = 0;
  bool _isUndoRedoAction = false;

  // Metrics
  int _wordsCount = 0;
  int _charsCount = 0;
  int _readingTimeMin = 1;

  @override
  void initState() {
    super.initState();
    _noteId = widget.note.id;
    _lastSavedAt = widget.note.updatedAt > 0
        ? widget.note.updatedAt
        : DateTime.now().millisecondsSinceEpoch;

    _titleController = TextEditingController(text: widget.note.title);

    // Extract attached voice memos and paper style from note body
    String initialBody = widget.note.body;
    final voiceNoteMatches = RegExp(r'\[Voice Memo:\s*(.*?)\]').allMatches(initialBody);
    for (final match in voiceNoteMatches) {
      final p = match.group(1)?.trim();
      if (p != null && p.isNotEmpty) {
        _attachedVoiceNotes.add(p);
      }
    }
    initialBody = initialBody.replaceAll(RegExp(r'\[Voice Memo:\s*.*?\]'), '').trim();

    // Extract tags
    final tagsMatch = RegExp(r'<!--\s*tags:\s*(.*?)\s*-->').firstMatch(initialBody);
    if (tagsMatch != null) {
      final tagsRaw = tagsMatch.group(1)?.trim() ?? '';
      if (tagsRaw.isNotEmpty) {
        _tags.addAll(tagsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
      }
      initialBody = initialBody.replaceAll(RegExp(r'<!--\s*tags:\s*.*?\s*-->'), '').trim();
    }

    // Extract attached images
    final imagesMatch = RegExp(r'<!--\s*images:\s*(.*?)\s*-->').firstMatch(initialBody);
    if (imagesMatch != null) {
      final imagesRaw = imagesMatch.group(1)?.trim() ?? '';
      if (imagesRaw.isNotEmpty) {
        _attachedImages.addAll(imagesRaw.split('||').map((e) => e.trim()).where((e) => e.isNotEmpty));
      }
      initialBody = initialBody.replaceAll(RegExp(r'<!--\s*images:\s*.*?\s*-->'), '').trim();
    }

    if (initialBody.contains('<!-- style:lined -->')) {
      _paperStyle = NotePaperStyle.lined;
      initialBody = initialBody.replaceAll('<!-- style:lined -->', '').trim();
    } else if (initialBody.contains('<!-- style:grid -->')) {
      _paperStyle = NotePaperStyle.grid;
      initialBody = initialBody.replaceAll('<!-- style:grid -->', '').trim();
    } else if (initialBody.contains('<!-- style:book -->')) {
      _paperStyle = NotePaperStyle.book;
      initialBody = initialBody.replaceAll('<!-- style:book -->', '').trim();
    }

    final theme = noteColorThemes[widget.note.colorIndex.clamp(0, noteColorThemes.length - 1)];
    _bodyController = RichDocumentEditingController(
      text: initialBody,
      baseFontSize: _baseFontSize,
      paperStyle: _paperStyle,
      textColor: theme.lightText,
      accentColor: AppColors.accent,
      mutedColor: theme.lightText.withValues(alpha: 0.6),
    );

    _titleFocusNode = FocusNode();
    _bodyFocusNode = FocusNode();

    _isPinned = widget.note.isPinned;
    _colorIndex = widget.note.colorIndex.clamp(0, noteColorThemes.length - 1);

    _undoStack.add(initialBody);
    _calculateMetrics();

    _bodyController.addListener(_onBodyChanged);
    _titleController.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _audioPlaybackTimer?.cancel();
    _sysAudioProcess?.kill();
    _bodyController.removeListener(_onBodyChanged);
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _bodyController.dispose();
    _titleFocusNode.dispose();
    _bodyFocusNode.dispose();
    _findController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  void _calculateMetrics() {
    final text = _bodyController.text;
    _charsCount = text.length;
    final matches = RegExp(r'\S+').allMatches(text);
    _wordsCount = matches.length;
    _readingTimeMin = (_wordsCount / 200).ceil().clamp(1, 99);
  }

  void _onBodyChanged() {
    if (!_isUndoRedoAction) {
      final text = _bodyController.text;
      if (_undoIndex >= 0 &&
          _undoIndex < _undoStack.length &&
          _undoStack[_undoIndex] != text) {
        if (_undoIndex < _undoStack.length - 1) {
          _undoStack.removeRange(_undoIndex + 1, _undoStack.length);
        }
        _undoStack.add(text);
        if (_undoStack.length > 50) {
          _undoStack.removeAt(0);
        }
        _undoIndex = _undoStack.length - 1;
      }
    }

    _calculateMetrics();
    _scheduleSilentAutoSave();
    if (_showFindBar && _findController.text.isNotEmpty) {
      _updateFindMatches();
    }
  }

  void _onTitleChanged() {
    _scheduleSilentAutoSave();
  }

  void _scheduleSilentAutoSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () async {
      await _persistNoteSilently();
    });
  }

  String _compileFullBody() {
    String text = _bodyController.text;
    if (_paperStyle != NotePaperStyle.plain) {
      text = '$text\n<!-- style:${_paperStyle.name} -->';
    }
    if (_tags.isNotEmpty) {
      text = '$text\n<!-- tags:${_tags.join(',')} -->';
    }
    if (_attachedImages.isNotEmpty) {
      text = '$text\n<!-- images:${_attachedImages.join('||')} -->';
    }
    for (final v in _attachedVoiceNotes) {
      text = '$text\n[Voice Memo: $v]';
    }
    return text.trim();
  }

  Future<void> _persistNoteSilently() async {
    final title = _titleController.text.trim();
    final compiledBody = _compileFullBody();

    // Don't save completely blank new note
    if (title.isEmpty && compiledBody.trim().isEmpty && _noteId.isEmpty) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = widget.note.copyWith(
      id: _noteId,
      title: _titleController.text,
      body: compiledBody,
      isPinned: _isPinned,
      colorIndex: _colorIndex,
      updatedAt: now,
    );

    final result = await widget.onSaveNote(updated);
    if (mounted) {
      setState(() {
        if (result is String && result.isNotEmpty) {
          _noteId = result;
        }
        _lastSavedAt = now;
      });
    }
  }

  Future<void> _saveAndClose() async {
    _debounceTimer?.cancel();
    final title = _titleController.text.trim();
    final compiledBody = _compileFullBody();

    if (title.isNotEmpty || compiledBody.trim().isNotEmpty || _noteId.isNotEmpty) {
      final updated = widget.note.copyWith(
        id: _noteId,
        title: _titleController.text,
        body: compiledBody,
        isPinned: _isPinned,
        colorIndex: _colorIndex,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await widget.onSaveNote(updated);
    }
    widget.onBack();
  }

  // --- Document Formatting Helpers ---

  String _stripLinePrefix(String line) {
    var s = line;
    if (s.startsWith('- [ ] ')) return s.substring(6);
    if (s.startsWith('- [x] ')) return s.substring(6);
    if (s.startsWith('### ')) return s.substring(4);
    if (s.startsWith('## ')) return s.substring(3);
    if (s.startsWith('# ')) return s.substring(2);
    if (s.startsWith('• ')) return s.substring(2);
    if (s.startsWith('> ')) return s.substring(2);
    final numMatch = RegExp(r'^\d+\.\s+').firstMatch(s);
    if (numMatch != null) return s.substring(numMatch.end);
    return s;
  }

  void _applyHeading(String prefix) {
    final text = _bodyController.text;
    final sel = _bodyController.selection;
    final cursor = sel.isValid ? sel.start : text.length;

    final lineStart = text.lastIndexOf('\n', cursor == 0 ? 0 : cursor - 1) + 1;
    final lineEnd = text.indexOf('\n', cursor);
    final actualEnd = lineEnd == -1 ? text.length : lineEnd;
    final currentLine = text.substring(lineStart, actualEnd);

    final clean = _stripLinePrefix(currentLine);
    final newLine = '$prefix$clean';
    final newText = text.replaceRange(lineStart, actualEnd, newLine);
    final shift = newLine.length - (actualEnd - lineStart);

    _bodyController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (cursor + shift).clamp(0, newText.length),
      ),
    );
  }

  void _removeHeading() {
    final text = _bodyController.text;
    final sel = _bodyController.selection;
    final cursor = sel.isValid ? sel.start : text.length;

    final lineStart = text.lastIndexOf('\n', cursor == 0 ? 0 : cursor - 1) + 1;
    final lineEnd = text.indexOf('\n', cursor);
    final actualEnd = lineEnd == -1 ? text.length : lineEnd;
    final currentLine = text.substring(lineStart, actualEnd);

    final clean = _stripLinePrefix(currentLine);
    final newText = text.replaceRange(lineStart, actualEnd, clean);
    final shift = clean.length - (actualEnd - lineStart);

    _bodyController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (cursor + shift).clamp(0, newText.length),
      ),
    );
  }

  void _wrapSelection(String prefix, String suffix) {
    final text = _bodyController.text;
    final sel = _bodyController.selection;
    if (!sel.isValid || sel.isCollapsed) {
      final pos = sel.isValid ? sel.start : text.length;
      final newText = text.replaceRange(pos, pos, '$prefix$suffix');
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: pos + prefix.length),
      );
    } else {
      final selected = text.substring(sel.start, sel.end);
      final newText = text.replaceRange(sel.start, sel.end, '$prefix$selected$suffix');
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: sel.start,
          extentOffset: sel.end + prefix.length + suffix.length,
        ),
      );
    }
  }

  void _insertText(String toInsert) {
    final text = _bodyController.text;
    final sel = _bodyController.selection;
    final pos = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final newText = text.replaceRange(pos, end, toInsert);
    _bodyController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + toInsert.length),
    );
  }

  void _toggleChecklist() {
    final text = _bodyController.text;
    final sel = _bodyController.selection;
    final cursor = sel.isValid ? sel.start : text.length;
    final lineStart = text.lastIndexOf('\n', cursor == 0 ? 0 : cursor - 1) + 1;
    final lineEnd = text.indexOf('\n', cursor);
    final actualEnd = lineEnd == -1 ? text.length : lineEnd;
    final currentLine = text.substring(lineStart, actualEnd);

    String newLine;
    if (currentLine.startsWith('- [ ] ')) {
      newLine = '- [x] ${currentLine.substring(6)}';
    } else if (currentLine.startsWith('- [x] ')) {
      newLine = currentLine.substring(6);
    } else {
      final clean = _stripLinePrefix(currentLine);
      newLine = '- [ ] $clean';
    }

    final newText = text.replaceRange(lineStart, actualEnd, newLine);
    final shift = newLine.length - (actualEnd - lineStart);

    _bodyController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (cursor + shift).clamp(0, newText.length),
      ),
    );
  }

  void _applyPrefixToCurrentLine(String prefix) {
    final text = _bodyController.text;
    final sel = _bodyController.selection;
    final cursor = sel.isValid ? sel.start : text.length;

    final lineStart = text.lastIndexOf('\n', cursor == 0 ? 0 : cursor - 1) + 1;
    final lineEnd = text.indexOf('\n', cursor);
    final actualEnd = lineEnd == -1 ? text.length : lineEnd;
    final currentLine = text.substring(lineStart, actualEnd);

    String newLine;
    if (currentLine.startsWith(prefix)) {
      newLine = currentLine.substring(prefix.length);
    } else {
      final clean = _stripLinePrefix(currentLine);
      newLine = '$prefix$clean';
    }

    final newText = text.replaceRange(lineStart, actualEnd, newLine);
    final shift = newLine.length - (actualEnd - lineStart);

    _bodyController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (cursor + shift).clamp(0, newText.length),
      ),
    );
  }

  void _undo() {
    if (_undoIndex > 0) {
      _isUndoRedoAction = true;
      _undoIndex--;
      _bodyController.text = _undoStack[_undoIndex];
      _bodyController.selection = TextSelection.collapsed(
        offset: _bodyController.text.length,
      );
      _isUndoRedoAction = false;
    }
  }

  void _redo() {
    if (_undoIndex < _undoStack.length - 1) {
      _isUndoRedoAction = true;
      _undoIndex++;
      _bodyController.text = _undoStack[_undoIndex];
      _bodyController.selection = TextSelection.collapsed(
        offset: _bodyController.text.length,
      );
      _isUndoRedoAction = false;
    }
  }

  // --- Voice Memo Playback ---

  Future<void> _playVoiceMemo(String audioPath) async {
    if (_currentlyPlayingAudio == audioPath) {
      // Pause / Stop
      _audioPlaybackTimer?.cancel();
      _sysAudioProcess?.kill();
      _sysAudioProcess = null;
      setState(() {
        _currentlyPlayingAudio = null;
        _audioPlayProgressSec = 0;
      });
      return;
    }

    _audioPlaybackTimer?.cancel();
    _sysAudioProcess?.kill();
    _sysAudioProcess = null;

    final file = File(audioPath);
    if (!file.existsSync()) {
      UndoToast.show(context, message: 'Audio file not found on disk');
      return;
    }

    setState(() {
      _currentlyPlayingAudio = audioPath;
      _audioPlayProgressSec = 0;
    });

    try {
      try {
        _sysAudioProcess = await Process.start('pw-play', [audioPath]);
      } catch (_) {
        try {
          _sysAudioProcess = await Process.start('ffplay', ['-nodisp', '-autoexit', audioPath]);
        } catch (_) {
          _sysAudioProcess = await Process.start('aplay', [audioPath]);
        }
      }

      _audioPlaybackTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() {
          _audioPlayProgressSec++;
        });
      });

      _sysAudioProcess?.exitCode.then((_) {
        _audioPlaybackTimer?.cancel();
        if (mounted) {
          setState(() {
            _currentlyPlayingAudio = null;
            _audioPlayProgressSec = 0;
          });
        }
      });
    } catch (e) {
      AppLogger.w('Voice playback error: $e');
      if (mounted) {
        setState(() {
          _currentlyPlayingAudio = null;
          _audioPlayProgressSec = 0;
        });
      }
    }
  }

  // --- Find & Replace ---

  void _updateFindMatches() {
    final query = _findController.text;
    if (query.isEmpty) {
      setState(() {
        _matches = [];
        _currentMatchIndex = 0;
      });
      return;
    }

    final source = _caseSensitive ? _bodyController.text : _bodyController.text.toLowerCase();
    final target = _caseSensitive ? query : query.toLowerCase();

    final matches = <int>[];
    int start = 0;
    while (true) {
      final index = source.indexOf(target, start);
      if (index == -1) break;
      matches.add(index);
      start = index + target.length;
    }

    setState(() {
      _matches = matches;
      if (_currentMatchIndex >= matches.length) {
        _currentMatchIndex = 0;
      }
    });
    _highlightCurrentMatch();
  }

  void _highlightCurrentMatch() {
    if (_matches.isEmpty) return;
    final pos = _matches[_currentMatchIndex];
    final len = _findController.text.length;
    _bodyController.selection = TextSelection(baseOffset: pos, extentOffset: pos + len);
  }

  void _findNext() {
    if (_matches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matches.length;
    });
    _highlightCurrentMatch();
  }

  void _findPrevious() {
    if (_matches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + _matches.length) % _matches.length;
    });
    _highlightCurrentMatch();
  }

  void _replaceCurrent() {
    if (_matches.isEmpty) return;
    final pos = _matches[_currentMatchIndex];
    final len = _findController.text.length;
    final replaceWith = _replaceController.text;

    final text = _bodyController.text;
    final newText = text.replaceRange(pos, pos + len, replaceWith);
    _bodyController.text = newText;
    _updateFindMatches();
  }

  void _replaceAll() {
    final query = _findController.text;
    if (query.isEmpty) return;
    final replaceWith = _replaceController.text;
    final text = _bodyController.text;

    String newText;
    if (_caseSensitive) {
      newText = text.replaceAll(query, replaceWith);
    } else {
      newText = text.replaceAll(RegExp(RegExp.escape(query), caseSensitive: false), replaceWith);
    }
    _bodyController.text = newText;
    _updateFindMatches();
  }

  // --- Modals & Sheets ---

  void _showHeadingStyleSelector() {
    AppBottomSheet.show<void>(
      context: context,
      title: 'Text Style & Format',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStyleOption(
              label: 'Title',
              subtitle: 'Largest document title header',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              onTap: () {
                _applyHeading('# ');
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 6),
            _buildStyleOption(
              label: 'Heading 1',
              subtitle: 'Primary section header',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              onTap: () {
                _applyHeading('## ');
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 6),
            _buildStyleOption(
              label: 'Heading 2',
              subtitle: 'Sub-section header',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              onTap: () {
                _applyHeading('### ');
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 6),
            _buildStyleOption(
              label: 'To-Do / Checklist',
              subtitle: 'Interactive task checklist box (☐)',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              onTap: () {
                _applyPrefixToCurrentLine('- [ ] ');
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 6),
            _buildStyleOption(
              label: 'Bullet List',
              subtitle: 'Bullet point list item (•)',
              fontSize: 15,
              fontWeight: FontWeight.normal,
              onTap: () {
                _applyPrefixToCurrentLine('• ');
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 6),
            _buildStyleOption(
              label: 'Numbered List',
              subtitle: 'Ordered list item (1.)',
              fontSize: 15,
              fontWeight: FontWeight.normal,
              onTap: () {
                _applyPrefixToCurrentLine('1. ');
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 6),
            _buildStyleOption(
              label: 'Quote Block',
              subtitle: 'Indented quotation block (> )',
              fontSize: 15,
              fontWeight: FontWeight.normal,
              onTap: () {
                _applyPrefixToCurrentLine('> ');
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 6),
            _buildStyleOption(
              label: 'Body Text',
              subtitle: 'Standard regular paragraph text',
              fontSize: 14,
              fontWeight: FontWeight.normal,
              onTap: () {
                _removeHeading();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleOption({
    required String label,
    required String subtitle,
    required double fontSize,
    required FontWeight fontWeight,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.appSurface2.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.appLine, width: 1.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: fontWeight,
                      color: context.appText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.accent),
          ],
        ),
      ),
    );
  }

  void _showPaperStyleSelector() {
    AppBottomSheet.show<void>(
      context: context,
      title: 'Paper & Book Style',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPaperOption(
              style: NotePaperStyle.plain,
              icon: Icons.note_alt_outlined,
              title: 'Plain Blank',
              subtitle: 'Clean minimalist modern paper',
            ),
            const SizedBox(height: 6),
            _buildPaperOption(
              style: NotePaperStyle.lined,
              icon: Icons.format_line_spacing_rounded,
              title: 'Lined Notebook',
              subtitle: 'Ruled horizontal lines (Samsung Notes style)',
            ),
            const SizedBox(height: 6),
            _buildPaperOption(
              style: NotePaperStyle.grid,
              icon: Icons.grid_4x4_rounded,
              title: 'Grid Paper',
              subtitle: 'Crisp graph paper squares',
            ),
            const SizedBox(height: 6),
            _buildPaperOption(
              style: NotePaperStyle.book,
              icon: Icons.menu_book_rounded,
              title: 'Book Reader',
              subtitle: 'Warm book parchment, serif font & left margin guide',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaperOption({
    required NotePaperStyle style,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _paperStyle == style;
    return InkWell(
      onTap: () {
        setState(() {
          _paperStyle = style;
        });
        _scheduleSilentAutoSave();
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.15)
              : context.appSurface2.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.accent : context.appLine,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: isSelected ? AppColors.accent : context.appText),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: context.appText,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: context.appMuted),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 20),
          ],
        ),
      ),
    );
  }

  void _showTextSizeSelector() {
    AppBottomSheet.show<void>(
      context: context,
      title: 'Note Font Size',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in [
              {'name': 'Small', 'size': 14.0},
              {'name': 'Regular (Default)', 'size': 16.5},
              {'name': 'Large', 'size': 19.0},
              {'name': 'Extra Large', 'size': 22.0},
            ]) ...[
              InkWell(
                onTap: () {
                  setState(() {
                    _baseFontSize = entry['size'] as double;
                  });
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _baseFontSize == entry['size']
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : context.appSurface2.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _baseFontSize == entry['size'] ? AppColors.accent : context.appLine,
                      width: _baseFontSize == entry['size'] ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Aa',
                        style: TextStyle(
                          fontSize: entry['size'] as double,
                          fontWeight: FontWeight.bold,
                          color: context.appText,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          entry['name'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: _baseFontSize == entry['size'] ? FontWeight.w700 : FontWeight.w500,
                            color: context.appText,
                          ),
                        ),
                      ),
                      if (_baseFontSize == entry['size'])
                        const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }

  void _showColorPicker() {
    AppBottomSheet.show<void>(
      context: context,
      title: 'Note Theme Tint',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < noteColorThemes.length; i++) ...[
              InkWell(
                onTap: () {
                  setState(() => _colorIndex = i);
                  _scheduleSilentAutoSave();
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _colorIndex == i
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _colorIndex == i ? AppColors.accent : context.appLine,
                      width: _colorIndex == i ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: noteColorThemes[i].previewColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          noteColorThemes[i].name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: _colorIndex == i ? FontWeight.w700 : FontWeight.w500,
                            color: context.appText,
                          ),
                        ),
                      ),
                      if (_colorIndex == i)
                        const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 20),
                    ],
                  ),
                ),
              ),
              if (i < noteColorThemes.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showVoiceToNoteModal() async {
    final granted = await SpeechToTextService.instance.requestMicrophonePermission(context);
    if (!granted) return;

    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceToNoteSheet(
        onInsertTranscription: (transcribedText, audioFilePath) {
          if (transcribedText.trim().isNotEmpty) {
            _insertText('$transcribedText ');
          }
          if (audioFilePath != null && audioFilePath.isNotEmpty) {
            setState(() {
              _attachedVoiceNotes.add(audioFilePath);
            });
            _scheduleSilentAutoSave();
          }
          UndoToast.show(context, message: 'Voice memo added to note');
        },
      ),
    );
  }

  void _showAddTagDialog() {
    final tagTextController = TextEditingController();
    const suggestions = ['Work', 'Ideas', 'Personal', 'Project', 'Meeting', 'Todo', 'Study'];

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          title: const Text('Add Tag', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: tagTextController,
                autofocus: true,
                decoration: InputDecoration(
                  prefixText: '#',
                  hintText: 'e.g. Work, Ideas',
                  filled: true,
                  fillColor: dialogCtx.appSurface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onSubmitted: (val) {
                  final t = val.trim().replaceAll('#', '');
                  if (t.isNotEmpty && !_tags.contains(t)) {
                    setState(() => _tags.add(t));
                    _scheduleSilentAutoSave();
                  }
                  Navigator.of(dialogCtx).pop();
                },
              ),
              const SizedBox(height: 12),
              const Text('Suggested:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: suggestions.map((s) {
                  return InkWell(
                    onTap: () {
                      if (!_tags.contains(s)) {
                        setState(() => _tags.add(s));
                        _scheduleSilentAutoSave();
                      }
                      Navigator.of(dialogCtx).pop();
                    },
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: dialogCtx.appSurface2,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: dialogCtx.appLine),
                      ),
                      child: Text('#$s', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final t = tagTextController.text.trim().replaceAll('#', '');
                if (t.isNotEmpty && !_tags.contains(t)) {
                  setState(() => _tags.add(t));
                  _scheduleSilentAutoSave();
                }
                Navigator.of(dialogCtx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Add Tag'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      if (result != null && result.paths.isNotEmpty) {
        setState(() {
          for (final p in result.paths) {
            if (p != null && !_attachedImages.contains(p)) {
              _attachedImages.add(p);
            }
          }
        });
        _scheduleSilentAutoSave();
        if (mounted) {
          UndoToast.show(context, message: 'Photo attached to note');
        }
      }
    } catch (e) {
      AppLogger.w('Failed to pick image: $e');
    }
  }

  void _showImagePreview(String imagePath) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          title: Text(
            'Delete Note?',
            style: AppTypography.h3.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          content: Text(
            'This note will be moved to trash and can be restored later.',
            style: TextStyle(
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                widget.onDeleteNote(widget.note);
                widget.onBack();
              },
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  // --- Toolbar Widget Builders ---

  Widget _buildDockButton({
    String? label,
    IconData? icon,
    bool isBold = false,
    bool isItalic = false,
    bool isUnderline = false,
    bool isStrikethrough = false,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: isActive ? AppColors.accent.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            alignment: Alignment.center,
            child: icon != null
                ? Icon(
                    icon,
                    size: 18,
                    color: isActive ? AppColors.accent : context.appText,
                  )
                : Text(
                    label ?? '',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isBold ? FontWeight.w800 : (isActive ? FontWeight.w700 : FontWeight.w600),
                      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                      decoration: isUnderline
                          ? TextDecoration.underline
                          : (isStrikethrough ? TextDecoration.lineThrough : null),
                      color: isActive ? AppColors.accent : context.appText,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final theme = noteColorThemes[_colorIndex];

    Color screenBg;
    if (_paperStyle == NotePaperStyle.book) {
      screenBg = isDark ? const Color(0xFF231D16) : const Color(0xFFFAF2E4);
    } else {
      screenBg = isDark ? theme.darkBg : theme.lightBg;
    }

    final textC = isDark ? theme.darkText : theme.lightText;
    final textMuted = textC.withValues(alpha: 0.55);

    // Update controller theme dynamically
    _bodyController.updateTheme(
      textColor: textC,
      accentColor: AppColors.accent,
      mutedColor: textMuted,
      baseFontSize: _baseFontSize,
      paperStyle: _paperStyle,
    );

    final formattedDate = DateFormat('MMMM d, yyyy · h:mm a').format(
      DateTime.fromMillisecondsSinceEpoch(_lastSavedAt),
    );

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _debounceTimer?.cancel();
          final title = _titleController.text.trim();
          final compiledBody = _compileFullBody();
          if (title.isNotEmpty || compiledBody.trim().isNotEmpty || _noteId.isNotEmpty) {
            final updated = widget.note.copyWith(
              id: _noteId,
              title: _titleController.text,
              body: compiledBody,
              isPinned: _isPinned,
              colorIndex: _colorIndex,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            );
            widget.onSaveNote(updated);
          }
        }
      },
      child: Scaffold(
        backgroundColor: screenBg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Sleek Top Action Bar (Silent & Professional)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    CircularIconButton(
                      icon: AppIcons.back,
                      size: 34,
                      iconSize: 18,
                      onPressed: _saveAndClose,
                    ),
                    const SizedBox(width: 6),

                    // Paper / Book Style Quick Button
                    InkWell(
                      onTap: _showPaperStyleSelector,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: context.appSurface2.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.appLine, width: 1.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _paperStyle == NotePaperStyle.book
                                  ? Icons.menu_book_rounded
                                  : (_paperStyle == NotePaperStyle.lined
                                      ? Icons.format_line_spacing_rounded
                                      : (_paperStyle == NotePaperStyle.grid
                                          ? Icons.grid_4x4_rounded
                                          : Icons.note_alt_outlined)),
                              size: 13,
                              color: context.appText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _paperStyle == NotePaperStyle.book
                                  ? 'Book'
                                  : (_paperStyle == NotePaperStyle.lined
                                      ? 'Lined'
                                      : (_paperStyle == NotePaperStyle.grid ? 'Grid' : 'Plain')),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: context.appText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Voice to Note Direct Button
                    CircularIconButton(
                      icon: Icons.mic_rounded,
                      size: 32,
                      iconSize: 16,
                      customColor: AppColors.accent.withValues(alpha: 0.15),
                      iconColor: AppColors.accent,
                      onPressed: _showVoiceToNoteModal,
                    ),
                    const SizedBox(width: 4),

                    // Color Tint Button
                    CircularIconButton(
                      icon: Icons.palette_outlined,
                      size: 32,
                      iconSize: 16,
                      onPressed: _showColorPicker,
                    ),
                    const SizedBox(width: 4),

                    // Pin Toggle Button
                    CircularIconButton(
                      icon: AppIcons.pin,
                      size: 32,
                      iconSize: 16,
                      customColor: _isPinned ? AppColors.accent : null,
                      iconColor: _isPinned ? Colors.white : null,
                      onPressed: () {
                        setState(() => _isPinned = !_isPinned);
                        _scheduleSilentAutoSave();
                        UndoToast.show(
                          context,
                          message: _isPinned ? 'Note pinned to top' : 'Note unpinned',
                        );
                      },
                    ),
                    const SizedBox(width: 4),

                    // Trash Button
                    CircularIconButton(
                      icon: AppIcons.trash,
                      size: 32,
                      iconSize: 16,
                      iconColor: AppColors.danger,
                      onPressed: _confirmDelete,
                    ),
                    const SizedBox(width: 6),

                    // Done Button
                    ElevatedButton(
                      onPressed: _saveAndClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Expandable Find & Replace Bar
              if (_showFindBar)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.appLine, width: 1.0),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _findController,
                              style: TextStyle(color: context.appText, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Find in note...',
                                hintStyle: TextStyle(color: context.appMuted),
                                isDense: true,
                                filled: true,
                                fillColor: context.appSurface2,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onChanged: (_) => _updateFindMatches(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _replaceController,
                              style: TextStyle(color: context.appText, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Replace with...',
                                hintStyle: TextStyle(color: context.appMuted),
                                isDense: true,
                                filled: true,
                                fillColor: context.appSurface2,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          InkWell(
                            onTap: _findPrevious,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: context.appSurface2,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.arrow_upward_rounded, size: 16),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: _findNext,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: context.appSurface2,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.arrow_downward_rounded, size: 16),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _replaceCurrent,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.appSurface2,
                              foregroundColor: context.appText,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Replace', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            onPressed: _replaceAll,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.appSurface2,
                              foregroundColor: context.appText,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('All', style: TextStyle(fontSize: 12)),
                          ),
                          const Spacer(),
                          Text(
                            _matches.isEmpty
                                ? 'No matches'
                                : '${_currentMatchIndex + 1} of ${_matches.length}',
                            style: TextStyle(color: context.appMuted, fontSize: 12),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => setState(() => _showFindBar = false),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // 3. Document Canvas Area
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _paperStyle == NotePaperStyle.book ? 28 : 22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Document Title
                      TextField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          color: textC,
                          fontFamily: _paperStyle == NotePaperStyle.book ? 'Georgia' : null,
                        ),
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Title',
                          hintStyle: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            color: textMuted,
                            fontFamily: _paperStyle == NotePaperStyle.book ? 'Georgia' : null,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.only(top: 8, bottom: 4),
                        ),
                      ),

                      // Document Metadata (Silent, Non-Intrusive)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '$formattedDate · $_wordsCount words · $_charsCount chars · $_readingTimeMin min read',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textMuted,
                          ),
                        ),
                      ),

                      // Tags Bar (Pocketdesk Note Tags)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              for (int ti = 0; ti < _tags.length; ti++) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(
                                      color: AppColors.accent.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '#${_tags[ti]}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () {
                                          setState(() => _tags.removeAt(ti));
                                          _scheduleSilentAutoSave();
                                        },
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 14,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              InkWell(
                                onTap: _showAddTagDialog,
                                borderRadius: BorderRadius.circular(99),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: context.appSurface2.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(color: context.appLine),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_rounded, size: 14, color: context.appMuted),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Tag',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: context.appMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Attached Photos Section
                      if (_attachedImages.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          height: 84,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _attachedImages.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, imgIdx) {
                              final imgPath = _attachedImages[imgIdx];
                              return Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () => _showImagePreview(imgPath),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(imgPath),
                                        width: 84,
                                        height: 84,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 84,
                                          height: 84,
                                          color: context.appSurface2,
                                          child: const Icon(Icons.broken_image_rounded),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() => _attachedImages.removeAt(imgIdx));
                                        _scheduleSilentAutoSave();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],

                      // Attached Voice Memos Section
                      if (_attachedVoiceNotes.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int vi = 0; vi < _attachedVoiceNotes.length; vi++) ...[
                                _buildVoiceMemoPill(
                                  index: vi,
                                  audioPath: _attachedVoiceNotes[vi],
                                  textColor: textC,
                                  textMuted: textMuted,
                                ),
                                const SizedBox(height: 6),
                              ],
                            ],
                          ),
                        ),
                      ],

                      Divider(color: textMuted.withValues(alpha: 0.15), height: 1),

                      // Document Body Canvas with Paper Texture
                      Expanded(
                        child: CustomPaint(
                          painter: PaperBackgroundPainter(
                            style: _paperStyle,
                            lineColor: context.appLine.withValues(alpha: 0.35),
                            lineHeight: 28.0,
                          ),
                          child: TextField(
                            controller: _bodyController,
                            focusNode: _bodyFocusNode,
                            maxLines: null,
                            expands: true,
                            keyboardType: TextInputType.multiline,
                            style: TextStyle(
                              fontSize: _baseFontSize,
                              height: 1.6,
                              color: textC,
                              fontFamily: _paperStyle == NotePaperStyle.book ? 'Georgia' : null,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Start writing your note...',
                              hintStyle: TextStyle(
                                fontSize: _baseFontSize,
                                height: 1.6,
                                color: textMuted,
                                fontFamily: _paperStyle == NotePaperStyle.book ? 'Georgia' : null,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Samsung Notes Standard Document Floating Formatting Dock
              Container(
                margin: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 12,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: context.appLine, width: 1.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x28000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Style Dropdown (Replaces H1/H2 with user-friendly selector with size previews)
                      InkWell(
                        onTap: _showHeadingStyleSelector,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: context.appSurface2,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Style',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: context.appText,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Bold
                      _buildDockButton(
                        label: 'B',
                        isBold: true,
                        onTap: () => _wrapSelection('**', '**'),
                      ),

                      // Italic
                      _buildDockButton(
                        label: 'I',
                        isItalic: true,
                        onTap: () => _wrapSelection('*', '*'),
                      ),

                      // Underline
                      _buildDockButton(
                        label: 'U',
                        isUnderline: true,
                        onTap: () => _wrapSelection('__', '__'),
                      ),

                      // Strikethrough
                      _buildDockButton(
                        label: 'S',
                        isStrikethrough: true,
                        onTap: () => _wrapSelection('~~', '~~'),
                      ),

                      // Checkbox
                      _buildDockButton(
                        icon: Icons.check_box_outlined,
                        onTap: _toggleChecklist,
                      ),

                      // Bullet List
                      _buildDockButton(
                        label: '•',
                        isBold: true,
                        onTap: () => _applyPrefixToCurrentLine('• '),
                      ),

                      // Numbered List
                      _buildDockButton(
                        label: '1.',
                        onTap: () => _applyPrefixToCurrentLine('1. '),
                      ),

                      // Quote
                      _buildDockButton(
                        label: '“ ”',
                        onTap: () => _applyPrefixToCurrentLine('> '),
                      ),

                      // Horizontal Divider
                      _buildDockButton(
                        label: '—',
                        onTap: () => _insertText('\n---\n'),
                      ),

                      Container(
                        width: 1,
                        height: 20,
                        color: context.appLine,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),

                      // Font Size Selector
                      _buildDockButton(
                        icon: Icons.format_size_rounded,
                        onTap: _showTextSizeSelector,
                      ),

                      // Voice to Note
                      _buildDockButton(
                        icon: Icons.mic_none_rounded,
                        onTap: _showVoiceToNoteModal,
                      ),

                      // Attach Photo
                      _buildDockButton(
                        icon: Icons.image_outlined,
                        onTap: _pickImage,
                      ),

                      Container(
                        width: 1,
                        height: 20,
                        color: context.appLine,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),

                      // Undo
                      _buildDockButton(
                        icon: AppIcons.undo,
                        onTap: _undo,
                      ),

                      // Redo
                      _buildDockButton(
                        icon: AppIcons.redo,
                        onTap: _redo,
                      ),

                      // Find & Replace
                      _buildDockButton(
                        icon: AppIcons.search,
                        isActive: _showFindBar,
                        onTap: () => setState(() => _showFindBar = !_showFindBar),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceMemoPill({
    required int index,
    required String audioPath,
    required Color textColor,
    required Color textMuted,
  }) {
    final isPlaying = _currentlyPlayingAudio == audioPath;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 1.0),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => _playVoiceMemo(audioPath),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.mic_rounded, size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      'Voice Memo ${index + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    if (isPlaying) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${_audioPlayProgressSec}s)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  audioPath.split('/').last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: AppColors.danger,
            onPressed: () {
              if (isPlaying) {
                _playVoiceMemo(audioPath);
              }
              setState(() {
                _attachedVoiceNotes.removeAt(index);
              });
              _scheduleSilentAutoSave();
            },
          ),
        ],
      ),
    );
  }
}

/// Voice to Note interactive sheet
class VoiceToNoteSheet extends StatefulWidget {
  final void Function(String transcribedText, String? audioFilePath) onInsertTranscription;

  const VoiceToNoteSheet({
    super.key,
    required this.onInsertTranscription,
  });

  @override
  State<VoiceToNoteSheet> createState() => _VoiceToNoteSheetState();
}

class _VoiceToNoteSheetState extends State<VoiceToNoteSheet> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late TextEditingController _transcriptController;

  AudioRecorder? _audioRecorder;
  Process? _sysRecordProcess;
  Process? _sysPlayProcess;
  bool _isRecording = false;
  bool _isPlayingPreview = false;
  bool _isTranscribing = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String? _recordedFilePath;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _transcriptController = TextEditingController();
    _startRecording();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recordTimer?.cancel();
    _sysRecordProcess?.kill();
    _sysPlayProcess?.kill();
    _audioRecorder?.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${docsDir.path}/notes_audio');
      if (!audioDir.existsSync()) {
        audioDir.createSync(recursive: true);
      }
      final filePath = '${audioDir.path}/note_voice_${DateTime.now().millisecondsSinceEpoch}.wav';

      if (Platform.isLinux) {
        try {
          _sysRecordProcess = await Process.start('pw-record', [filePath]);
          _recordedFilePath = filePath;
        } catch (_) {
          try {
            _sysRecordProcess = await Process.start('arecord', ['-q', '-f', 'cd', '-t', 'wav', filePath]);
            _recordedFilePath = filePath;
          } catch (_) {
            try {
              _sysRecordProcess = await Process.start('ffmpeg', ['-y', '-f', 'pulse', '-i', 'default', filePath]);
              _recordedFilePath = filePath;
            } catch (e) {
              AppLogger.w('System record process error: $e');
            }
          }
        }
      } else {
        _audioRecorder = AudioRecorder();
        final hasPerm = await _audioRecorder!.hasPermission();
        if (hasPerm) {
          await _audioRecorder!.start(
            const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1),
            path: filePath,
          );
          _recordedFilePath = filePath;
        }
      }

      if (mounted) {
        setState(() {
          _isRecording = true;
          _recordSeconds = 0;
        });
      }

      _pulseController.repeat(reverse: true);
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() {
          _recordSeconds++;
        });
      });
    } catch (e) {
      AppLogger.w('Start recording failed: $e');
    }
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    _pulseController.stop();

    if (_sysRecordProcess != null) {
      try {
        _sysRecordProcess!.kill(ProcessSignal.sigint);
        await _sysRecordProcess!.exitCode.timeout(
          const Duration(milliseconds: 300),
          onTimeout: () {
            _sysRecordProcess?.kill();
            return 0;
          },
        );
      } catch (_) {
        _sysRecordProcess?.kill();
      }
      _sysRecordProcess = null;
    }

    if (_audioRecorder != null) {
      try {
        if (await _audioRecorder!.isRecording()) {
          final path = await _audioRecorder!.stop();
          if (path != null && path.isNotEmpty) {
            _recordedFilePath = path;
          }
        }
      } catch (e) {
        AppLogger.w('AudioRecorder stop error: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isRecording = false;
        _isTranscribing = true;
      });
    }

    try {
      if (_recordedFilePath != null &&
          File(_recordedFilePath!).existsSync() &&
          File(_recordedFilePath!).lengthSync() > 0) {
        final text = await SpeechToTextService.instance.translateAudioToText(
          audioFilePath: _recordedFilePath!,
        );
        if (text != null && text.trim().isNotEmpty) {
          _transcriptController.text = text.trim();
        } else {
          _interpretEnglishSpeech();
        }
      } else {
        _interpretEnglishSpeech();
      }
    } catch (e) {
      AppLogger.w('Voice transcription error: $e');
      _interpretEnglishSpeech();
    } finally {
      if (mounted) {
        setState(() {
          _isTranscribing = false;
        });
      }
    }
  }

  void _interpretEnglishSpeech() {
    if (_transcriptController.text.isEmpty) {
      _transcriptController.text = '';
    }
  }

  Future<void> _togglePreviewPlay() async {
    if (_recordedFilePath == null || !File(_recordedFilePath!).existsSync()) return;

    if (_isPlayingPreview) {
      _sysPlayProcess?.kill();
      setState(() => _isPlayingPreview = false);
      return;
    }

    setState(() => _isPlayingPreview = true);

    try {
      try {
        _sysPlayProcess = await Process.start('pw-play', [_recordedFilePath!]);
      } catch (_) {
        try {
          _sysPlayProcess = await Process.start('ffplay', ['-nodisp', '-autoexit', _recordedFilePath!]);
        } catch (_) {
          _sysPlayProcess = await Process.start('aplay', [_recordedFilePath!]);
        }
      }

      _sysPlayProcess?.exitCode.then((_) {
        if (mounted) {
          setState(() => _isPlayingPreview = false);
        }
      });
    } catch (e) {
      AppLogger.w('Preview playback error: $e');
      if (mounted) {
        setState(() => _isPlayingPreview = false);
      }
    }
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard : AppColors.lightCard;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Voice to Note (English)',
                style: AppTypography.h3.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _isRecording
                ? 'Listening... Speak in English. Audio is recording and will be saved.'
                : 'Recording complete. Edit transcription or tap Insert into Note.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 20),

          // Big Pulsing Mic Visualizer
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = _isRecording ? 1.0 + (_pulseController.value * 0.15) : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? AppColors.accent : context.appSurface2,
                      boxShadow: _isRecording
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.4),
                                blurRadius: 20 * _pulseController.value + 6,
                                spreadRadius: 4 * _pulseController.value,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      _isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                      size: 36,
                      color: _isRecording ? Colors.white : context.appText,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Duration & Status
          Center(
            child: Text(
              _formatTime(_recordSeconds),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_isTranscribing) ...[
            const SizedBox(height: 12),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.accent),
                  const SizedBox(height: 16),
                  Text(
                    'Translating English speech to note text...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Writing spoken words directly into the note...',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            // Controls Row (Start / Stop Recording / Restart Record)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                if (_isRecording) ...[
                  ElevatedButton.icon(
                    onPressed: _stopRecording,
                    icon: const Icon(Icons.stop_rounded, size: 20),
                    label: const Text('Stop Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _startRecording,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Restart Record'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: _startRecording,
                    icon: const Icon(Icons.mic_rounded, size: 18),
                    label: const Text('Start Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _startRecording,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Restart Record'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  if (_recordedFilePath != null)
                    OutlinedButton.icon(
                      onPressed: _togglePreviewPlay,
                      icon: Icon(_isPlayingPreview ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 18),
                      label: Text(_isPlayingPreview ? 'Pause' : 'Play Audio'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Editable Transcription Box
            Text(
              'Transcribed English Text (typed into Note):',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _transcriptController,
              maxLines: 3,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: _isRecording
                    ? 'Speak in English now... Click Stop Recording when finished'
                    : 'Click Start Recording and speak in English...',
                filled: true,
                fillColor: context.appSurface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.appLine),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),

            // Action Button
            ElevatedButton(
              onPressed: () {
                if (_isRecording) {
                  _stopRecording();
                } else {
                  final text = _transcriptController.text.trim();
                  if (text.isNotEmpty) {
                    widget.onInsertTranscription(
                      text,
                      _recordedFilePath,
                    );
                  }
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _isRecording ? 'Stop & Type into Notepad' : 'Insert Spoken English into Notepad',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

