import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/features/tasks/data/tasks_repository.dart';
import 'package:pocketdesk/features/tasks/presentation/tasks_screen.dart';

void main() {
  group('Tasks & Events Integration Tests', () {
    testWidgets('TasksScreen renders Events filter chip and displays Event badge', (tester) async {
      final taskWithEvent = MyDayTask(
        id: 'ev-1',
        accountId: 'acc-1',
        kind: 'todo',
        title: 'Project Architecture Sync',
        dueDate: '2026-10-19',
        tags: const ['event'],
        isDone: false,
      );

      final normalTask = MyDayTask(
        id: 'tk-1',
        accountId: 'acc-1',
        kind: 'todo',
        title: 'Submit pull request',
        dueDate: '2026-10-19',
        tags: const ['work'],
        isDone: false,
      );

      String? selectedFilter;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TasksScreen(
              tasks: [taskWithEvent, normalTask],
              activeFilter: 'all',
              onFilterChanged: (filter) => selectedFilter = filter,
              onToggleTask: (_) {},
              onEditTask: (_) {},
              onDeleteTask: (_) {},
              onRunTask: (_) {},
              runningTimers: const {},
            ),
          ),
        ),
      );

      // Verify filter chips
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Verify Event badge appears for event task
      expect(find.text('Event'), findsOneWidget);
      expect(find.text('Project Architecture Sync'), findsOneWidget);
      expect(find.text('Submit pull request'), findsOneWidget);

      // Tap Events chip
      await tester.tap(find.text('Events'));
      expect(selectedFilter, 'events');
    });
  });
}
