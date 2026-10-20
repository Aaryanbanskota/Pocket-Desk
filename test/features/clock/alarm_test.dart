import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/features/clock/presentation/clock_screen.dart';

void main() {
  group('Alarm & Reminders Tests', () {
    test('AlarmItem formats time and repeat days accurately', () {
      const alarm1 = AlarmItem(
        id: '1',
        hour: 7,
        minute: 0,
        label: 'Morning Wakeup',
        repeatDays: [1, 2, 3, 4, 5],
      );

      expect(alarm1.timeFormatted, '7:00 AM');
      expect(alarm1.repeatFormatted, 'Weekdays (Mon - Fri)');

      const alarm2 = AlarmItem(
        id: '2',
        hour: 14,
        minute: 30,
        label: 'Team Sync',
        repeatDays: [],
      );

      expect(alarm2.timeFormatted, '2:30 PM');
      expect(alarm2.repeatFormatted, 'Once / Today');

      const alarm3 = AlarmItem(
        id: '3',
        hour: 0,
        minute: 15,
        label: 'Midnight Reminder',
        repeatDays: [1, 2, 3, 4, 5, 6, 7],
      );

      expect(alarm3.timeFormatted, '12:15 AM');
      expect(alarm3.repeatFormatted, 'Everyday');
    });

    test('AlarmItem serialization and deserialization work', () {
      const original = AlarmItem(
        id: 'test_123',
        hour: 9,
        minute: 45,
        label: 'Standup Reminder',
        isEnabled: true,
        repeatDays: [1, 3, 5],
      );

      final json = original.toJson();
      final reconstructed = AlarmItem.fromJson(json);

      expect(reconstructed.id, original.id);
      expect(reconstructed.hour, original.hour);
      expect(reconstructed.minute, original.minute);
      expect(reconstructed.label, original.label);
      expect(reconstructed.isEnabled, original.isEnabled);
      expect(reconstructed.repeatDays, original.repeatDays);
    });

    testWidgets('ClockScreen renders Clock, Alarm, Stopwatch, and Timer tabs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClockScreen(),
          ),
        ),
      );

      expect(find.text('Clock'), findsOneWidget);
      expect(find.text('Alarm & Reminders'), findsOneWidget);
      expect(find.text('Stopwatch'), findsOneWidget);
      expect(find.text('Timer'), findsOneWidget);

      // Tap on Alarm tab
      await tester.tap(find.text('Alarm & Reminders'));
      await tester.pumpAndSettle();

      expect(find.text('Alarms & Reminders'), findsOneWidget);
      expect(find.text('Add Alarm'), findsOneWidget);
    });
  });
}
