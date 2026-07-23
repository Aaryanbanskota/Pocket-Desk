import 'package:isar/isar.dart';

part 'calendar_model.g.dart';

/// A named calendar (e.g. "Work", "Personal", "Family").
@collection
class CalendarModel {
  CalendarModel();

  Id id = Isar.autoIncrement;

  /// Owner user ID.
  @Index()
  late int userId;

  /// Display name of the calendar.
  late String name;

  /// Color hex string for the calendar badge.
  String colorHex = '0xFF0EA5E9';

  /// Whether this calendar is visible in views.
  bool isVisible = true;

  /// Whether this is the default calendar for new events.
  bool isDefault = false;

  late DateTime createdAt;
  late DateTime updatedAt;
}
