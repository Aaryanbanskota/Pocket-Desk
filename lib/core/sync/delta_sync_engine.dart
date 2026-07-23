import 'package:isar/isar.dart';
import '../../features/calendar/data/models/calendar_event_model.dart';
import '../../features/tasks/data/models/task_model.dart';
import '../../features/notes/data/models/note_model.dart';
import 'sync_protocol.dart';
import '../logging/app_logger.dart';

/// Delta Sync Engine to record, packetize, and apply database delta changes.
/// Implements Last-Write-Wins (LWW) conflict resolution using `updatedAt`.
class DeltaSyncEngine {
  DeltaSyncEngine({required Isar isar}) : _isar = isar;
  final Isar _isar;

  /// Gets unsynced items from all collections.
  Future<List<DeltaChange>> getPendingChanges(int userId) async {
    final changes = <DeltaChange>[];
    try {
      // 1. Tasks
      final tasks = await _isar.taskModels.where().userIdEqualTo(userId).findAll();
      for (final t in tasks.where((t) => !t.isSynced)) {
        changes.add(DeltaChange(
          collection: SyncProtocol.colTasks,
          recordId: t.id,
          operation: DeltaOp.update,
          data: {
            'title': t.title,
            'description': t.description,
            'priority': t.priority.name,
            'status': t.status.name,
            'dueDate': t.dueDate?.toIso8601String(),
            'category': t.category,
            'listName': t.listName,
            'folderName': t.folderName,
            'subtaskTitles': t.subtaskTitles,
            'subtaskDone': t.subtaskDone,
            'isRecurring': t.isRecurring,
            'recurrenceRule': t.recurrenceRule,
          },
          updatedAt: t.updatedAt,
        ));
      }

      // 2. Notes
      final notes = await _isar.noteModels.where().userIdEqualTo(userId).findAll();
      for (final n in notes.where((n) => !n.isSynced)) {
        changes.add(DeltaChange(
          collection: SyncProtocol.colNotes,
          recordId: n.id,
          operation: DeltaOp.update,
          data: {
            'title': n.title,
            'content': n.content,
            'folderName': n.folderName,
            'tags': n.tags,
            'isPinned': n.isPinned,
            'isFavorite': n.isFavorite,
            'hasChecklist': n.hasChecklist,
            'checklistItems': n.checklistItems,
            'checklistDone': n.checklistDone,
          },
          updatedAt: n.updatedAt,
        ));
      }

      // 3. Calendar Events
      final events = await _isar.calendarEventModels.where().userIdEqualTo(userId).findAll();
      for (final e in events.where((e) => !e.isSynced)) {
        changes.add(DeltaChange(
          collection: SyncProtocol.colCalendarEvents,
          recordId: e.id,
          operation: DeltaOp.update,
          data: {
            'title': e.title,
            'description': e.description,
            'location': e.location,
            'startTime': e.startTime.toIso8601String(),
            'endTime': e.endTime.toIso8601String(),
            'isAllDay': e.isAllDay,
            'recurrenceType': e.recurrenceType.name,
            'recurrenceRule': e.recurrenceRule,
            'reminderMinutes': e.reminderMinutes,
            'colorHex': e.colorHex,
          },
          updatedAt: e.updatedAt,
        ));
      }
    } catch (e, st) {
      AppLogger.e('Error generating delta changes', tag: 'SyncEngine', error: e, st: st);
    }
    return changes;
  }

  /// Applies delta changes received from a paired device.
  /// Resolves conflicts using Last-Write-Wins (LWW) based on `updatedAt`.
  Future<void> applyChanges(int userId, List<DeltaChange> changes) async {
    await _isar.writeTxn(() async {
      for (final change in changes) {
        try {
          if (change.collection == SyncProtocol.colTasks) {
            await _syncTask(userId, change);
          } else if (change.collection == SyncProtocol.colNotes) {
            await _syncNote(userId, change);
          } else if (change.collection == SyncProtocol.colCalendarEvents) {
            await _syncCalendarEvent(userId, change);
          }
        } catch (e, st) {
          AppLogger.e('Failed to apply sync change', tag: 'SyncEngine', error: e, st: st);
        }
      }
    });
  }

