import 'package:isar/isar.dart';

part 'calendar_event_model.g.dart';

/// Recurrence pattern options for events.
enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
  custom,
}

/// Local calendar event collection stored in Isar.
@collection
class CalendarEventModel {
  CalendarEventModel();

  Id id = Isar.autoIncrement;

  /// User ID who owns this calendar event.
  @Index()
  late int userId;

  /// Title of the event.
  late String title;

  /// Description / notes content.
  String? description;

  /// Venue / virtual link location.
  String? location;

  /// Event start time.
  @Index()
  late DateTime startTime;

  /// Event end time.
  @Index()
  late DateTime endTime;

  /// Whether the event spans the entire day.
  bool isAllDay = false;

  /// Category name / label (e.g. 'Work', 'Personal').
  String? category;

  /// Color hex code (e.g. '0xFF0EA5E9').
  String? colorHex;

  /// Recurrence type for repetitive events.
  @enumerated
  RecurrenceType recurrenceType = RecurrenceType.none;

  /// Recurrence rules (e.g. 'FREQ=WEEKLY;BYDAY=MO,WE,FR' or custom interval configurations).
  String? recurrenceRule;

  /// Time zone string (e.g. 'UTC', 'America/New_York').
  String timeZone = 'UTC';

  /// Reminder offsets in minutes before startTime (e.g. [15, 30, 60]).
  List<int> reminderMinutes = [];

  /// File paths for attached documents or images.
  List<String> attachmentPaths = [];

  /// RFC 3339 timestamp of when the event was created.
  late DateTime createdAt;

  /// RFC 3339 timestamp of when the event was last updated.
  late DateTime updatedAt;

  /// Client device sync state tracker.
  bool isSynced = false;
}
