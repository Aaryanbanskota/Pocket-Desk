import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../logging/app_logger.dart';
import '../../features/calendar/data/models/calendar_event_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initializes the local notification plugin and configures timezone database.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize timezone database
      tz.initializeTimeZones();
      // Set default local location to UTC for safety, or local if available
      tz.setLocalLocation(tz.getLocation('UTC'));

      // 2. Setup initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: null, // Add iOS configs if needed in future specs
        macOS: null,
        linux: LinuxInitializationSettings(
          defaultActionName: 'Open',
        ),
      );

      // 3. Initialize plugin
      final bool? initialized = await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          AppLogger.i('Notification clicked: ${response.payload}', tag: 'NotificationService');
        },
      );

      _isInitialized = initialized ?? false;
      AppLogger.i('NotificationService initialized: $_isInitialized', tag: 'NotificationService');
    } catch (e, st) {
      AppLogger.e('Failed to initialize NotificationService', tag: 'NotificationService', error: e, st: st);
    }
  }

  /// Cancels all scheduled notifications for a specific event.
  Future<void> cancelEventReminders(int eventId) async {
    if (!_isInitialized) await initialize();

    try {
      // Up to 5 reminders per event
      for (int i = 0; i < 5; i++) {
        final notificationId = _generateNotificationId(eventId, i);
        await _notificationsPlugin.cancel(notificationId);
      }
      AppLogger.d('Cancelled notifications for event ID: $eventId', tag: 'NotificationService');
    } catch (e, st) {
      AppLogger.e('Failed to cancel notifications for event ID: $eventId', tag: 'NotificationService', error: e, st: st);
    }
  }

  /// Schedules notifications for an event based on its reminderMinutes settings.
  Future<void> scheduleEventReminders(CalendarEventModel event) async {
    if (!_isInitialized) await initialize();

    // First cancel any existing reminders for this event
    await cancelEventReminders(event.id);

    if (event.reminderMinutes.isEmpty) return;

    try {
      final now = DateTime.now();

      // Setup Android notification channel details
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'pocketdesk_calendar_channel',
        'Calendar Events',
        channelDescription: 'Reminders and notifications for calendar events',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        linux: LinuxNotificationDetails(),
      );

      for (int i = 0; i < event.reminderMinutes.length; i++) {
        final minutesBefore = event.reminderMinutes[i];
        final reminderTime = event.startTime.subtract(Duration(minutes: minutesBefore));

        if (reminderTime.isBefore(now)) {
          // Skip if the reminder time is in the past
          continue;
        }

        final tzReminderTime = tz.TZDateTime.from(reminderTime, tz.local);
        final notificationId = _generateNotificationId(event.id, i);

        final label = minutesBefore == 0
            ? 'Event starting now'
            : 'Starting in $minutesBefore minutes';

        await _notificationsPlugin.zonedSchedule(
          notificationId,
          event.title,
          '${event.location != null ? "@ ${event.location} - " : ""}$label',
          tzReminderTime,
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'event_id=${event.id}',
        );

        AppLogger.d(
          'Scheduled reminder $i for event "${event.title}" at $reminderTime (ID: $notificationId)',
          tag: 'NotificationService',
        );
      }
    } catch (e, st) {
      AppLogger.e('Failed to schedule notifications for event "${event.title}"', tag: 'NotificationService', error: e, st: st);
    }
  }

  /// Generates a unique integer notification ID for an event's reminder.
  int _generateNotificationId(int eventId, int reminderIndex) {
    // Unique ID combining eventId and reminderIndex.
    // Assuming eventId is a small integer, we offset it.
    return (eventId * 10) + reminderIndex;
  }
}
