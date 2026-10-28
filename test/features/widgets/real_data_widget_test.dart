import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/core/database/myday_database.dart';
import 'package:pocketdesk/core/widgets/widget_data_sync_service.dart';
import 'package:pocketdesk/features/tasks/data/tasks_repository.dart';
import 'package:pocketdesk/features/widgets/presentation/components/calendar_month_widget.dart';
import 'package:pocketdesk/features/widgets/presentation/components/dual_date_agenda_widget.dart';
import 'package:pocketdesk/features/widgets/presentation/components/task_progress_tracker_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Real User Data in Widgets Tests', () {
    testWidgets('TaskProgressTrackerWidget displays user added tasks directly', (tester) async {
      final userTasks = [
        const WidgetTaskItem(
          id: 'user_task_1',
          title: 'Prepare Quarterly Budget Report',
          isDone: false,
          priority: 'high',
          time: '11:00 AM',
        ),
        const WidgetTaskItem(
          id: 'user_task_2',
          title: 'Deploy Production Release v2.4',
          isDone: true,
          priority: 'medium',
          time: '04:00 PM',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TaskProgressTrackerWidget(
              size: WidgetSize.medium,
              isDarkMode: false,
              tasks: userTasks,
            ),
          ),
        ),
      );

      // Verify the user's REAL task titles and times appear directly on the widget
      expect(find.text('Prepare Quarterly Budget Report'), findsOneWidget);
      expect(find.text('Deploy Production Release v2.4'), findsOneWidget);
      expect(find.text('11:00 AM'), findsOneWidget);
      expect(find.text('04:00 PM'), findsOneWidget);
    });

    testWidgets('DualDateAgendaWidget displays user added events directly without hardcoded text', (tester) async {
      final userEvents = [
        const WidgetAgendaItem(
          id: 'user_event_1',
          title: 'Quarterly Strategy Review with Team',
          time: '10:30 AM – 11:45 AM',
          isDone: false,
        ),
        const WidgetAgendaItem(
          id: 'user_event_2',
          title: 'Client Product Walkthrough',
          time: '02:00 PM – 03:00 PM',
          isDone: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DualDateAgendaWidget(
              size: WidgetSize.medium,
              isDarkMode: true,
              currentDate: DateTime(2026, 10, 22),
              events: userEvents,
            ),
          ),
        ),
      );

      // Verify user's actual events appear
      expect(find.text('Quarterly Strategy Review with Team'), findsOneWidget);
      expect(find.text('Client Product Walkthrough'), findsOneWidget);
      expect(find.text('10:30 AM – 11:45 AM'), findsOneWidget);
      expect(find.text('02:00 PM – 03:00 PM'), findsOneWidget);

      // Verify no hardcoded placeholder items appear
      expect(find.text('Review System Design'), findsNothing);
      expect(find.text('Spendee Financial Sync'), findsNothing);
      expect(find.text('Gym & Cardio Session'), findsNothing);
    });

    test('WidgetDataSyncService synchronizes tasks and agenda to SharedPreferences for Android widgets', () async {
      SharedPreferences.setMockInitialValues({});
      final db = MyDayDatabase.create(inMemory: true);
      await db.initDatabase();

      final tasksRepo = TasksRepository(db);
      const accountId = 'user_account_sync_test';

      // Insert real task
      await tasksRepo.addTask(
        accountId: accountId,
        title: 'Submit Expense Receipts',
        dueDate: 'Today · 5:00 PM',
        kind: 'todo',
      );

      // Insert real event
      await tasksRepo.addTask(
        accountId: accountId,
        title: 'Project Roadmap Sync',
        dueDate: 'Today · 3:00 PM',
        tags: ['event'],
        kind: 'todo',
      );

      await WidgetDataSyncService.syncWidgetsData(
        tasksRepository: tasksRepo,
        accountId: accountId,
      );

      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getString('widget_tasks_json');
      final agendaJson = prefs.getString('widget_agenda_json');
      final adDate = prefs.getString('widget_ad_date');
      final bsDate = prefs.getString('widget_bs_date');

      expect(tasksJson, isNotNull);
      expect(tasksJson, contains('Submit Expense Receipts'));

      expect(agendaJson, isNotNull);
      expect(agendaJson, contains('Project Roadmap Sync'));

      expect(adDate, isNotNull);
      expect(bsDate, isNotNull);

      await db.close();
    });
  });
}
