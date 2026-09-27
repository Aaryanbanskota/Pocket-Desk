import 'package:isar/isar.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../models/calendar_event_model.dart';

class CalendarRepository {
  CalendarRepository({required Isar isar}) : _isar = isar;

  final Isar _isar;

  // --------------------------------------------------------------------------
  // Create / Update Event
  // --------------------------------------------------------------------------

  Future<({CalendarEventModel? event, AppFailure? error})> saveEvent(
    CalendarEventModel event,
  ) async {
    try {
      final now = DateTime.now();
      event.updatedAt = now;
      if (event.id != Isar.autoIncrement && event.id > 0) {
        final existing = await _isar.calendarEventModels.get(event.id);
        if (existing != null) {
          event.createdAt = existing.createdAt;
        } else {
          event.createdAt = now;
        }
      } else {
        event.createdAt = now;
      }

      await _isar.writeTxn(() async {
        await _isar.calendarEventModels.put(event);
      });

      AppLogger.i('Saved event: ${event.title} (ID: ${event.id})', tag: 'CalendarRepository');
      return (event: event, error: null);
    } catch (e, st) {
      AppLogger.e('Failed to save event', tag: 'CalendarRepository', error: e, st: st);
      return (
        event: null,
        error: UnexpectedFailure('Failed to save event', error: e, stackTrace: st)
      );
    }
  }

  // --------------------------------------------------------------------------
  // Delete Event
  // --------------------------------------------------------------------------

  Future<AppFailure?> deleteEvent(int eventId) async {
    try {
      final success = await _isar.writeTxn(() async {
        return _isar.calendarEventModels.delete(eventId);
      });

      if (!success) {
        return const DatabaseFailure('Event to delete not found');
      }

      AppLogger.i('Deleted event ID: $eventId', tag: 'CalendarRepository');
      return null;
    } catch (e, st) {
      AppLogger.e('Failed to delete event', tag: 'CalendarRepository', error: e, st: st);
      return UnexpectedFailure('Failed to delete event', error: e, stackTrace: st);
    }
  }

  // --------------------------------------------------------------------------
  // Fetch Events
  // --------------------------------------------------------------------------

  Future<List<CalendarEventModel>> getEventsForUser(int userId) async {
    try {
      return await _isar.calendarEventModels
          .where()
          .userIdEqualTo(userId)
          .sortByStartTime()
          .findAll();
    } catch (e, st) {
      AppLogger.e('Failed to query user events', tag: 'CalendarRepository', error: e, st: st);
      return [];
    }
  }

  Future<List<CalendarEventModel>> getEventsForRange(
    int userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      return await _isar.calendarEventModels
          .where()
          .userIdEqualTo(userId)
          .filter()
          .startTimeLessThan(end)
          .and()
          .endTimeGreaterThan(start)
          .sortByStartTime()
          .findAll();
    } catch (e, st) {
      AppLogger.e('Failed to query range events', tag: 'CalendarRepository', error: e, st: st);
      return [];
    }
  }

  Future<List<CalendarEventModel>> searchEvents(int userId, String query) async {
    try {
      if (query.trim().isEmpty) return [];
      return await _isar.calendarEventModels
          .where()
          .userIdEqualTo(userId)
          .filter()
          .titleContains(query, caseSensitive: false)
          .or()
          .descriptionContains(query, caseSensitive: false)
          .sortByStartTime()
          .findAll();
    } catch (e, st) {
      AppLogger.e('Failed to search events', tag: 'CalendarRepository', error: e, st: st);
      return [];
    }
  }
}
