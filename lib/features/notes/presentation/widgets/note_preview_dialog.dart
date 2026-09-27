import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/note_model.dart';
import '../providers/notes_notifier.dart';
import '../pages/note_editor_page.dart';

class NotePreviewDialog extends ConsumerWidget {
  const NotePreviewDialog({super.key, required this.note});

  final NoteModel note;

  static void show(BuildContext context, NoteModel note) {
    showDialog<void>(
      context: context,
      builder: (_) => NotePreviewDialog(note: note),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title with actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (note.isPinned) ...[
                              Icon(Icons.push_pin_rounded, size: 16, color: cs.primary),
                              const SizedBox(width: 4),
                            ],
                            if (note.isFavorite) ...[
                              const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                            ],
                            if (note.folderName != null && note.folderName!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  note.folderName!,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          note.title.isEmpty ? 'Untitled Note' : note.title,
                          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Last edited: ${note.updatedAt.day}/${note.updatedAt.month}/${note.updatedAt.year} ${note.updatedAt.hour}:${note.updatedAt.minute.toString().padLeft(2, '0')}',
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),

                  // Quick Action Edit & Delete Icons
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit Note',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => NoteEditorPage(note: note),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: cs.error),
                    tooltip: 'Delete Note',
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final title = note.title;
                      await ref.read(notesProvider.notifier).deleteNote(note.id);
                      if (context.mounted) {
                        Navigator.pop(context);
                        messenger.showSnackBar(
                          SnackBar(content: Text('Deleted "$title"')),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Note Content / Checklist
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (note.imagePaths.isNotEmpty) ...[
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: note.imagePaths.length,
                            itemBuilder: (ctx, i) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(note.imagePaths[i]),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 120,
                                    height: 120,
                                    color: cs.surfaceContainerHighest,
                                    child: const Icon(Icons.broken_image_rounded),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (note.hasChecklist) ...[
                        Text('Checklist', style: tt.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
                        const SizedBox(height: 8),
                        ...List.generate(note.checklistItems.length, (i) {
                          final isDone = i < note.checklistDone.length && note.checklistDone[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  isDone ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                  size: 20,
                                  color: isDone ? cs.primary : cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    note.checklistItems[i],
                                    style: tt.bodyMedium?.copyWith(
                                      decoration: isDone ? TextDecoration.lineThrough : null,
                                      color: isDone ? cs.onSurfaceVariant : cs.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ] else ...[
                        SelectableText(
                          note.content.isEmpty ? '(No content)' : note.content,
                          style: tt.bodyMedium?.copyWith(height: 1.5),
                        ),
                      ],

                      if (note.tags.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 6,
                          children: note.tags.map((String t) => Chip(
                            label: Text('#$t', style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.bold)),
                            backgroundColor: cs.primaryContainer.withValues(alpha: 0.4),
                            side: BorderSide.none,
                            padding: EdgeInsets.zero,
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => NoteEditorPage(note: note),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit Note'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
