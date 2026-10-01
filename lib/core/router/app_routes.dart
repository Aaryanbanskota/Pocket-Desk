/// Centralized route path constants for PocketDesk.
/// All navigation paths are defined here — never hardcode strings elsewhere.
abstract final class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String accountSelector = '/account-select';
  static const String subscriptionPlan = '/subscription-plan';
  static const String login = '/login';
  static const String qrLogin = '/login/qr';
  static const String register = '/register';
  static const String setupOnboarding = '/setup';

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

  // New Modules
  static const String fileShare = '/fileshare';
  static const String posts = '/posts';
  static const String chat = '/chat';
  static const String moneyTracker = '/money';
  static const String clock = '/clock';
  static const String aboutApp = '/about';
  static const String termsAndConditions = '/about/terms-and-conditions';
  static const String privacyPolicy = '/about/privacy-policy';
  static const String licenses = '/about/licenses';
  static const String trash = '/trash';

  // Error
  static const String notFound = '/404';
}
