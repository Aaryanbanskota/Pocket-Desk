import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/features/calendar/data/models/calendar_event_model.dart';
import 'package:pocketdesk/core/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService Tests', () {
    test('initialization runs successfully or logs cleanly', () async {
      final service = NotificationService.instance;
      // Should not throw or crash even in test environment (will log initialization details)
      await service.initialize();
    });

    test('cancelEventReminders does not throw error in unit test context', () async {
      final service = NotificationService.instance;
      expect(() => service.cancelEventReminders(123), returnsNormally);
    });

    test('scheduleEventReminders does not crash on empty reminder list', () async {
      final service = NotificationService.instance;
      final event = CalendarEventModel()
        ..id = 99
        ..title = 'Silent Event'
        ..startTime = DateTime.now().add(const Duration(hours: 1))
        ..endTime = DateTime.now().add(const Duration(hours: 2))
        ..reminderMinutes = [];

      expect(() => service.scheduleEventReminders(event), returnsNormally);
    });

    test('scheduleEventReminders skips past reminders cleanly', () async {
      final service = NotificationService.instance;
      final event = CalendarEventModel()
        ..id = 100
        ..title = 'Past Event'
        ..startTime = DateTime.now().subtract(const Duration(minutes: 30))
        ..endTime = DateTime.now().add(const Duration(hours: 1))
        ..reminderMinutes = [15, 30, 45]; // 15 mins ago, 30 mins ago, 45 mins ago (all in past)

      expect(() => service.scheduleEventReminders(event), returnsNormally);
    });
  });
}
