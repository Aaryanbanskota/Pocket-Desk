import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/chat/services/call_audio_service.dart';
import '../services/notification_service.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool isNotificationEnabled = true;
  static void Function(bool accept, String? payload)? onCallAction;

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('ic_notification');
    const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open MyDay');
    const darwinSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      linux: linuxSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.actionId == 'action_accept_call') {
            onCallAction?.call(true, response.payload);
          } else if (response.actionId == 'action_decline_call') {
            onCallAction?.call(false, response.payload);
          }
        },
      );

      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        try {
          await androidImpl?.requestNotificationsPermission();
          final canExact = await androidImpl?.canScheduleExactNotifications();
          if (canExact == false) {
            await androidImpl?.requestExactAlarmsPermission();
          }
        } catch (_) {}
      }
    } catch (_) {
      // Graceful fallback for non-supported desktop platforms/tests
    }

    try {
      await NotificationService.instance.initialize();
    } catch (_) {}
  }

  /// Request runtime permissions for notifications and exact alarms
  static Future<bool> requestNotificationPermissions() async {
    if (Platform.isAndroid) {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      try {
        final granted = await androidImpl?.requestNotificationsPermission();
        final canExact = await androidImpl?.canScheduleExactNotifications();
        if (canExact == false) {
          await androidImpl?.requestExactAlarmsPermission();
        }
        return (granted ?? false) || (await androidImpl?.areNotificationsEnabled() ?? false);
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  /// Plays the custom ding notification sound (ding.mp3 from Pocketdesk/v2 sound/message)
  static Future<void> playNotificationSound() async {
    try {
      if (!kIsWeb && Platform.isLinux) {
        const candidates = [
          'assets/sounds/ding.mp3',
          'assets/sounds/message_ding.mp3',
          'assets/sounds/notification.mp3',
          '/home/aaryan/Documents/desk/pocketsesk_v2/sound/message/ding.mp3',
        ];

        String soundPath = '';
        for (final candidate in candidates) {
          final file = File(candidate);
          if (file.existsSync()) {
            soundPath = file.absolute.path;
            break;
          }
        }

        if (soundPath.isNotEmpty) {
          try {
            await Process.run('pw-play', [soundPath]);
            return;
          } catch (_) {
            try {
              await Process.run('ffplay', ['-nodisp', '-autoexit', soundPath]);
              return;
            } catch (_) {}
          }
        }
      } else {
        await CallAudioService.instance.playMessageDing();
        return;
      }
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!isNotificationEnabled) return;
    // 1. Play audible ding notification sound
    playNotificationSound();

    // 2. Native Linux desktop notification popup via notify-send
    if (!kIsWeb && Platform.isLinux) {
      try {
        await Process.run('notify-send', [
          '-u',
          'critical',
          '-a',
          'MyDay',
          title,
          body,
        ]);
      } catch (_) {}
    }

    // 3. Plugin notification for Android, iOS, macOS, and Linux
    // Uses pocketdesk_notifications_v3 channel configured with ding.mp3
    const androidDetails = AndroidNotificationDetails(
      'pocketdesk_notifications_v3',
      'MyDay Notifications',
      channelDescription: 'Notifications for messages, reminders and alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('ding'),
    );
    const linuxDetails = LinuxNotificationDetails(
      urgency: LinuxNotificationUrgency.critical,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
      linux: linuxDetails,
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
      );
    } catch (_) {}
  }

  /// Displays high-priority incoming call notification and wakes screen over lock screen like a default call app
  static Future<void> showIncomingCallNotification({
    required String callerName,
    required String callerNumber,
    String? callId,
  }) async {
    if (!isNotificationEnabled) return;

    // Wake physical screen and set flags to show Activity over lock screen on Android
    if (!kIsWeb && Platform.isAndroid) {
      try {
        const MethodChannel('pocketdesk/device')
            .invokeMethod('wakeScreenForIncomingCall')
            .catchError((_) => null);
      } catch (_) {}
    }

    if (!kIsWeb && Platform.isLinux) {
      try {
        await Process.run('notify-send', [
          '-u',
          'critical',
          '-a',
          'MyDay Call',
          '📞 Incoming Call from $callerName',
          '$callerNumber • Tap to open and pick up',
        ]);
      } catch (_) {}
    }

    const androidDetails = AndroidNotificationDetails(
      'pocketdesk_calls_v3',
      'Incoming Calls',
      channelDescription: 'Full-screen heads-up alert and lock screen display for incoming MyDay calls',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.notificationRingtone,
      sound: RawResourceAndroidNotificationSound('classic_phone_ring'),
      ongoing: true,
      autoCancel: false,
      playSound: true,
      actions: [
        AndroidNotificationAction(
          'action_accept_call',
          'Pick Up',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'action_decline_call',
          'End Call',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
      linux: LinuxNotificationDetails(urgency: LinuxNotificationUrgency.critical),
    );

    try {
      await _notificationsPlugin.show(
        9999,
        '📞 Incoming Call: $callerName',
        'Call from $callerNumber • MyDay Call',
        notificationDetails,
        payload: callId,
      );
    } catch (_) {}
  }

  /// Cancels incoming call notification when call is answered or declined
  static Future<void> cancelCallNotification() async {
    if (!isNotificationEnabled) return;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        const MethodChannel('pocketdesk/device')
            .invokeMethod('clearCallWakeFlags')
            .catchError((_) => null);
      } catch (_) {}
    }

    try {
      await _notificationsPlugin.cancel(9999);
    } catch (_) {}
  }
}
