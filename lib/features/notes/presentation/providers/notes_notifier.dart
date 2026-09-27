import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/isar_provider.dart';
import '../../../../core/error/app_failure.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/note_model.dart';
import '../../data/repositories/note_repository.dart';

final noteRepositoryProvider = FutureProvider<NoteRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return NoteRepository(isar: isar);
});

// ─── State ───────────────────────────────────────────────────────────────────

class NotesState {
  const NotesState({
    this.notes = const [],
    this.folders = const [],
    this.selectedFolder,
    this.isLoading = false,
    this.error,
  });

  final List<NoteModel> notes;
  final List<String> folders;
  final String? selectedFolder;
  final bool isLoading;
  final AppFailure? error;

  NotesState copyWith({
    List<NoteModel>? notes,
    List<String>? folders,
    String? selectedFolder,
    bool clearFolder = false,
    bool? isLoading,
    AppFailure? error,
  }) =>
      NotesState(
        notes: notes ?? this.notes,
        folders: folders ?? this.folders,
        selectedFolder: clearFolder ? null : selectedFolder ?? this.selectedFolder,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class NotesNotifier extends AutoDisposeAsyncNotifier<NotesState> {
  @override
  Future<NotesState> build() async {
    final notes = await _fetch();
    final folders = await _fetchFolders();
    return NotesState(notes: notes, folders: folders);
  }

  Future<List<NoteModel>> _fetch({String? folder}) async {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return [];
    final repo = await ref.read(noteRepositoryProvider.future);
    return repo.getNotesForUser(auth.user.id, folder: folder);
  }

  Future<List<String>> _fetchFolders() async {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return [];
    final repo = await ref.read(noteRepositoryProvider.future);
    return repo.getFolders(auth.user.id);
  }

  Future<void> setFolder(String? folder) async {
    final prev = state.valueOrNull ?? const NotesState();
    state = AsyncValue.data(prev.copyWith(isLoading: true));
    final notes = await _fetch(folder: folder);
    final s = state.valueOrNull ?? const NotesState();
    state = AsyncValue.data(s.copyWith(
      notes: notes,
      isLoading: false,
      selectedFolder: folder,
      clearFolder: folder == null,
    ));
  }

  Future<void> saveNote({
    required String title,
    String content = '',
    String? folderName,
    List<String> tags = const [],
    bool isPinned = false,
    bool isFavorite = false,
    bool hasChecklist = false,
    List<String> checklistItems = const [],
    List<bool> checklistDone = const [],
    int? noteId,
  }) async {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return;
    final repo = await ref.read(noteRepositoryProvider.future);

    final note = NoteModel()
      ..userId = auth.user.id
      ..title = title
      ..content = content
      ..folderName = folderName
      ..tags = tags
      ..isPinned = isPinned
      ..isFavorite = isFavorite
      ..hasChecklist = hasChecklist
      ..checklistItems = checklistItems
      ..checklistDone = checklistDone.isEmpty && checklistItems.isNotEmpty
          ? List.filled(checklistItems.length, false)
          : List.from(checklistDone);

    if (noteId != null) note.id = noteId;

    final result = await repo.saveNote(note);
    if (result.error != null) {
      state = AsyncValue.data((state.valueOrNull ?? const NotesState())
          .copyWith(error: result.error));
    } else {
      ref.invalidateSelf();
    }
  }

  Future<void> togglePin(NoteModel note) async {
    final repo = await ref.read(noteRepositoryProvider.future);
    note.isPinned = !note.isPinned;
    await repo.saveNote(note);
    ref.invalidateSelf();
  }

  Future<void> toggleFavorite(NoteModel note) async {
    final repo = await ref.read(noteRepositoryProvider.future);
    note.isFavorite = !note.isFavorite;
    await repo.saveNote(note);
    ref.invalidateSelf();
  }

  Future<void> deleteNote(int noteId) async {
    final repo = await ref.read(noteRepositoryProvider.future);
    await repo.deleteNote(noteId);
    ref.invalidateSelf();
  }

  Future<void> duplicateNote(NoteModel note) async {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return;
    final repo = await ref.read(noteRepositoryProvider.future);

    final dup = NoteModel()
      ..userId = auth.user.id
      ..title = '${note.title} (Copy)'
      ..content = note.content
      ..folderName = note.folderName
      ..tags = List.from(note.tags)
      ..isPinned = note.isPinned
      ..isFavorite = note.isFavorite
      ..hasChecklist = note.hasChecklist
      ..checklistItems = List.from(note.checklistItems)
      ..checklistDone = List.from(note.checklistDone)
      ..imagePaths = List.from(note.imagePaths);

    await repo.saveNote(dup);
    ref.invalidateSelf();
  }

  Future<List<NoteModel>> searchNotes(String query) async {
    final auth = ref.read(authNotifierProvider).valueOrNull;
    if (auth is! AuthAuthenticated) return [];
    final repo = await ref.read(noteRepositoryProvider.future);
    return repo.searchNotes(auth.user.id, query);
  }
}

final notesProvider =
    AutoDisposeAsyncNotifierProvider<NotesNotifier, NotesState>(
  NotesNotifier.new,
);
