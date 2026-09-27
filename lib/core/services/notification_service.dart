import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../logging/app_logger.dart';
import '../../features/calendar/data/models/calendar_event_model.dart';
import '../../features/tasks/data/models/task_model.dart';

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
      try {
        final String localName = DateTime.now().timeZoneName;
        tz.setLocalLocation(tz.getLocation(localName));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      // 2. Setup initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
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

      // Request Android 13+ permission & Android 12+ exact alarm permission
      final androidImpl = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.requestNotificationsPermission();
        await androidImpl.requestExactAlarmsPermission();
      }

      AppLogger.i('NotificationService initialized: $_isInitialized', tag: 'NotificationService');
    } catch (e, st) {
      AppLogger.e('Failed to initialize NotificationService', tag: 'NotificationService', error: e, st: st);
    }
  }

  /// Shows an instant notification alert (used for alarms and timers on Android & Linux).
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'pocketdesk_alarms_channel',
        'Alarms & Timers',
        channelDescription: 'Alerts for alarms, timers, and countdowns',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        linux: LinuxNotificationDetails(),
      );

      await _notificationsPlugin.show(id, title, body, platformDetails, payload: payload);
    } catch (e, st) {
      AppLogger.e('Failed to show notification', tag: 'NotificationService', error: e, st: st);
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

        // Resolve event's timezone, fallback to local
        tz.Location location;
        try {
          location = tz.getLocation(event.timeZone.isEmpty ? 'UTC' : event.timeZone);
        } catch (_) {
          location = tz.local;
        }

        final tzReminderTime = tz.TZDateTime.from(reminderTime, location);
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

  // --------------------------------------------------------------------------
  // Task notifications
  // --------------------------------------------------------------------------

  /// Cancels all scheduled notifications for a task.
  Future<void> cancelTaskReminder(int taskId) async {
    if (!_isInitialized) await initialize();
    try {
      // Use a dedicated range (offset by 1_000_000) to avoid collision with event IDs.
      for (int i = 0; i < 5; i++) {
        await _notificationsPlugin.cancel(1000000 + (taskId * 10) + i);
      }
    } catch (e, st) {
      AppLogger.e('Failed to cancel task notification: $taskId',
          tag: 'NotificationService', error: e, st: st);
    }
  }

  /// Schedules reminder notifications for a task based on its [dueDate]
  /// and [reminderMinutesRaw] list.
  ///
  /// Each string in [reminderMinutesRaw] is expected to be an integer number
  /// of minutes before [dueDate] to fire the reminder.
  Future<void> scheduleTaskReminder(TaskModel task) async {
    if (!_isInitialized) await initialize();
    await cancelTaskReminder(task.id);

    if (task.dueDate == null || task.reminderMinutesRaw.isEmpty) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pocketdesk_tasks_channel',
      'Task Reminders',
      channelDescription: 'Reminders for upcoming tasks and deadlines',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      linux: LinuxNotificationDetails(),
    );

    final now = DateTime.now();

    try {
      for (int i = 0; i < task.reminderMinutesRaw.length; i++) {
        final minutes = int.tryParse(task.reminderMinutesRaw[i]);
        if (minutes == null) continue;

        final reminderTime = task.dueDate!.subtract(Duration(minutes: minutes));
        if (reminderTime.isBefore(now)) continue;

        final tzReminderTime = tz.TZDateTime.from(reminderTime, tz.local);
        final notificationId = 1000000 + (task.id * 10) + i;

        final label = minutes == 0
            ? 'Task due now'
            : 'Due in $minutes minutes';

        await _notificationsPlugin.zonedSchedule(
          notificationId,
          task.title,
          '${task.description != null ? "${task.description} — " : ""}$label',
          tzReminderTime,
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'task_id=${task.id}',
        );

        AppLogger.d(
          'Scheduled task reminder $i for "${task.title}" at $reminderTime',
          tag: 'NotificationService',
        );
      }
    } catch (e, st) {
      AppLogger.e('Failed to schedule task notifications for "${task.title}"',
          tag: 'NotificationService', error: e, st: st);
    }
  }
}
