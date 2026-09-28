import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/features/clock/presentation/pages/clock_page.dart';

void main() {
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
