import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/features/clock/presentation/pages/clock_page.dart';

void main() {
  testWidgets('clock switches between digital and analog displays',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ClockPage()),
      ),
    );

    await tester.tap(find.text('Analog'));
    await tester.pump();
    expect(
      find.bySemanticsLabel(RegExp('Analog clock showing')),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Digital'));
    await tester.tap(find.text('Digital'));
    await tester.pump();
    expect(
      find.bySemanticsLabel(RegExp('Analog clock showing')),
      findsNothing,
    );
  });

  test('alarm snooze duration defaults for existing saved alarms', () {
    final alarm = AlarmItem.fromJson({
      'id': 42,
      'hour': 7,
      'minute': 30,
      'label': 'Wake up',
      'days': 'Weekdays',
      'isEnabled': true,
    });

    expect(alarm.snoozeMinutes, 10);
  });

  test('alarm snooze duration is saved and restored', () {
    final alarm = AlarmItem(
      id: 42,
      time: const TimeOfDay(hour: 7, minute: 30),
      label: 'Wake up',
      days: 'Weekdays',
      snoozeMinutes: 15,
    );

    final restored = AlarmItem.fromJson(alarm.toJson());

    expect(restored.snoozeMinutes, 15);
  });
}
