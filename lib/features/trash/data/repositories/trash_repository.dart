import 'package:isar/isar.dart';
import '../../../../core/error/app_failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../data/models/trash_item_model.dart';
import '../../../notes/data/models/note_model.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../calendar/data/models/calendar_event_model.dart';
import '../../../posts/data/models/instant_model.dart';
import '../../../posts/data/models/post_model.dart';

class TrashRepository {
  TrashRepository({required Isar isar}) : _isar = isar;

  final Isar _isar;

  /// Retains deleted items for exactly 20 days.
  static const int retentionDays = 20;

  // --------------------------------------------------------------------------
  // Move Item to Trash
  // --------------------------------------------------------------------------

  Future<AppFailure?> moveToTrash({
    required int userId,
    required TrashItemType itemType,
    required int originalId,
    required String title,
    String? snippet,
    required String payloadJson,
  }) async {
    try {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: retentionDays));

      final trashItem = TrashItemModel()
        ..userId = userId
        ..itemType = itemType
        ..originalId = originalId
        ..title = title
        ..snippet = snippet
        ..payloadJson = payloadJson
        ..deletedAt = now
        ..expiresAt = expiresAt;

      await _isar.writeTxn(() async {
        await _isar.trashItemModels.put(trashItem);
      });

      AppLogger.i('Moved item to Trash: $title ($itemType)', tag: 'TrashRepository');
      return null;
    } catch (e, st) {
      AppLogger.e('Failed to move item to trash', tag: 'TrashRepository', error: e, st: st);
      return UnexpectedFailure('Failed to move item to Trash', error: e, stackTrace: st);
    }
  }

  // --------------------------------------------------------------------------
  // Get User Trash & Auto-Purge Expired Items (>20 Days)
  // --------------------------------------------------------------------------

  Future<List<TrashItemModel>> getTrashItemsForUser(int userId) async {
    try {
      final now = DateTime.now();

      // Auto-purge expired items older than 20 days
      await _isar.writeTxn(() async {
        final expired = await _isar.trashItemModels
            .where()
            .userIdEqualTo(userId)
            .filter()
            .expiresAtLessThan(now)
            .findAll();

        for (final item in expired) {
          await _isar.trashItemModels.delete(item.id);
        }
      });

      // Return active trash items sorted by deletedAt (newest first)
      return await _isar.trashItemModels
          .where()
          .userIdEqualTo(userId)
          .sortByDeletedAtDesc()
          .findAll();
    } catch (e, st) {
      AppLogger.e('Failed to fetch trash items', tag: 'TrashRepository', error: e, st: st);
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // Restore Item
  // --------------------------------------------------------------------------

  Future<AppFailure?> restoreItem(TrashItemModel item) async {
    try {
      await _isar.writeTxn(() async {
        switch (item.itemType) {
          case TrashItemType.note:
            final note = NoteModel()
              ..id = item.originalId
              ..userId = item.userId
              ..title = item.title
              ..content = item.snippet ?? ''
              ..createdAt = item.deletedAt
              ..updatedAt = DateTime.now();
            await _isar.noteModels.put(note);
            break;
          case TrashItemType.task:
            final task = TaskModel()
              ..id = item.originalId
              ..userId = item.userId
              ..title = item.title
              ..description = item.snippet
              ..createdAt = item.deletedAt
              ..updatedAt = DateTime.now();
            await _isar.taskModels.put(task);
            break;
          case TrashItemType.event:
            final event = CalendarEventModel()
              ..id = item.originalId
              ..userId = item.userId
              ..title = item.title
              ..description = item.snippet
              ..startTime = DateTime.now()
              ..endTime = DateTime.now().add(const Duration(hours: 1))
              ..createdAt = item.deletedAt
              ..updatedAt = DateTime.now();
            await _isar.calendarEventModels.put(event);
            break;
          case TrashItemType.post:
            final post = PostModel()
              ..id = item.originalId
              ..userId = item.userId
              ..title = item.title
              ..content = item.snippet ?? ''
              ..createdAt = item.deletedAt
              ..updatedAt = DateTime.now();
            await _isar.postModels.put(post);
            break;
          case TrashItemType.instant:
            final instant = InstantModel()
              ..id = item.originalId
              ..userId = item.userId
              ..imagePath = item.snippet ?? ''
              ..textOverlay = item.title
              ..createdAt = item.deletedAt
              ..expiresAt = DateTime.now().add(const Duration(hours: 24));
            await _isar.instantModels.put(instant);
            break;
          case TrashItemType.expense:
            break;
        }

        // Delete from Trash after restoring
        await _isar.trashItemModels.delete(item.id);
      });

      AppLogger.i('Restored item: ${item.title}', tag: 'TrashRepository');
      return null;
    } catch (e, st) {
      AppLogger.e('Failed to restore item', tag: 'TrashRepository', error: e, st: st);
      return UnexpectedFailure('Failed to restore item', error: e, stackTrace: st);
    }
  }

  // --------------------------------------------------------------------------
  // Permanent Delete Item
  // --------------------------------------------------------------------------

  Future<AppFailure?> deletePermanently(int trashId) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.trashItemModels.delete(trashId);
      });

      AppLogger.i('Permanently deleted trash item ID: $trashId', tag: 'TrashRepository');
      return null;
    } catch (e, st) {
      AppLogger.e('Failed to permanently delete item', tag: 'TrashRepository', error: e, st: st);
      return UnexpectedFailure('Failed to permanently delete item', error: e, stackTrace: st);
    }
  }

  // --------------------------------------------------------------------------
  // Empty All Trash
  // --------------------------------------------------------------------------

  Future<AppFailure?> emptyTrash(int userId) async {
    try {
      await _isar.writeTxn(() async {
        final items = await _isar.trashItemModels
            .where()
            .userIdEqualTo(userId)
            .findAll();
        for (final item in items) {
          await _isar.trashItemModels.delete(item.id);
        }
      });

      AppLogger.i('Emptied all trash for user ID: $userId', tag: 'TrashRepository');
      return null;
    } catch (e, st) {
      AppLogger.e('Failed to empty trash', tag: 'TrashRepository', error: e, st: st);
      return UnexpectedFailure('Failed to empty trash', error: e, stackTrace: st);
    }
  }
}
