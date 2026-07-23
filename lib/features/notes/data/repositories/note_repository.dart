import 'package:isar/isar.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../models/note_model.dart';

class NoteRepository {
  NoteRepository({required Isar isar}) : _isar = isar;
  final Isar _isar;

  Future<List<NoteModel>> getNotesForUser(int userId, {String? folder}) async {
    try {
      final all = await _isar.noteModels.where().userIdEqualTo(userId).findAll();
      if (folder != null) return all.where((n) => n.folderName == folder).toList();
      return all;
    } catch (e, st) {
      AppLogger.e('Failed to fetch notes', tag: 'NoteRepo', error: e, st: st);
      return [];
    }
  }

  Future<List<NoteModel>> searchNotes(int userId, String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final all = await _isar.noteModels.where().userIdEqualTo(userId).findAll();
      final q = query.toLowerCase();
      return all.where((n) =>
        n.title.toLowerCase().contains(q) ||
        n.content.toLowerCase().contains(q) ||
        n.tags.any((t) => t.toLowerCase().contains(q))
      ).toList();
    } catch (e, st) {
      AppLogger.e('Failed to search notes', tag: 'NoteRepo', error: e, st: st);
      return [];
    }
  }

  Future<List<String>> getFolders(int userId) async {
    final all = await _isar.noteModels.where().userIdEqualTo(userId).findAll();
    return all
        .map((n) => n.folderName)
        .where((f) => f != null && f.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
  }

  Future<({NoteModel? note, AppFailure? error})> saveNote(NoteModel note) async {
    try {
      final now = DateTime.now();
      note.updatedAt = now;
      if (note.id == Isar.autoIncrement) note.createdAt = now;
      await _isar.writeTxn(() => _isar.noteModels.put(note));
      AppLogger.i('Saved note: ${note.title}', tag: 'NoteRepo');
      return (note: note, error: null);
    } catch (e, st) {
      AppLogger.e('Failed to save note', tag: 'NoteRepo', error: e, st: st);
      return (note: null, error: UnexpectedFailure('Failed to save note', error: e, stackTrace: st));
    }
  }

  Future<AppFailure?> deleteNote(int noteId) async {
    try {
      await _isar.writeTxn(() => _isar.noteModels.delete(noteId));
      return null;
    } catch (e, st) {
      return UnexpectedFailure('Failed to delete note', error: e, stackTrace: st);
    }
  }
}
