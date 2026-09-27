import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketdesk/features/dashboard/presentation/widgets/app_hamburger_drawer.dart';
import '../../data/models/note_model.dart';
import '../providers/notes_notifier.dart';
import 'note_editor_page.dart';

class NotesDashboardView extends ConsumerStatefulWidget {
  const NotesDashboardView({super.key});

  @override
  ConsumerState<NotesDashboardView> createState() => _NotesDashboardViewState();
}

class _NotesDashboardViewState extends ConsumerState<NotesDashboardView> {
  final _searchCtrl = TextEditingController();
  bool _searching = false;
  List<NoteModel>? _searchResults;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _doSearch(String q) async {
    if (q.trim().isEmpty) { setState(() => _searchResults = null); return; }
    final results = await ref.read(notesProvider.notifier).searchNotes(q);
    setState(() => _searchResults = results);
  }

  void _openEditor([NoteModel? note]) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => NoteEditorPage(note: note),
      ));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      drawer: const AppHamburgerDrawer(),
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search notes…',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: cs.onSurfaceVariant),
                ),
                onChanged: _doSearch,
              )
            : Text('Notes', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search_outlined),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) { _searchCtrl.clear(); _searchResults = null; }
            }),
          ),
        ],
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (state) {
          final displayNotes = _searchResults ?? state.notes;

          return Row(
            children: [
              // Folder sidebar (wide screens only)
              if (MediaQuery.of(context).size.width > 600)
                _FolderSidebar(
                  folders: state.folders,
                  selected: state.selectedFolder,
                  onSelect: (f) => ref.read(notesProvider.notifier).setFolder(f),
                ),
              Expanded(
                child: displayNotes.isEmpty
                    ? _EmptyState(onAdd: _openEditor)
                    : _NotesGrid(notes: displayNotes, onTap: _openEditor),
              ),
            ],
          );
        },
      ),
      // Folder chips on narrow screens
      bottomNavigationBar: notesAsync.maybeWhen(
        data: (state) => state.folders.isEmpty
            ? null
            : _FolderChipBar(
                folders: state.folders,
                selected: state.selectedFolder,
                onSelect: (f) => ref.read(notesProvider.notifier).setFolder(f),
              ),
        orElse: () => null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('New Note'),
      ),
    );
  }
}

// ─── Notes Grid ───────────────────────────────────────────────────────────────

class _NotesGrid extends StatelessWidget {
  const _NotesGrid({required this.notes, required this.onTap});
  final List<NoteModel> notes;
  final void Function(NoteModel) onTap;

  @override
  Widget build(BuildContext context) {
    final pinned = notes.where((n) => n.isPinned).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final others = notes.where((n) => !n.isPinned).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (pinned.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.push_pin_outlined, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  'PINNED (${pinned.length})',
                  style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemCount: pinned.length,
            itemBuilder: (_, i) => _NoteCard(note: pinned[i], onTap: onTap),
          ),
          const SizedBox(height: 16),
        ],
        if (others.isNotEmpty) ...[
          if (pinned.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'OTHERS (${others.length})',
                style: tt.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemCount: others.length,
            itemBuilder: (_, i) => _NoteCard(note: others[i], onTap: onTap),
          ),
        ],
      ],
    );
  }
}

// ─── Note Card ────────────────────────────────────────────────────────────────

class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.note, required this.onTap});
  final NoteModel note;
  final void Function(NoteModel) onTap;

  static const _cardColors = [
    Color(0xFFFFF9C4), Color(0xFFE8F5E9), Color(0xFFE3F2FD),
    Color(0xFFF3E5F5), Color(0xFFFCE4EC), Color(0xFFE0F7FA),
  ];

  Color _cardColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) return Theme.of(context).colorScheme.surfaceContainerHighest;
    return _cardColors[note.id % _cardColors.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => onTap(note),
      onLongPress: () => _showOptions(context, ref),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: note.isPinned
              ? Border.all(color: cs.primary.withOpacity(0.6), width: 2)
              : null,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                if (note.isPinned)
                  Icon(Icons.push_pin, size: 14, color: cs.primary),
                if (note.isFavorite)
                  const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
              ],
            ),
            const SizedBox(height: 6),
            if (note.hasChecklist)
              Text(
                '${note.checklistDone.where((d) => d).length}/${note.checklistItems.length} done',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              )
            else
              Expanded(
                child: Text(
                  note.content,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            const Spacer(),
            if (note.tags.isNotEmpty)
              Wrap(
                spacing: 4,
                children: note.tags.take(3).map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(t, style: TextStyle(fontSize: 10, color: cs.primary)),
                    )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(notesProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(note.isPinned ? 'Unpin' : 'Pin'),
              onTap: () { notifier.togglePin(note); Navigator.pop(context); },
            ),
            ListTile(
              leading: Icon(note.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded),
              title: Text(note.isFavorite ? 'Unfavorite' : 'Favorite'),
              onTap: () { notifier.toggleFavorite(note); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () { notifier.deleteNote(note.id); Navigator.pop(context); },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Folder Sidebar ───────────────────────────────────────────────────────────

class _FolderSidebar extends StatelessWidget {
  const _FolderSidebar({required this.folders, this.selected, required this.onSelect});
  final List<String> folders;
  final String? selected;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 160,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: cs.outlineVariant)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _FolderTile(label: 'All Notes', icon: Icons.notes_outlined,
              selected: selected == null, onTap: () => onSelect(null)),
          ...folders.map((f) => _FolderTile(
                label: f,
                icon: Icons.folder_outlined,
                selected: selected == f,
                onTap: () => onSelect(f),
              )),
        ],
      ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({required this.label, required this.icon, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 18, color: selected ? cs.primary : cs.onSurfaceVariant),
      title: Text(label, style: TextStyle(
        color: selected ? cs.primary : cs.onSurface,
        fontWeight: selected ? FontWeight.w600 : null,
        fontSize: 13,
      )),
      tileColor: selected ? cs.primary.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }
}

// ─── Folder chip bar (narrow) ─────────────────────────────────────────────────

class _FolderChipBar extends StatelessWidget {
  const _FolderChipBar({required this.folders, this.selected, required this.onSelect});
  final List<String> folders;
  final String? selected;
  final void Function(String?) onSelect;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 52,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [
            ActionChip(
              label: const Text('All'),
              onPressed: () => onSelect(null),
              backgroundColor: selected == null
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
            ),
            const SizedBox(width: 6),
            ...folders.map((f) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(f),
                    onPressed: () => onSelect(f),
                    backgroundColor: selected == f
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                  ),
                )),
          ],
        ),
      );
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.note_outlined, size: 72, color: cs.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No notes yet', style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          FilledButton.tonal(onPressed: onAdd, child: const Text('Create your first note')),
        ],
      ),
    );
  }
}
