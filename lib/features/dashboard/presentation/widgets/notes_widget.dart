import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../notes/presentation/providers/notes_notifier.dart';
import '../../../notes/presentation/pages/note_editor_page.dart';
import '../../../notes/presentation/widgets/note_preview_dialog.dart';

class NotesWidget extends ConsumerWidget {
  const NotesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final notesAsync = ref.watch(notesProvider);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(50),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.notes),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            notesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(child: Text('Error loading notes: $err')),
              data: (state) {
                final notes = state.notes;
                if (notes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.note_alt_outlined,
                            size: 48,
                            color: colorScheme.onSurfaceVariant.withAlpha(100),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'No notes found',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Show up to 3 notes on dashboard
                final displayedNotes = notes.take(3).toList();

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedNotes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final note = displayedNotes[index];
                    return InkWell(
                      onTap: () => NotePreviewDialog.show(context, note),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withAlpha(40),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withAlpha(30),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    note.title.isEmpty ? 'Untitled Note' : note.title,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => NoteEditorPage(note: note),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(2),
                                        child: Icon(Icons.edit_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () async {
                                        final title = note.title;
                                        final messenger = ScaffoldMessenger.of(context);
                                        await ref.read(notesProvider.notifier).deleteNote(note.id);
                                        messenger.showSnackBar(
                                          SnackBar(content: Text('Deleted "$title"')),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(2),
                                        child: Icon(Icons.delete_outline_rounded, size: 16, color: colorScheme.error),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (note.content.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                note.content,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
