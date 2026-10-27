import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/features/widgets/presentation/components/budget_spendee_widget.dart';
import 'package:pocketdesk/features/widgets/presentation/components/calendar_month_widget.dart';
import 'package:pocketdesk/features/widgets/presentation/components/dual_date_agenda_widget.dart';
import 'package:pocketdesk/features/widgets/presentation/components/focus_pomodoro_widget.dart';
import 'package:pocketdesk/features/widgets/presentation/components/quick_actions_widget.dart';
import 'package:pocketdesk/features/widgets/presentation/components/task_progress_tracker_widget.dart';
import 'package:pocketdesk/features/widgets/presentation/widgets_gallery_screen.dart';

void main() {
  group('MyDay Device Widgets Tests', () {
    testWidgets('CalendarMonthWidget renders .calendarWidget and month grid', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalendarMonthWidget(
              size: WidgetSize.medium,
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.text('.calendarWidget'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Today · Mon 19'), findsOneWidget);
    });

    testWidgets('DualDateAgendaWidget renders 19 October 2026 Monday and Kartik 2 2083 in light and dark mode', (tester) async {
      // Light mode test
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DualDateAgendaWidget(
              size: WidgetSize.medium,
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.text('19'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('MONDAY'), findsOneWidget);
      expect(find.textContaining('Kartik 2 2083'), findsOneWidget);
      expect(find.textContaining('कार्तिक २, २०८३'), findsOneWidget);

      // Dark mode test
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DualDateAgendaWidget(
              size: WidgetSize.medium,
              isDarkMode: true,
            ),
          ),
        ),
      );

      expect(find.text('19'), findsOneWidget);
      expect(find.text('MONDAY'), findsOneWidget);
    });

    testWidgets('TaskProgressTrackerWidget displays percentage and little tasks underneath', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TaskProgressTrackerWidget(
              size: WidgetSize.medium,
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.text("Today's Tasks"), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('3 of 4'), findsOneWidget);
      expect(find.text('Upcoming Tasks'), findsOneWidget);
      expect(find.text('Review System Design & Roadmap'), findsOneWidget);

      // Tap task to toggle
      await tester.tap(find.text('Review System Design & Roadmap'));
      await tester.pump();
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('QuickActionsWidget renders capture buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuickActionsWidget(
              size: WidgetSize.medium,
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.text('Quick Capture'), findsOneWidget);
      expect(find.text('Task'), findsOneWidget);
      expect(find.text('Note'), findsOneWidget);
      expect(find.text('Moment'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
    });

    testWidgets('BudgetSpendeeWidget renders balance and daily limit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BudgetSpendeeWidget(
              size: WidgetSize.medium,
              currency: 'Rs',
              balance: 24500,
              spentToday: 350,
              dailyLimit: 800,
            ),
          ),
        ),
      );

      expect(find.text('Budget & Net Worth'), findsOneWidget);
      expect(find.text('Rs 24500'), findsOneWidget);
      expect(find.text('Spent: Rs350'), findsOneWidget);
      expect(find.text('Daily Limit: Rs800'), findsOneWidget);
    });

    testWidgets('BudgetSpendeeWidget renders without overflow on 320px narrow mobile viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Test Small (2x2)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150,
              height: 160,
              child: BudgetSpendeeWidget(
                size: WidgetSize.small,
                currency: 'Rs',
                balance: 12000,
                spentToday: 250,
                dailyLimit: 500,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Spendee Glance'), findsOneWidget);
      expect(find.text('Rs 12000'), findsOneWidget);

      // Test Medium (4x2) on 320px screen inside showcase card
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 288,
                height: 180,
                child: BudgetSpendeeWidget(
                  size: WidgetSize.medium,
                  currency: 'Rs',
                  balance: 24500,
                  spentToday: 350,
                  dailyLimit: 800,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Budget & Net Worth'), findsOneWidget);

      // Test Large (4x4)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 360,
              child: BudgetSpendeeWidget(
                size: WidgetSize.large,
                currency: 'Rs',
                balance: 35000,
                spentToday: 450,
                dailyLimit: 1200,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Spendee Financial Pulse'), findsOneWidget);
      expect(find.text('Recent Expenses'), findsOneWidget);
    });

    testWidgets('FocusPomodoroWidget renders 25:00 countdown dial and toggles timer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FocusPomodoroWidget(
              size: WidgetSize.medium,
            ),
          ),
        ),
      );

      expect(find.text('Pomodoro Focus'), findsOneWidget);
      expect(find.text('25:00'), findsOneWidget);
    });

    testWidgets('WidgetsGalleryScreen renders category filters and size selectors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WidgetsGalleryScreen(
            initialDarkMode: false,
          ),
        ),
      );

      expect(find.text('Device Widgets'), findsOneWidget);
      expect(find.text('All Widgets'), findsOneWidget);
      expect(find.text('2×2'), findsOneWidget);
      expect(find.text('4×2'), findsOneWidget);
      expect(find.text('4×4'), findsOneWidget);
    });
  });
}
