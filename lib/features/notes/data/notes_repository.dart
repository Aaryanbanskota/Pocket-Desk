import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/myday_database.dart';

class MyDayNote {
  final String id;
  final String accountId;
  final String title;
  final String body;
  final bool isPinned;
  final int colorIndex; // 0 to 4
  final int createdAt;
  final int updatedAt;
  final bool isDeleted;
  final int? deletedAt;

  const MyDayNote({
    required this.id,
    required this.accountId,
    required this.title,
    required this.body,
    this.isPinned = false,
    this.colorIndex = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  factory MyDayNote.fromRow(QueryRow row) {
    return MyDayNote(
      id: row.read<String>('id'),
      accountId: row.read<String>('account_id'),
      title: row.read<String>('title'),
      body: row.read<String>('body'),
      isPinned: row.read<int>('is_pinned') == 1,
      colorIndex: row.read<int>('color_index'),
      createdAt: row.read<int>('created_at'),
      updatedAt: row.read<int>('updated_at'),
      isDeleted: row.read<int>('is_deleted') == 1,
      deletedAt: row.read<int?>('deleted_at'),
    );
  }

  MyDayNote copyWith({
    String? id,
    String? title,
    String? body,
    bool? isPinned,
    int? colorIndex,
    int? updatedAt,
  }) {
    return MyDayNote(
      id: id ?? this.id,
      accountId: accountId,
      title: title ?? this.title,
      body: body ?? this.body,
      isPinned: isPinned ?? this.isPinned,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted,
      deletedAt: deletedAt,
    );
  }
}

class NotesRepository {
  final MyDayDatabase db;
  static const _uuid = Uuid();

  NotesRepository(this.db);

  /// Retrieves notes sorted by pinned first, then updated timestamp
  Future<List<MyDayNote>> getNotes(String accountId, {String searchQuery = ''}) async {
    String where = 'account_id = ? AND is_deleted = 0';
    List<Variable> vars = [Variable(accountId)];

    if (searchQuery.isNotEmpty) {
      where += ' AND (title LIKE ? OR body LIKE ?)';
      vars.add(Variable('%$searchQuery%'));
      vars.add(Variable('%$searchQuery%'));
    }

    final rows = await db.customSelect(
      'SELECT * FROM notes WHERE $where ORDER BY is_pinned DESC, updated_at DESC',
      variables: vars,
    ).get();

    return rows.map(MyDayNote.fromRow).toList();
  }

  /// Creates a new note
  Future<MyDayNote> createNote({
    required String accountId,
    String title = '',
    String body = '',
    bool isPinned = false,
    int colorIndex = 0,
  }) async {
    final id = _uuid.v4().substring(0, 8);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.customInsert(
      '''
      INSERT INTO notes (id, account_id, title, body, is_pinned, color_index, is_deleted, sync_status, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, 0, 'pending', ?, ?)
      ''',
      variables: [
        Variable(id),
        Variable(accountId),
        Variable(title),
        Variable(body),
        Variable(isPinned ? 1 : 0),
        Variable(colorIndex),
        Variable(nowMs),
        Variable(nowMs),
      ],
    );

    return MyDayNote(
      id: id,
      accountId: accountId,
      title: title,
      body: body,
      isPinned: isPinned,
      colorIndex: colorIndex,
      createdAt: nowMs,
      updatedAt: nowMs,
    );
  }

  /// Updates an existing note
  Future<void> updateNote(MyDayNote note) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.customUpdate(
      '''
      UPDATE notes SET
        title = ?, body = ?, is_pinned = ?, color_index = ?,
        sync_status = 'pending', updated_at = ?
      WHERE id = ?
      ''',
      variables: [
        Variable(note.title),
        Variable(note.body),
        Variable(note.isPinned ? 1 : 0),
        Variable(note.colorIndex),
        Variable(nowMs),
        Variable(note.id),
      ],
    );
  }

  /// Toggles note pinned state
  Future<void> togglePin(MyDayNote note) async {
    await updateNote(note.copyWith(isPinned: !note.isPinned));
  }

  /// Cycles note color (0 to 4)
  Future<void> cycleColor(MyDayNote note) async {
    final nextColor = (note.colorIndex + 1) % 5;
    await updateNote(note.copyWith(colorIndex: nextColor));
  }

  /// Soft deletes note
  Future<void> deleteNote(String noteId) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.customUpdate(
      "UPDATE notes SET is_deleted = 1, deleted_at = ?, sync_status = 'pending' WHERE id = ?",
      variables: [Variable(nowMs), Variable(noteId)],
    );
  }

  /// Restores note from trash
  Future<void> restoreNote(String noteId) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.customUpdate(
      "UPDATE notes SET is_deleted = 0, deleted_at = NULL, sync_status = 'pending', updated_at = ? WHERE id = ?",
      variables: [Variable(nowMs), Variable(noteId)],
    );
  }
}
