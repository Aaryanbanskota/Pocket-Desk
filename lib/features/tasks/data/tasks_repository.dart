import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/myday_database.dart';

class MyDayTask {
  final String id;
  final String accountId;
  final String kind; // 'todo' | 'timed'
  final String title;
  final int minDuration;
  final int durationLeftMs;
  final String dueDate; // 'YYYY-MM-DD'
  final bool isImportant;
  final bool isDone;
  final int? doneAt;
  final String repeatInterval; // 'none' | 'daily' | 'weekly'
  final bool spawned;
  final List<String> tags;
  final String note;
  final bool isDeleted;
  final int? deletedAt;

  const MyDayTask({
    required this.id,
    required this.accountId,
    this.kind = 'todo',
    required this.title,
    this.minDuration = 0,
    this.durationLeftMs = 0,
    required this.dueDate,
    this.isImportant = false,
    this.isDone = false,
    this.doneAt,
    this.repeatInterval = 'none',
    this.spawned = false,
    this.tags = const [],
    this.note = '',
    this.isDeleted = false,
    this.deletedAt,
  });

  factory MyDayTask.fromRow(QueryRow row) {
    List<String> parsedTags = [];
    try {
      final jsonStr = row.read<String>('tags_json');
      parsedTags = List<String>.from(jsonDecode(jsonStr) as List);
    } catch (_) {}

    return MyDayTask(
      id: row.read<String>('id'),
      accountId: row.read<String>('account_id'),
      kind: row.read<String>('kind'),
      title: row.read<String>('title'),
      minDuration: row.read<int>('min_duration'),
      durationLeftMs: row.read<int>('duration_left_ms'),
      dueDate: row.read<String>('due_date'),
      isImportant: row.read<int>('is_important') == 1,
      isDone: row.read<int>('is_done') == 1,
      doneAt: row.read<int?>('done_at'),
      repeatInterval: row.read<String>('repeat_interval'),
      spawned: row.read<int>('spawned') == 1,
      tags: parsedTags,
      note: row.read<String>('note'),
      isDeleted: row.read<int>('is_deleted') == 1,
      deletedAt: row.read<int?>('deleted_at'),
    );
  }

  MyDayTask copyWith({
    String? kind,
    String? title,
    int? minDuration,
    int? durationLeftMs,
    String? dueDate,
    bool? isImportant,
    bool? isDone,
    int? doneAt,
    String? repeatInterval,
    bool? spawned,
    List<String>? tags,
    String? note,
  }) {
    return MyDayTask(
      id: id,
      accountId: accountId,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      minDuration: minDuration ?? this.minDuration,
      durationLeftMs: durationLeftMs ?? this.durationLeftMs,
      dueDate: dueDate ?? this.dueDate,
      isImportant: isImportant ?? this.isImportant,
      isDone: isDone ?? this.isDone,
      doneAt: doneAt ?? this.doneAt,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      spawned: spawned ?? this.spawned,
      tags: tags ?? this.tags,
      note: note ?? this.note,
      isDeleted: isDeleted,
      deletedAt: deletedAt,
    );
  }
}

class TasksRepository {
  final MyDayDatabase db;
  static const _uuid = Uuid();

  TasksRepository(this.db);

  /// Retrieves tasks for the given account filtered by filter tab ('today', 'upcoming', 'all', 'done')
  Future<List<MyDayTask>> getTasks(String accountId, {String filter = 'all'}) async {
    final now = DateTime.now();
    final todayIso =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    String whereClause = 'account_id = ? AND is_deleted = 0';
    List<Variable> vars = [Variable(accountId)];

    if (filter == 'today') {
      whereClause += ' AND due_date <= ? AND is_done = 0';
      vars.add(Variable(todayIso));
    } else if (filter == 'upcoming') {
      whereClause += ' AND due_date > ? AND is_done = 0';
      vars.add(Variable(todayIso));
    } else if (filter == 'events') {
      whereClause += " AND tags_json LIKE '%event%'";
    } else if (filter == 'done') {
      whereClause += ' AND is_done = 1';
    }

    final rows = await db.customSelect(
      'SELECT * FROM tasks WHERE $whereClause ORDER BY due_date ASC, created_at DESC',
      variables: vars,
    ).get();

    return rows.map(MyDayTask.fromRow).toList();
  }

  /// Gets dates that have incomplete tasks for mini-calendar markers
  Future<Set<String>> getDatesWithTasks(String accountId) async {
    final rows = await db.customSelect(
      'SELECT DISTINCT due_date FROM tasks WHERE account_id = ? AND is_done = 0 AND is_deleted = 0',
      variables: [Variable(accountId)],
    ).get();

    return rows.map((r) => r.read<String>('due_date')).toSet();
  }

