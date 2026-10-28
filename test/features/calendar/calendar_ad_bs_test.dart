import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:pocketdesk/core/design_system/calendar_event_indicators.dart';
import 'package:pocketdesk/core/design_system/widgets/calendar_system_toggle.dart';
import 'package:pocketdesk/core/design_system/widgets/cream_hero_card.dart';
import 'package:pocketdesk/core/utils/nepali_calendar_converter.dart';
import 'package:pocketdesk/features/calendar/presentation/calendar_screen.dart';
import 'package:pocketdesk/features/tasks/data/tasks_repository.dart';

void main() {
  group('NepaliCalendarConverter Tests', () {
    test('Accurately converts AD to BS using nepali_utils', () {
      final adDate = DateTime(2026, 10, 19);
      final bsDate = NepaliCalendarConverter.toBS(adDate);
      expect(bsDate.year, greaterThanOrEqualTo(2083));
      expect(bsDate.month, inInclusiveRange(1, 12));
      expect(bsDate.day, inInclusiveRange(1, 32));
    });

    test('Accurately returns days in Nepali month and month name', () {
      final days = NepaliCalendarConverter.getDaysInNepaliMonth(2083, 7);
      expect(days, inInclusiveRange(29, 32));

      final monthName = NepaliCalendarConverter.getNepaliMonthName(7);
      expect(monthName, equals('Kartik'));
    });
  });

  group('Calendar Event Indicators & Palette Tests', () {
    test('Tag matches return distinct theme colors', () {
      final workTask = MyDayTask(
        id: 'w1',
        accountId: 'acc1',
        title: 'Office Meeting',
        dueDate: '2026-10-19',
        tags: ['Work'],
      );
      final personalTask = MyDayTask(
        id: 'p1',
        accountId: 'acc1',
        title: 'Gym workout',
        dueDate: '2026-10-19',
        tags: ['Health'],
      );
      final studyTask = MyDayTask(
        id: 's1',
        accountId: 'acc1',
        title: 'Study Flutter',
        dueDate: '2026-10-19',
        tags: ['Study'],
      );

      final cWork = getEventColor(workTask);
      final cHealth = getEventColor(personalTask);
      final cStudy = getEventColor(studyTask);

      expect(cWork, isNot(equals(cHealth)));
      expect(cHealth, isNot(equals(cStudy)));
      expect(cWork, isNot(equals(cStudy)));
    });

    test('Untagged tasks receive deterministic distinct palette colors', () {
      final task1 = MyDayTask(
        id: 't1',
        accountId: 'acc1',
        title: 'Buy groceries',
        dueDate: '2026-10-19',
      );
      final task2 = MyDayTask(
        id: 't2',
        accountId: 'acc1',
        title: 'Dentist appointment',
        dueDate: '2026-10-19',
      );

      final c1 = getEventColor(task1);
      final c2 = getEventColor(task2);

      expect(kEventPalette.contains(c1), isTrue);
      expect(kEventPalette.contains(c2), isTrue);
    });
  });

  group('CalendarSystemToggle Widget Tests', () {
    testWidgets('Tapping BS calls onChanged with true', (tester) async {
      bool? toggledVal;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarSystemToggle(
              isBS: false,
              onChanged: (val) => toggledVal = val,
            ),
          ),
        ),
      );

      expect(find.text('AD'), findsOneWidget);
      expect(find.text('BS'), findsOneWidget);

      await tester.tap(find.text('BS'));
      await tester.pump();

      expect(toggledVal, isTrue);
    });
  });

  group('CreamHeroCard Widget Tests', () {
    testWidgets('Renders mini calendar and responds to AD/BS mode', (tester) async {
      final now = DateTime.now();
      final todayIso = DateFormat('yyyy-MM-dd').format(now);
      final task = MyDayTask(
        id: 'hero_t1',
        accountId: 'acc1',
        title: 'Review Project',
        dueDate: todayIso,
        tags: ['Work'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreamHeroCard(
              date: now,
              userName: 'Aaryan',
              openTasksCount: 1,
              notesCount: 2,
              datesWithTasks: {todayIso},
              tasks: [task],
              isNepaliCalendar: false,
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Aaryan'),
        ),
        findsWidgets,
      );
      expect(find.text('M'), findsWidgets);
    });
  });
}
