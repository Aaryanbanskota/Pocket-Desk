import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketdesk/core/services/p2p_sync_service.dart';
import 'package:pocketdesk/features/auth/presentation/providers/auth_notifier.dart';
import 'package:pocketdesk/features/chat/presentation/pages/chat_page.dart';
import 'package:pocketdesk/features/calendar/data/models/calendar_event_model.dart';
import 'package:pocketdesk/features/calendar/presentation/providers/calendar_events_notifier.dart';
import 'package:pocketdesk/features/notes/data/models/note_model.dart';
import 'package:pocketdesk/features/notes/presentation/providers/notes_notifier.dart';
import 'package:pocketdesk/features/settings/data/models/ai_settings_model.dart';
import 'package:pocketdesk/features/settings/data/repositories/ai_settings_repository.dart';
import 'package:pocketdesk/features/settings/presentation/providers/ai_settings_notifier.dart';
import 'package:pocketdesk/features/tasks/data/models/task_model.dart';
import 'package:pocketdesk/features/tasks/presentation/providers/tasks_notifier.dart';
import 'package:isar/isar.dart';

final _deletedRecords = <String>[];

class _ImmediateUnauthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => const AuthUnauthenticated();
}

class _TasksNotifierWithData extends TasksNotifier {
  @override
  Future<TasksState> build() async {
    return TasksState(
      tasks: [TaskModel()..title = 'Finish report'],
    );
  }
}

class _CalendarNotifierWithData extends CalendarEventsNotifier {
  @override
  Future<List<CalendarEventModel>> build() async {
    return [CalendarEventModel()..title = 'Team meeting'];
  }
}

class _NotesNotifierWithData extends NotesNotifier {
  @override
  Future<NotesState> build() async {
    return NotesState(notes: [NoteModel()..title = 'Shopping list']);
  }

  @override
  Future<void> deleteNote(int noteId) async {
    _deletedRecords.add('note:$noteId');
  }
}

class _DeletableTasksNotifier extends _TasksNotifierWithData {
  @override
  Future<void> deleteTask(int taskId) async {
    _deletedRecords.add('task:$taskId');
  }
}

class _DeletableCalendarNotifier extends _CalendarNotifierWithData {
  @override
  Future<void> deleteEvent(int eventId) async {
    _deletedRecords.add('event:$eventId');
  }
}

class _UnusedIsar implements Isar {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AISettingsRepositoryWithMasterControl extends AISettingsRepository {
  _AISettingsRepositoryWithMasterControl() : super(isar: _UnusedIsar());

  @override
  Future<AISettingsModel> getOrCreateSettings(int userId) async {
    return AISettingsModel()
      ..userId = userId
      ..masterControlEnabled = true;
  }
}

void main() {
  testWidgets(
      'slash suggestions keep input visible and Enter sends the command',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_ImmediateUnauthNotifier.new),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: const ChatPage(),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.person_add_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Enter Friend Code / Device ID',
      ),
      'test-peer',
    );
    await tester.tap(find.text('Connect P2P'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final input = find.byType(TextField);
    await tester.showKeyboard(input);
    await tester.enterText(input, '/');
    await tester.pump();

    expect(input, findsOneWidget);
    expect(find.textContaining('/create -'), findsOneWidget);
    expect(tester.widget<TextField>(input).focusNode!.hasPrimaryFocus, isTrue);

    await tester.tap(find.textContaining('/create -'));
    await tester.pump();
    expect(tester.widget<TextField>(input).focusNode!.hasPrimaryFocus, isTrue);
    expect(tester.widget<TextField>(input).controller!.text, '/create ');

    await tester.enterText(input, '/create a task');
    expect(tester.widget<TextField>(input).controller!.text, '/create a task');
    expect(tester.widget<TextField>(input).focusNode!.hasPrimaryFocus, isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('/create a task'), findsOneWidget);
    expect(input, findsOneWidget);
  });

  testWidgets('AI lists local task and event names on request', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await P2PSyncService().initialize(deviceId: 'test-device');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_ImmediateUnauthNotifier.new),
          tasksProvider.overrideWith(_TasksNotifierWithData.new),
          calendarEventsProvider.overrideWith(_CalendarNotifierWithData.new),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: const ChatPage(),
        ),
      ),
    );

    final input = find.byType(TextField);
    await tester.showKeyboard(input);
    await tester.enterText(input, 'tell me all event task name');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.textContaining('- Finish report'), findsOneWidget);
    expect(find.textContaining('- Team meeting'), findsOneWidget);
  });

  testWidgets('named task, event, and note deletions need one confirmation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await P2PSyncService().initialize(deviceId: 'test-device');
    _deletedRecords.clear();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_ImmediateUnauthNotifier.new),
          aiSettingsRepositoryProvider.overrideWith(
            (ref) async => _AISettingsRepositoryWithMasterControl(),
          ),
          tasksProvider.overrideWith(_DeletableTasksNotifier.new),
          calendarEventsProvider.overrideWith(_DeletableCalendarNotifier.new),
          notesProvider.overrideWith(_NotesNotifierWithData.new),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: const ChatPage(),
        ),
      ),
    );

    for (final request in [
      ('delete task Finish report', 'task:'),
      ('delete event Team meeting', 'event:'),
      ('delete note Shopping list', 'note:'),
    ]) {
      await tester.showKeyboard(find.byType(TextField));
      await tester.enterText(find.byType(TextField), request.$1);
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      final type = request.$2.split(':').first;
      expect(find.text('Delete $type?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(_deletedRecords.last, startsWith(request.$2));
      expect(find.textContaining('deletion cancelled'), findsNothing);
    }

    expect(_deletedRecords, hasLength(3));
  });
}
