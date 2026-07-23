/// Centralized route path constants for PocketDesk.
/// All navigation paths are defined here — never hardcode strings elsewhere.
abstract final class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Main shell
  static const String dashboard = '/dashboard';

  // Calendar
  static const String calendar = '/calendar';
  static const String calendarEventCreate = '/calendar/event/create';
  static const String calendarEventEdit = '/calendar/event/:eventId';

  // Tasks
  static const String tasks = '/tasks';
  static const String taskDetail = '/tasks/:taskId';

  // Notes
  static const String notes = '/notes';
  static const String noteDetail = '/notes/:noteId';
  static const String noteCreate = '/notes/create';

  // Settings
  static const String settings = '/settings';
  static const String settingsProfile = '/settings/profile';
  static const String settingsDevices = '/settings/devices';
  static const String settingsQrPair = '/settings/devices/pair';

  // Error
  static const String notFound = '/404';
}
