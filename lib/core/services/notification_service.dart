import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../logging/app_logger.dart';
import '../../features/calendar/data/models/calendar_event_model.dart';
import '../../features/tasks/data/models/task_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  final Map<int, Set<Timer>> _linuxAlarmTimers = {};
  static const _timezoneChannel = MethodChannel('pocketdesk/device');

  Future<bool> _ensureInitialized() async {
    if (!_isInitialized) await initialize();
    return _isInitialized;
  }

  /// Initializes the local notification plugin and configures timezone database.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize timezone database
      tz.initializeTimeZones();
      try {
        final String localName = Platform.isAndroid
            ? (await _timezoneChannel.invokeMethod<String>('localTimezone') ??
                DateTime.now().timeZoneName)
            : DateTime.now().timeZoneName;
        tz.setLocalLocation(tz.getLocation(localName));
      } catch (_) {
        final offset = DateTime.now().timeZoneOffset.inMilliseconds;
        tz.setLocalLocation(
          tz.Location(
            'device-local',
            const [],
            const [],
            [tz.TimeZone(offset, isDst: false, abbreviation: 'local')],
          ),
        );
      }

      // 2. Setup initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(
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
          AppLogger.i('Notification clicked: ${response.payload}',
              tag: 'NotificationService');
        },
      );

      _isInitialized = initialized ?? false;

      AppLogger.i('NotificationService initialized: $_isInitialized',
          tag: 'NotificationService');
    } catch (e, st) {
      AppLogger.e('Failed to initialize NotificationService',
          tag: 'NotificationService', error: e, st: st);
      _isInitialized = false;
    }
  }

  Future<bool> requestNotificationPermission() async {
    if (!await _ensureInitialized()) return false;
    final androidImpl =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return true;

    try {
      await androidImpl.requestNotificationsPermission();
      return await androidImpl.areNotificationsEnabled() ?? false;
    } catch (e, st) {
      AppLogger.w(
        'Notification permission request failed: $e',
        tag: 'NotificationService',
      );
      AppLogger.e('Notification permission request exception',
          tag: 'NotificationService', error: e, st: st);
      return false;
    }
  }

  Future<AndroidScheduleMode> _scheduleMode({
    bool requestExactAlarmAccess = false,
  }) async {
    if (!Platform.isAndroid) return AndroidScheduleMode.inexactAllowWhileIdle;
    final androidImpl =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }

    try {
      var canScheduleExact = await androidImpl.canScheduleExactNotifications();
      if (canScheduleExact != true && requestExactAlarmAccess) {
        await androidImpl.requestExactAlarmsPermission();
        canScheduleExact = await androidImpl.canScheduleExactNotifications();
      }
      if (canScheduleExact != true) {
        AppLogger.w(
          'Exact alarm access is disabled.',
          tag: 'NotificationService',
        );
        return AndroidScheduleMode.inexactAllowWhileIdle;
      }
      return AndroidScheduleMode.exactAllowWhileIdle;
    } catch (e, st) {
      AppLogger.w(
        'Exact alarm permission check failed: $e',
        tag: 'NotificationService',
      );
      AppLogger.e('Exact alarm permission check exception',
          tag: 'NotificationService', error: e, st: st);
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  Future<void> _requestFullScreenAlarmAccess() async {
    if (!Platform.isAndroid) return;
    final androidImpl =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return;
    try {
      final allowed = await androidImpl.requestFullScreenIntentPermission();
      if (allowed != true) {
        AppLogger.w(
          'Full-screen alarm access is disabled; alarms will appear as notifications.',
          tag: 'NotificationService',
        );
      }
    } catch (e, st) {
      AppLogger.e('Full-screen alarm permission request failed',
          tag: 'NotificationService', error: e, st: st);
    }
  }

  Future<bool> scheduleAlarm({
    required int id,
    required String title,
    required String days,
    required int hour,
    required int minute,
  }) async {
    if (!await _ensureInitialized()) return false;
    if (!await requestNotificationPermission()) return false;

    try {
      if (!await cancelAlarm(id)) return false;
      if (Platform.isLinux) {
        _scheduleLinuxAlarmOccurrence(
          id: id,
          title: title,
          days: days,
          hour: hour,
          minute: minute,
        );
        return true;
      }
      if (!Platform.isAndroid) return false;

      final mode = await _scheduleMode(requestExactAlarmAccess: true);
      await _requestFullScreenAlarmAccess();
      final now = DateTime.now();
      final occurrences = days == 'Weekdays'
          ? [
              DateTime.monday,
              DateTime.tuesday,
              DateTime.wednesday,
              DateTime.thursday,
              DateTime.friday
            ]
          : days == 'Weekends'
              ? [DateTime.saturday, DateTime.sunday]
              : days == 'Daily'
                  ? [null]
                  : [0];
      for (final weekday in occurrences) {
        var next = DateTime(now.year, now.month, now.day, hour, minute);
        while (next.isBefore(now) ||
            (weekday != null && weekday > 0 && next.weekday != weekday)) {
          next = next.add(const Duration(days: 1));
        }
        final notificationId = _alarmNotificationId(id, weekday);
        await _notificationsPlugin.zonedSchedule(
          notificationId,
          title,
          'Alarm',
          tz.TZDateTime.from(next, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'pocketdesk_alarms_channel',
              'Alarms & Timers',
              channelDescription: 'Alerts for alarms, timers, and countdowns',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
              fullScreenIntent: true,
            ),
          ),
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: weekday == null
              ? DateTimeComponents.time
              : weekday > 0
                  ? DateTimeComponents.dayOfWeekAndTime
                  : null,
          payload: 'alarm_id=$id',
        );
      }
      return true;
    } catch (e, st) {
      AppLogger.e('Failed to schedule alarm $id',
          tag: 'NotificationService', error: e, st: st);
      return false;
    }
  }

  void _scheduleLinuxAlarmOccurrence({
    required int id,
    required String title,
    required String days,
    required int hour,
    required int minute,
  }) {
    // ponytail: Linux alarms stay in-process; add a system service backend if
    // they must fire after PocketDesk exits.
    final now = DateTime.now();
    final weekdays = switch (days) {
      'Weekdays' => {
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
        },
      'Weekends' => {DateTime.saturday, DateTime.sunday},
      _ => <int>{},
    };
    final repeats = days != 'Once';
    DateTime? occurrence;
    for (var offset = 0; offset <= (repeats ? 7 : 1); offset++) {
      final candidate = DateTime(
        now.year,
        now.month,
        now.day + offset,
        hour,
        minute,
      );
      final matchesDay = days == 'Daily' ||
          (weekdays.isNotEmpty && weekdays.contains(candidate.weekday)) ||
          (!repeats && offset == 0);
      if (candidate.isAfter(now) && matchesDay) {
        occurrence = candidate;
        break;
      }
    }
    if (occurrence == null) return;

    late final Timer timer;
    timer = Timer(occurrence.difference(now), () {
      _linuxAlarmTimers[id]?.remove(timer);
      if (!repeats) _linuxAlarmTimers.remove(id);
      unawaited(() async {
        await showNotification(
          id: _alarmNotificationId(id, null),
          title: title,
          body: 'Alarm',
          payload: 'alarm_id=$id',
        );
        if (repeats) {
          _scheduleLinuxAlarmOccurrence(
            id: id,
            title: title,
            days: days,
            hour: hour,
            minute: minute,
          );
        }
      }());
    });
    (_linuxAlarmTimers[id] ??= <Timer>{}).add(timer);
  }

  Future<bool> cancelAlarm(int id) async {
    if (!await _ensureInitialized()) return false;
    try {
      if (Platform.isLinux) {
        for (final timer in _linuxAlarmTimers.remove(id) ?? <Timer>{}) {
          timer.cancel();
        }
        await _notificationsPlugin.cancel(_alarmNotificationId(id, null));
        return true;
      }
      for (var weekday = 0; weekday <= 8; weekday++) {
        await _notificationsPlugin.cancel(_alarmNotificationId(
          id,
          weekday == 8 ? null : weekday,
        ));
      }
      return true;
    } catch (e, st) {
      AppLogger.e('Failed to cancel alarm $id',
          tag: 'NotificationService', error: e, st: st);
      return false;
    }
  }

  Future<bool> scheduleTimer({
    required int id,
    required Duration duration,
  }) async {
    if (!Platform.isAndroid) return true;
    if (!await _ensureInitialized()) return false;
    if (!await requestNotificationPermission()) return false;
    final mode = await _scheduleMode(requestExactAlarmAccess: true);
    try {
      if (!await cancelTimer(id)) return false;
      await _notificationsPlugin.zonedSchedule(
        id,
        'Timer finished',
        'Your countdown timer has ended.',
        tz.TZDateTime.now(tz.local).add(duration),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'pocketdesk_alarms_channel',
            'Alarms & Timers',
            channelDescription: 'Alerts for alarms, timers, and countdowns',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return true;
    } catch (e, st) {
      AppLogger.e('Failed to schedule timer notification',
          tag: 'NotificationService', error: e, st: st);
      return false;
    }
  }

  Future<bool> cancelTimer(int id) async {
    if (!await _ensureInitialized()) return false;
    try {
      await _notificationsPlugin.cancel(id);
      return true;
    } catch (e, st) {
      AppLogger.e('Failed to cancel timer $id',
          tag: 'NotificationService', error: e, st: st);
      return false;
    }
  }

  int _alarmNotificationId(int id, int? weekday) =>
      2000000 + id * 10 + (weekday ?? 8);

  /// Shows an instant notification alert (used for alarms and timers on Android & Linux).
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!await _ensureInitialized()) return;
    if (!await requestNotificationPermission()) {
      AppLogger.w(
        'Notification permission denied; "$title" was not shown.',
        tag: 'NotificationService',
      );
      return;
    }
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
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

      await _notificationsPlugin.show(id, title, body, platformDetails,
          payload: payload);
    } catch (e, st) {
      AppLogger.e('Failed to show notification',
          tag: 'NotificationService', error: e, st: st);
    }
  }

  /// Cancels all scheduled notifications for a specific event.
  Future<void> cancelEventReminders(int eventId) async {
    if (!await _ensureInitialized()) return;

    try {
      // Up to 5 reminders per event
      for (int i = 0; i < 5; i++) {
        final notificationId = _generateNotificationId(eventId, i);
        await _notificationsPlugin.cancel(notificationId);
      }
      AppLogger.d('Cancelled notifications for event ID: $eventId',
          tag: 'NotificationService');
    } catch (e, st) {
      AppLogger.e('Failed to cancel notifications for event ID: $eventId',
          tag: 'NotificationService', error: e, st: st);
    }
  }

  /// Schedules notifications for an event based on its reminderMinutes settings.
  Future<void> scheduleEventReminders(CalendarEventModel event) async {
    if (!await _ensureInitialized()) return;

    // First cancel any existing reminders for this event
    await cancelEventReminders(event.id);

    if (event.reminderMinutes.isEmpty) return;
    if (!await requestNotificationPermission()) {
      AppLogger.w(
        'Notification permission denied; reminders for "${event.title}" were not scheduled.',
        tag: 'NotificationService',
      );
      return;
    }

    try {
      final scheduleMode = await _scheduleMode();
      final now = DateTime.now();

      // Setup Android notification channel details
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
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
        final reminderTime =
            event.startTime.subtract(Duration(minutes: minutesBefore));

        if (reminderTime.isBefore(now)) {
          // Skip if the reminder time is in the past
          continue;
        }

        // Resolve event's timezone, fallback to local
        tz.Location location;
        try {
          location =
              tz.getLocation(event.timeZone.isEmpty ? 'UTC' : event.timeZone);
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
          androidScheduleMode: scheduleMode,
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
      AppLogger.e('Failed to schedule notifications for event "${event.title}"',
          tag: 'NotificationService', error: e, st: st);
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
    if (!await _ensureInitialized()) return;
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
    if (!await _ensureInitialized()) return;
    await cancelTaskReminder(task.id);

    if (task.dueDate == null || task.reminderMinutesRaw.isEmpty) return;
    if (!await requestNotificationPermission()) {
      AppLogger.w(
        'Notification permission denied; reminder for "${task.title}" was not scheduled.',
        tag: 'NotificationService',
      );
      return;
    }

    final scheduleMode = await _scheduleMode();
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
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

        final label = minutes == 0 ? 'Task due now' : 'Due in $minutes minutes';

        await _notificationsPlugin.zonedSchedule(
          notificationId,
          task.title,
          '${task.description != null ? "${task.description} — " : ""}$label',
          tzReminderTime,
          platformDetails,
          androidScheduleMode: scheduleMode,
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
