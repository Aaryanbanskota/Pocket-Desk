import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_icons.dart';
import 'calendar_month_widget.dart';

class WidgetNoteItem {
  final String id;
  final String title;
  final String snippet;
  final bool isPinned;
  final bool hasVoiceMemo;
  final String date;
  final String? tag;

  const WidgetNoteItem({
    required this.id,
    required this.title,
    required this.snippet,
    this.isPinned = false,
    this.hasVoiceMemo = false,
    this.date = 'Today',
    this.tag,
  });
}

/// Quick Notes & Voice Memo Widget for Device Home Screen
/// Provides quick note overview and 1-tap New Note and Voice Note capture
class QuickNotesWidget extends StatelessWidget {
  final WidgetSize size;
  final bool isDarkMode;
  final List<WidgetNoteItem>? notes;
  final VoidCallback? onNewNote;
  final VoidCallback? onVoiceNote;
  final ValueChanged<WidgetNoteItem>? onTapNote;

  const QuickNotesWidget({
    super.key,
    this.size = WidgetSize.medium,
    this.isDarkMode = false,
    this.notes,
    this.onNewNote,
    this.onVoiceNote,
    this.onTapNote,
  });

  List<WidgetNoteItem> get _effectiveNotes {
    if (notes != null && notes!.isNotEmpty) return notes!;
    return const [
      WidgetNoteItem(
        id: '1',
        title: 'Project Roadmap & Goals',
        snippet: 'Finalize mobile widget responsiveness and document styling...',
        isPinned: true,
        hasVoiceMemo: true,
        date: '10:30 AM',
        tag: 'Work',
      ),
      WidgetNoteItem(
        id: '2',
        title: 'Voice Memo: Team Sync',
        snippet: 'Discussed calendar dual AD/BS support and budget filters.',
        isPinned: false,
        hasVoiceMemo: true,
        date: 'Yesterday',
        tag: 'Ideas',
      ),
      WidgetNoteItem(
        id: '3',
        title: 'Grocery & Weekend Plan',
        snippet: 'Checklist for Saturday morning market and supplies.',
        isPinned: false,
        date: 'Oct 18',
        tag: 'Personal',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDarkMode ? const Color(0xFF1E1E24) : const Color(0xFFFFFDF9);
    final textPrimary = isDarkMode ? Colors.white : const Color(0xFF1C1917);
    final textMuted = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF78716C);
    final borderColor = isDarkMode ? const Color(0xFF2E2E38) : const Color(0xFFE7E5E4);
    final surface2 = isDarkMode ? const Color(0xFF282834) : const Color(0xFFF5F3EF);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: size == WidgetSize.small
          ? _buildSmall(textPrimary, textMuted, surface2)
          : (size == WidgetSize.medium
              ? _buildMedium(textPrimary, textMuted, surface2)
              : _buildLarge(textPrimary, textMuted, surface2)),
    );
  }

  Widget _buildSmall(Color textPrimary, Color textMuted, Color surface2) {
    final topNote = _effectiveNotes.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(AppIcons.notes, size: 14, color: AppColors.accent),
                const SizedBox(width: 4),
                Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${_effectiveNotes.length}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
        InkWell(
          onTap: onTapNote != null ? () => onTapNote!(topNote) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  topNote.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  topNote.snippet,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: textMuted, height: 1.25),
                ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: InkWell(
                onTap: onVoiceNote,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic_rounded, size: 13, color: AppColors.accent),
                      SizedBox(width: 4),
                      Text(
                        'Voice',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: InkWell(
                onTap: onNewNote,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: surface2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, size: 13, color: textPrimary),
                      const SizedBox(width: 4),
                      Text(
                        'Note',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMedium(Color textPrimary, Color textMuted, Color surface2) {
    final list = _effectiveNotes.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(AppIcons.notes, size: 15, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  'Quick Notes',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${_effectiveNotes.length})',
                  style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: onVoiceNote,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mic_rounded, size: 12, color: AppColors.accent),
                        SizedBox(width: 4),
                        Text(
                          'Voice Note',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: onNewNote,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: surface2,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_rounded, size: 14, color: textPrimary),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Column(
            children: [
              for (int i = 0; i < list.length; i++) ...[
                Expanded(
                  child: _buildNoteRow(list[i], textPrimary, textMuted, surface2),
                ),
                if (i < list.length - 1) const SizedBox(height: 6),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLarge(Color textPrimary, Color textMuted, Color surface2) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(AppIcons.notes, size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  'Recent Notes & Memos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: onVoiceNote,
                  icon: const Icon(Icons.mic_rounded, size: 14),
                  label: const Text('Record Voice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: onNewNote,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    backgroundColor: surface2,
                    padding: const EdgeInsets.all(6),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            physics: const ClampingScrollPhysics(),
            itemCount: _effectiveNotes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) => _buildNoteRow(_effectiveNotes[i], textPrimary, textMuted, surface2),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteRow(
    WidgetNoteItem note,
    Color textPrimary,
    Color textMuted,
    Color surface2,
  ) {
    return InkWell(
      onTap: onTapNote != null ? () => onTapNote!(note) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: surface2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (note.isPinned)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(AppIcons.pin, size: 12, color: AppColors.accent),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      if (note.hasVoiceMemo) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.mic_rounded, size: 12, color: AppColors.accent),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    note.snippet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  note.date,
                  style: TextStyle(fontSize: 9.5, color: textMuted, fontWeight: FontWeight.w500),
                ),
                if (note.tag != null) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: textMuted.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      note.tag!,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: textMuted),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
