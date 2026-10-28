import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/core/database/myday_database.dart';
import 'package:pocketdesk/core/security/secure_pin_service.dart';
import 'package:pocketdesk/core/utils/nepali_calendar_converter.dart';
import 'package:pocketdesk/features/tasks/data/tasks_repository.dart';
import 'package:pocketdesk/features/notes/data/notes_repository.dart';
import 'package:pocketdesk/features/trash/data/trash_repository.dart';

void main() {
  group('MyDay Core & Utilities Tests', () {
    late MyDayDatabase db;
    late TasksRepository tasksRepo;
    late NotesRepository notesRepo;
    late TrashRepository trashRepo;
    const testAccountId = 'test_user_core';

    setUp(() async {
      db = MyDayDatabase.create(inMemory: true);
      await db.initDatabase();
      tasksRepo = TasksRepository(db);
      notesRepo = NotesRepository(db);
      trashRepo = TrashRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('SecurePinService: salt prefix and SHA-256 validation', () {
      final hash = SecurePinService.hashPin('1234');
      expect(hash.isNotEmpty, isTrue);
      expect(SecurePinService.verifyPin('1234', hash), isTrue);
      expect(SecurePinService.verifyPin('0000', hash), isFalse);
      expect(SecurePinService.verifyPin('1235', hash), isFalse);
    });

    test('NepaliCalendarConverter: dual Gregorian AD <-> Bikram Sambat BS', () {
      final adDate = DateTime(2026, 10, 18);
      final bsDate = NepaliCalendarConverter.toBS(adDate);

      expect(bsDate.year, 2083);
      expect(bsDate.month, 7); // Kartik is 7th month

      final reconvertedAD = NepaliCalendarConverter.toAD(bsDate);
      expect(reconvertedAD.year, adDate.year);
      expect(reconvertedAD.month, adDate.month);
      expect(reconvertedAD.day, adDate.day);

      final bsFormatted = NepaliCalendarConverter.formatBSShort(adDate);
      expect(bsFormatted.contains('Kartik'), isTrue);
      expect(bsFormatted.contains('2083'), isTrue);
    });

    test('TasksRepository: CRUD, completion, and daily recurrence spawning', () async {
      final task = await tasksRepo.addTask(
        accountId: testAccountId,
        title: 'Review PRs',
        kind: 'todo',
        dueDate: '2026-10-18',
        isImportant: true,
        tags: ['Work', 'Code'],
        repeatInterval: 'daily',
        note: 'High priority backlog PRs',
      );

      expect(task.title, 'Review PRs');
      expect(task.isDone, isFalse);
      expect(task.isImportant, isTrue);
      expect(task.tags, contains('Work'));

      // Complete the recurring task -> should spawn the next recurrence
      await tasksRepo.toggleTaskDone(task);

      final tasks = await tasksRepo.getTasks(testAccountId);
      expect(tasks.length, 2); // original completed task + spawned next day's task

      final completed = tasks.firstWhere((t) => t.id == task.id);
      expect(completed.isDone, isTrue);

      final spawned = tasks.firstWhere((t) => t.id != task.id);
      expect(spawned.isDone, isFalse);
      expect(spawned.dueDate, '2026-10-19'); // spawned for tomorrow
      expect(spawned.title, 'Review PRs');

      // Verify dates with incomplete tasks (only tomorrow's spawned task is pending)
      final dates = await tasksRepo.getDatesWithTasks(testAccountId);
      expect(dates.contains('2026-10-18'), isFalse);
      expect(dates.contains('2026-10-19'), isTrue);
    });

    test('TrashRepository: 30-day retention, multi-entity aggregation, restore, and purge', () async {
      // 1. Create task and note
      final task = await tasksRepo.addTask(
        accountId: testAccountId,
        title: 'Task to Trash',
        dueDate: '2026-10-18',
      );

      final note = await notesRepo.createNote(
        accountId: testAccountId,
        title: 'Note to Trash',
        body: 'Discarded scratchpad content',
      );

      // Trash both
      await tasksRepo.deleteTask(task.id);
      await notesRepo.deleteNote(note.id);

      // Verify they appear in trash
      var trashItems = await trashRepo.getTrashItems(testAccountId);
      expect(trashItems.length, 2);

      for (final item in trashItems) {
        expect(item.daysRemaining, inInclusiveRange(28, 30));
      }

      // Restore task
      final taskItem = trashItems.firstWhere((i) => i.id == task.id);
      await trashRepo.restoreItem(taskItem);

      trashItems = await trashRepo.getTrashItems(testAccountId);
      expect(trashItems.length, 1);
      expect(trashItems.first.id, note.id);

      final activeTasks = await tasksRepo.getTasks(testAccountId);
      expect(activeTasks.any((t) => t.id == task.id), isTrue);

      // Permanently delete remaining note
      final noteItem = trashItems.first;
      await trashRepo.permanentlyDeleteItem(noteItem);

      trashItems = await trashRepo.getTrashItems(testAccountId);
      expect(trashItems.isEmpty, isTrue);
    });
  });
}
