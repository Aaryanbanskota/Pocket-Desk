import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/features/tasks/data/models/task_model.dart';

void main() {
  group('TaskModel Validation Tests', () {
    test('TaskModel initializes with correct defaults', () {
      final task = TaskModel()
        ..title = 'Test Task'
        ..userId = 1;

      expect(task.title, equals('Test Task'));
      expect(task.userId, equals(1));
      expect(task.priority, equals(TaskPriority.none));
      expect(task.status, equals(TaskStatus.todo));
      expect(task.isRecurring, isFalse);
      expect(task.subtaskTitles, isEmpty);
      expect(task.subtaskDone, isEmpty);
    });
  });
}
