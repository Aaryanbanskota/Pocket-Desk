import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/features/calendar/data/models/calendar_event_model.dart';
import 'package:pocketdesk/features/calendar/data/models/recurrence_engine.dart';

void main() {
  group('RecurrenceEngine Tests', () {
    late CalendarEventModel baseEvent;

    setUp(() {
      baseEvent = CalendarEventModel()
        ..id = 1
        ..userId = 42
        ..title = 'Test Event'
        ..startTime = DateTime(2026, 7, 20, 10, 0) // Mon
        ..endTime = DateTime(2026, 7, 20, 11, 0)
        ..recurrenceType = RecurrenceType.none
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();
    });

    test('no recurrence returns single instance within range', () {
      final rangeStart = DateTime(2026, 7, 20, 0, 0);
      final rangeEnd = DateTime(2026, 7, 21, 0, 0);

      final instances = RecurrenceEngine.expandEvents([baseEvent], rangeStart, rangeEnd);
      expect(instances.length, equals(1));
      expect(instances.first.startTime, equals(baseEvent.startTime));
    });

    test('daily recurrence generates daily instances within range', () {
      baseEvent.recurrenceType = RecurrenceType.daily;

      final rangeStart = DateTime(2026, 7, 20, 0, 0);
      final rangeEnd = DateTime(2026, 7, 25, 0, 0); // 5 days (20, 21, 22, 23, 24)

      final instances = RecurrenceEngine.expandEvents([baseEvent], rangeStart, rangeEnd);
      expect(instances.length, equals(5));
      expect(instances[0].startTime, equals(DateTime(2026, 7, 20, 10, 0)));
      expect(instances[1].startTime, equals(DateTime(2026, 7, 21, 10, 0)));
      expect(instances[4].startTime, equals(DateTime(2026, 7, 24, 10, 0)));
    });

    test('weekly recurrence generates weekly instances within range', () {
      baseEvent.recurrenceType = RecurrenceType.weekly;

      final rangeStart = DateTime(2026, 7, 20, 0, 0);
      final rangeEnd = DateTime(2026, 8, 10, 0, 0); // ~3 weeks (July 20, 27, Aug 3)

      final instances = RecurrenceEngine.expandEvents([baseEvent], rangeStart, rangeEnd);
      expect(instances.length, equals(3));
      expect(instances[0].startTime, equals(DateTime(2026, 7, 20, 10, 0)));
      expect(instances[1].startTime, equals(DateTime(2026, 7, 27, 10, 0)));
      expect(instances[2].startTime, equals(DateTime(2026, 8, 3, 10, 0)));
    });

    test('monthly recurrence generates monthly instances within range', () {
      baseEvent.recurrenceType = RecurrenceType.monthly;

      final rangeStart = DateTime(2026, 7, 1, 0, 0);
      final rangeEnd = DateTime(2026, 10, 1, 0, 0); // July, Aug, Sept

      final instances = RecurrenceEngine.expandEvents([baseEvent], rangeStart, rangeEnd);
      expect(instances.length, equals(3));
      expect(instances[0].startTime, equals(DateTime(2026, 7, 20, 10, 0)));
      expect(instances[1].startTime, equals(DateTime(2026, 8, 20, 10, 0)));
      expect(instances[2].startTime, equals(DateTime(2026, 9, 20, 10, 0)));
    });

    test('custom weekly recurrence with specific days generates instances correctly', () {
      baseEvent.recurrenceType = RecurrenceType.custom;
      baseEvent.recurrenceRule = 'FREQ=WEEKLY;BYDAY=MO,WE,FR;INTERVAL=1';

      final rangeStart = DateTime(2026, 7, 20, 0, 0);
      final rangeEnd = DateTime(2026, 7, 27, 0, 0); // 1 week starting July 20 (Mon) to July 26 (Sun)

      final instances = RecurrenceEngine.expandEvents([baseEvent], rangeStart, rangeEnd);
      
      // Expected instances: Mon July 20, Wed July 22, Fri July 24
      expect(instances.length, equals(3));
      expect(instances[0].startTime, equals(DateTime(2026, 7, 20, 10, 0)));
      expect(instances[1].startTime, equals(DateTime(2026, 7, 22, 10, 0)));
      expect(instances[2].startTime, equals(DateTime(2026, 7, 24, 10, 0)));
    });
  });
}
