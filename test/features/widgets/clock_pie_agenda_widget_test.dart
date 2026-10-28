import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/features/widgets/presentation/components/calendar_month_widget.dart';
import 'package:pocketdesk/features/widgets/presentation/components/clock_pie_agenda_widget.dart';

void main() {
  group('ClockPieAgendaWidget ("Day Dial") Tests', () {
    test('ClockPieTaskItem calculates start, end, and duration minutes correctly', () {
      const item = ClockPieTaskItem(
        id: 'task_1',
        title: 'Architecture Review',
        startTime: TimeOfDay(hour: 9, minute: 30),
        endTime: TimeOfDay(hour: 11, minute: 0),
        color: Color(0xFF6366F1),
        category: 'Focus',
      );

      expect(item.startMinutes, 9 * 60 + 30);
      expect(item.endMinutes, 11 * 60);
      expect(item.durationMinutes, 90);
      expect(item.timeFormatted, '9:30 AM – 11:00 AM');
    });

    test('ClockPieTaskItem detects whether current time falls within its schedule', () {
      const item = ClockPieTaskItem(
        id: 'task_2',
        title: 'Team Standup',
        startTime: TimeOfDay(hour: 10, minute: 0),
        endTime: TimeOfDay(hour: 11, minute: 0),
        color: Color(0xFF06B6D4),
      );

      final during = DateTime(2026, 10, 22, 10, 30);
      final before = DateTime(2026, 10, 22, 9, 45);
      final after = DateTime(2026, 10, 22, 11, 15);

      expect(item.isCurrent(during), isTrue);
      expect(item.isCurrent(before), isFalse);
      expect(item.isCurrent(after), isFalse);
    });

    testWidgets('Renders Small (2x2) ClockPieAgendaWidget without overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 170,
              height: 170,
              child: ClockPieAgendaWidget(
                size: WidgetSize.small,
                isDarkMode: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('DAY DIAL'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Renders Medium (4x2) ClockPieAgendaWidget with schedule feed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 200,
              child: ClockPieAgendaWidget(
                size: WidgetSize.medium,
                isDarkMode: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('DAY DIAL'), findsOneWidget);
      expect(find.text("Today's Schedule"), findsOneWidget);
      expect(find.textContaining('Tasks'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Renders Large (4x4) ClockPieAgendaWidget with prominent dial and card', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 380,
              child: ClockPieAgendaWidget(
                size: WidgetSize.large,
                isDarkMode: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Day Dial Agenda'), findsOneWidget);
      expect(find.text('Live 12-Hour Pie Chart Schedule'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