  /// Adds a new task
  Future<MyDayTask> addTask({
    required String accountId,
    required String title,
    String kind = 'todo',
    int minDuration = 25,
    required String dueDate,
    bool isImportant = false,
    List<String> tags = const [],
    String repeatInterval = 'none',
    String note = '',
  }) async {
    final id = _uuid.v4().substring(0, 8);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final durationLeft = kind == 'timed' ? minDuration * 60 * 1000 : 0;

    await db.customInsert(
      '''
      INSERT INTO tasks (
        id, account_id, kind, title, min_duration, duration_left_ms, due_date,
        is_important, is_done, repeat_interval, spawned, tags_json, note,
        is_deleted, sync_status, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?, 0, ?, ?, 0, 'pending', ?, ?)
      ''',
      variables: [
        Variable(id),
        Variable(accountId),
        Variable(kind),
        Variable(title),
        Variable(kind == 'timed' ? minDuration : 0),
        Variable(durationLeft),
        Variable(dueDate),
        Variable(isImportant ? 1 : 0),
        Variable(repeatInterval),
        Variable(jsonEncode(tags)),
        Variable(note),
        Variable(nowMs),
        Variable(nowMs),
      ],
    );

    return MyDayTask(
      id: id,
      accountId: accountId,
      kind: kind,
      title: title,
      minDuration: kind == 'timed' ? minDuration : 0,
      durationLeftMs: durationLeft,
      dueDate: dueDate,
      isImportant: isImportant,
      isDone: false,
      repeatInterval: repeatInterval,
      tags: tags,
      note: note,
    );
  }

  /// Updates an existing task
  Future<void> updateTask(MyDayTask task) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.customUpdate(
      '''
      UPDATE tasks SET
        kind = ?, title = ?, min_duration = ?, duration_left_ms = ?, due_date = ?,
        is_important = ?, is_done = ?, done_at = ?, repeat_interval = ?, tags_json = ?,
        note = ?, sync_status = 'pending', updated_at = ?
      WHERE id = ?
      ''',
      variables: [
        Variable(task.kind),
        Variable(task.title),
        Variable(task.minDuration),
        Variable(task.durationLeftMs),
        Variable(task.dueDate),
        Variable(task.isImportant ? 1 : 0),
        Variable(task.isDone ? 1 : 0),
        Variable(task.doneAt),
        Variable(task.repeatInterval),
        Variable(jsonEncode(task.tags)),
        Variable(task.note),
        Variable(nowMs),
        Variable(task.id),
      ],
    );
  }

  /// Toggles task completion and schedules recurring task if applicable
  Future<void> toggleTaskDone(MyDayTask task) async {
    final newDone = !task.isDone;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final updated = task.copyWith(
      isDone: newDone,
      doneAt: newDone ? nowMs : null,
    );

    await updateTask(updated);

    // Spawning next recurring task
    if (newDone && task.repeatInterval != 'none' && !task.spawned) {
      await _spawnNextRecurringTask(task);
    }
  }

  Future<void> _spawnNextRecurringTask(MyDayTask task) async {
    try {
      final currentDue = DateTime.parse('${task.dueDate}T00:00:00');
      final nextDue = task.repeatInterval == 'daily'
          ? currentDue.add(const Duration(days: 1))
          : currentDue.add(const Duration(days: 7));

      final nextIso =
          '${nextDue.year}-${nextDue.month.toString().padLeft(2, '0')}-${nextDue.day.toString().padLeft(2, '0')}';

      await addTask(
        accountId: task.accountId,
        title: task.title,
        kind: task.kind,
        minDuration: task.minDuration,
        dueDate: nextIso,
        isImportant: task.isImportant,
        tags: task.tags,
        repeatInterval: task.repeatInterval,
        note: task.note,
      );

      // Mark original task as spawned
      await db.customUpdate(
        'UPDATE tasks SET spawned = 1 WHERE id = ?',
        variables: [Variable(task.id)],
      );
    } catch (_) {}
  }

  /// Soft deletes task (moves to trash)
  Future<void> deleteTask(String taskId) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.customUpdate(
      "UPDATE tasks SET is_deleted = 1, deleted_at = ?, sync_status = 'pending' WHERE id = ?",
      variables: [Variable(nowMs), Variable(taskId)],
    );
  }


  /// Restores task from trash
  Future<void> restoreTask(String taskId) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.customUpdate(
      "UPDATE tasks SET is_deleted = 0, deleted_at = NULL, sync_status = 'pending', updated_at = ? WHERE id = ?",
      variables: [Variable(nowMs), Variable(taskId)],
    );
  }
}
