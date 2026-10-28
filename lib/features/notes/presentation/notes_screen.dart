import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/widgets/circular_icon_button.dart';
import '../../../core/design_system/widgets/undo_toast.dart';
import '../../../core/services/speech_to_text_service.dart';
import '../data/notes_repository.dart';
import 'notepad_editor_screen.dart';

class NotesScreen extends StatefulWidget {
  final List<MyDayNote> notes;
  final void Function(MyDayNote) onOpenNote;
  final ValueChanged<String> onSearchChanged;
  final String searchQuery;
  final VoidCallback? onAddNote;
  final VoidCallback? onVoiceNote;

  const NotesScreen({
    super.key,
    required this.notes,
    required this.onOpenNote,
    required this.onSearchChanged,
    required this.searchQuery,
    this.onAddNote,
    this.onVoiceNote,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 6),

            // Search Bar and Add Note Button
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.appSurface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: context.appLine, width: 1.0),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: context.appText),
                        decoration: InputDecoration(
                          prefixIcon: Icon(AppIcons.search, size: 20, color: context.appMuted),
                          hintText: 'Search notes',
                          hintStyle: TextStyle(
                            color: context.appMuted.withValues(alpha: 0.6),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onChanged: widget.onSearchChanged,
                      ),
                    ),
                  ),
                  if (widget.onAddNote != null) ...[
                    const SizedBox(width: 10),
                    CircularIconButton(
                      icon: AppIcons.plus,
                      size: 44,
                      iconSize: 22,
                      onPressed: widget.onAddNote,
                    ),
                  ],
                ],
              ),
            ),

            // Notes List: 2-column masonry/staggered grid
            Expanded(
              child: widget.notes.isEmpty
                  ? Center(
                      child: Text(
                        'No notes found',
                        style: AppTypography.body.copyWith(color: context.appMuted),
                      ),
                    )
                  : CustomScrollView(
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                        SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _buildNoteCard(context, widget.notes[index]);
                            },
                            childCount: widget.notes.length,
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 60)),
                      ],
                    ),
            ),
          ],
        ),

        // Floating Voice Note Button at the bottom
        if (widget.onVoiceNote != null)
          Positioned(
            bottom: 12,
            right: 0,
            child: Material(
              elevation: 8,
              shadowColor: AppColors.accent.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(999),
              color: AppColors.accent,
              child: InkWell(
                onTap: widget.onVoiceNote,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Voice Note',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNoteCard(BuildContext context, MyDayNote note) {
    final isDark = context.isDarkMode;
    final cardBg = isDark
        ? AppColors.noteColorsDark[note.colorIndex]
        : (note.colorIndex == 0 ? context.appSurface : AppColors.noteColorsDark[note.colorIndex]);

    final textC = isDark
        ? AppColors.noteTextColorsDark[note.colorIndex]
        : (note.colorIndex == 0 ? context.appText : Colors.white);

    final hasVoiceMemo = note.body.contains('[Voice Memo:');
    final hasImages = note.body.contains('<!-- images:');
    final tagMatch = RegExp(r'<!--\s*tags:\s*(.*?)\s*-->').firstMatch(note.body);
    final tags = tagMatch != null
        ? tagMatch.group(1)!.split(',').take(2).map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    final cleanBody = note.body
        .replaceAll(RegExp(r'\[Voice Memo:\s*.*?\]'), '')
        .replaceAll(RegExp(r'<!--.*?-->'), '')
        .replaceAll(RegExp(r'[#*_~]'), '')
        .replaceAll(RegExp(r'^\s*-\s*\[[ x]\]\s*', multiLine: true), '☐ ')
        .trim();

    return InkWell(
      onTap: () => widget.onOpenNote(note),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: note.colorIndex == 0
              ? Border.all(color: context.appLine, width: 1.0)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    note.title.isNotEmpty ? note.title : 'Untitled',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h4.copyWith(
                      color: textC,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (note.isPinned)
                  Icon(AppIcons.pin, size: 16, color: textC),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                cleanBody,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: textC.withValues(alpha: 0.75),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Footer Badges: Voice note, Photos, Tags
            Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (hasVoiceMemo)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic_rounded, size: 13, color: textC.withValues(alpha: 0.85)),
                      const SizedBox(width: 2),
                      Text(
                        'Voice',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textC.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                if (hasImages)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_outlined, size: 13, color: textC.withValues(alpha: 0.85)),
                      const SizedBox(width: 2),
                      Text(
                        'Photo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textC.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                for (final tag in tags)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: textC.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: textC.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NotesPage extends StatefulWidget {
  final NotesRepository notesRepository;
  final String accountId;
  final void Function(MyDayNote)? onOpenNote;
  final Future<void> Function()? onRefresh;

  const NotesPage({
    super.key,
    required this.notesRepository,
    required this.accountId,
    this.onOpenNote,
    this.onRefresh,
  });

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<MyDayNote> _notes = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void didUpdateWidget(covariant NotesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final notes = await widget.notesRepository
          .getNotes(widget.accountId, searchQuery: _searchQuery)
          .timeout(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _notes = notes;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadNotes();
  }

  void _openEditor([MyDayNote? note]) {
    NotepadEditorScreen.open(
      context,
      notesRepository: widget.notesRepository,
      accountId: widget.accountId,
      note: note,
    ).then((_) {
      _loadNotes();
    });
  }

  Future<void> _startVoiceNoteCreation() async {
    final granted = await SpeechToTextService.instance.requestMicrophonePermission(context);
    if (!granted) return;

    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceToNoteSheet(
        onInsertTranscription: (transcribedText, audioFilePath) async {
          final now = DateTime.now();
          final text = transcribedText.trim();
          String title;
          if (text.isNotEmpty) {
            final words = text.split(RegExp(r'\s+'));
            if (words.length <= 6) {
              title = text;
            } else {
              title = '${words.take(6).join(' ')}...';
            }
          } else {
            title = 'Voice Note ${DateFormat('MMM d, h:mm a').format(now)}';
          }

          String body = text;
          if (audioFilePath != null && audioFilePath.isNotEmpty) {
            body = '$body\n[Voice Memo: $audioFilePath]';
          }

          await widget.notesRepository.createNote(
            accountId: widget.accountId,
            title: title,
            body: body.trim(),
          );
          await _loadNotes();
          if (mounted) {
            UndoToast.show(context, message: 'New voice note recorded & saved!');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentOrange));
    }

    return RefreshIndicator(
      color: AppColors.accentOrange,
      backgroundColor: context.appSurface,
      onRefresh: () async {
        if (widget.onRefresh != null) {
          await widget.onRefresh!();
        }
        await _loadNotes();
      },
      child: NotesScreen(
        notes: _notes,
        onOpenNote: widget.onOpenNote ?? _openEditor,
        onAddNote: () => _openEditor(null),
        onVoiceNote: _startVoiceNoteCreation,
        searchQuery: _searchQuery,
        onSearchChanged: _onSearchChanged,
      ),
    );
  }
}