  /// Marks items as synced.
  Future<void> markAsSynced(int userId, List<DeltaChange> changes) async {
    await _isar.writeTxn(() async {
      for (final change in changes) {
        if (change.collection == SyncProtocol.colTasks) {
          final t = await _isar.taskModels.get(change.recordId);
          if (t != null) {
            t.isSynced = true;
            await _isar.taskModels.put(t);
          }
        } else if (change.collection == SyncProtocol.colNotes) {
          final n = await _isar.noteModels.get(change.recordId);
          if (n != null) {
            n.isSynced = true;
            await _isar.noteModels.put(n);
          }
        } else if (change.collection == SyncProtocol.colCalendarEvents) {
          final e = await _isar.calendarEventModels.get(change.recordId);
          if (e != null) {
            e.isSynced = true;
            await _isar.calendarEventModels.put(e);
          }
        }
      }
    });
  }

  // ─── Private Helpers for Collection Mapping & LWW ──────────────────────────

  Future<void> _syncTask(int userId, DeltaChange c) async {
    final existing = await _isar.taskModels.get(c.recordId);
    if (existing != null && existing.updatedAt.isAfter(c.updatedAt)) {
      AppLogger.i('LWW: Kept local task update for ID ${c.recordId}', tag: 'SyncEngine');
      return; // Local is newer
    }

    final d = c.data;
    final task = (existing ?? TaskModel())
      ..id = c.recordId
      ..userId = userId
      ..title = d['title'] as String
      ..description = d['description'] as String?
      ..priority = TaskPriority.values.byName(d['priority'] as String)
      ..status = TaskStatus.values.byName(d['status'] as String)
      ..dueDate = d['dueDate'] != null ? DateTime.parse(d['dueDate'] as String) : null
      ..category = d['category'] as String?
      ..listName = d['listName'] as String?
      ..folderName = d['folderName'] as String?
      ..subtaskTitles = List<String>.from(d['subtaskTitles'] as List)
      ..subtaskDone = List<bool>.from(d['subtaskDone'] as List)
      ..isRecurring = d['isRecurring'] as bool? ?? false
      ..recurrenceRule = d['recurrenceRule'] as String?
      ..isSynced = true
      ..updatedAt = c.updatedAt
      ..createdAt = existing?.createdAt ?? c.updatedAt;

    await _isar.taskModels.put(task);
  }

  Future<void> _syncNote(int userId, DeltaChange c) async {
    final existing = await _isar.noteModels.get(c.recordId);
    if (existing != null && existing.updatedAt.isAfter(c.updatedAt)) {
      AppLogger.i('LWW: Kept local note update for ID ${c.recordId}', tag: 'SyncEngine');
      return;
    }

    final d = c.data;
    final note = (existing ?? NoteModel())
      ..id = c.recordId
      ..userId = userId
      ..title = d['title'] as String
      ..content = d['content'] as String? ?? ''
      ..folderName = d['folderName'] as String?
      ..tags = List<String>.from(d['tags'] as List)
      ..isPinned = d['isPinned'] as bool? ?? false
      ..isFavorite = d['isFavorite'] as bool? ?? false
      ..hasChecklist = d['hasChecklist'] as bool? ?? false
      ..checklistItems = List<String>.from(d['checklistItems'] as List)
      ..checklistDone = List<bool>.from(d['checklistDone'] as List)
      ..isSynced = true
      ..updatedAt = c.updatedAt
      ..createdAt = existing?.createdAt ?? c.updatedAt;

    await _isar.noteModels.put(note);
  }

  Future<void> _syncCalendarEvent(int userId, DeltaChange c) async {
    final existing = await _isar.calendarEventModels.get(c.recordId);
    if (existing != null && existing.updatedAt.isAfter(c.updatedAt)) {
      AppLogger.i('LWW: Kept local event update for ID ${c.recordId}', tag: 'SyncEngine');
      return;
    }

    final d = c.data;
    final event = (existing ?? CalendarEventModel())
      ..id = c.recordId
      ..userId = userId
      ..title = d['title'] as String
      ..description = d['description'] as String?
      ..location = d['location'] as String?
      ..startTime = DateTime.parse(d['startTime'] as String)
      ..endTime = DateTime.parse(d['endTime'] as String)
      ..isAllDay = d['isAllDay'] as bool? ?? false
      ..recurrenceType = RecurrenceType.values.byName(d['recurrenceType'] as String)
      ..recurrenceRule = d['recurrenceRule'] as String?
      ..reminderMinutes = List<int>.from(d['reminderMinutes'] as List)
      ..colorHex = d['colorHex'] as String?
      ..isSynced = true
      ..updatedAt = c.updatedAt
      ..createdAt = existing?.createdAt ?? c.updatedAt;

    await _isar.calendarEventModels.put(event);
  }
}
