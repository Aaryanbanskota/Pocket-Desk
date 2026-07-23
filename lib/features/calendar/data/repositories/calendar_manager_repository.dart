import 'package:isar/isar.dart';
import '../models/calendar_model.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/logging/app_logger.dart';

class CalendarRepository {
  CalendarRepository({required Isar isar}) : _isar = isar;
  final Isar _isar;

  Future<List<CalendarModel>> getCalendarsForUser(int userId) async {
    try {
      return await _isar.calendarModels
          .where()
          .userIdEqualTo(userId)
          .findAll();
    } catch (e, st) {
      AppLogger.e('Failed to fetch calendars', tag: 'CalendarRepo', error: e, st: st);
      return [];
    }
  }

  Future<AppFailure?> saveCalendar(CalendarModel cal) async {
    try {
      final now = DateTime.now();
      cal.updatedAt = now;
      if (cal.id == Isar.autoIncrement) cal.createdAt = now;
      await _isar.writeTxn(() => _isar.calendarModels.put(cal));
      return null;
    } catch (e, st) {
      return UnexpectedFailure('Failed to save calendar', error: e, stackTrace: st);
    }
  }

  Future<AppFailure?> deleteCalendar(int calendarId) async {
    try {
      await _isar.writeTxn(() => _isar.calendarModels.delete(calendarId));
      return null;
    } catch (e, st) {
      return UnexpectedFailure('Failed to delete calendar', error: e, stackTrace: st);
    }
  }

  /// Ensures a user always has a default calendar.
  Future<CalendarModel> ensureDefaultCalendar(int userId) async {
    final existing = await _isar.calendarModels
        .where()
        .userIdEqualTo(userId)
        .findFirst();
    if (existing != null) return existing;

    final defaultCal = CalendarModel()
      ..userId = userId
      ..name = 'My Calendar'
      ..colorHex = '0xFF0EA5E9'
      ..isDefault = true
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.calendarModels.put(defaultCal));
    return defaultCal;
  }
}
