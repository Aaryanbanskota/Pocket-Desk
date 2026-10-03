import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/isar_provider.dart';
import '../../../../core/error/app_failure.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/models/calendar_event_model.dart';
import '../../data/repositories/calendar_repository.dart';
import '../../../notes/presentation/providers/notes_notifier.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/presentation/providers/tasks_notifier.dart';
import '../../../trash/data/models/trash_item_model.dart';
import '../../../trash/presentation/providers/trash_notifier.dart';


// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final calendarRepositoryProvider = FutureProvider<CalendarRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return CalendarRepository(isar: isar);
});

// ---------------------------------------------------------------------------
// Calendar events notifier
// ---------------------------------------------------------------------------

class CalendarEventsNotifier extends AutoDisposeAsyncNotifier<List<CalendarEventModel>> {
  @override
  Future<List<CalendarEventModel>> build() async {
    return _fetchEvents();
  }

  Future<List<CalendarEventModel>> _fetchEvents() async {
    final authState = ref.watch(authNotifierProvider).valueOrNull;
    if (authState is! AuthAuthenticated) return [];

    final repo = await ref.read(calendarRepositoryProvider.future);
    final realEvents = await repo.getEventsForUser(authState.user.id);

    final syntheticEvents = <CalendarEventModel>[];

    // 1. Interconnect Tasks with due dates into Calendar
    final tasksState = ref.read(tasksProvider).valueOrNull;
    if (tasksState != null) {
      for (final task in tasksState.tasks) {
        if (task.dueDate != null) {
          final due = task.dueDate!;
          final isDone = task.status == TaskStatus.done;
          syntheticEvents.add(
            CalendarEventModel()
              ..id = 9000000 + (task.id.hashCode.abs() % 900000)
              ..userId = authState.user.id
              ..title = '${isDone ? "✓ " : "📋 Task Due: "}${task.title}'
              ..startTime = due
              ..endTime = due.add(const Duration(hours: 1))
              ..description = task.description ?? 'Task due date'
              ..category = 'Task'
              ..colorHex = isDone ? '#4CAF50' : '#FF9800'
              ..isAllDay = false,
          );
        }
      }
    }

    // 2. Interconnect Notes creation date into Calendar
    final notesState = ref.read(notesProvider).valueOrNull;
    if (notesState != null) {
      for (final note in notesState.notes) {
        final created = note.createdAt;
        syntheticEvents.add(
          CalendarEventModel()
            ..id = 8000000 + (note.id.hashCode.abs() % 900000)
            ..userId = authState.user.id
            ..title = '📝 Note Created: ${note.title}'
            ..startTime = created
            ..endTime = created.add(const Duration(hours: 1))
            ..description = note.content.length > 150
                ? '${note.content.substring(0, 150)}...'
                : note.content
            ..category = 'Note'
            ..colorHex = '#2196F3'
            ..isAllDay = false,
        );
      }
    }

    return [...realEvents, ...syntheticEvents];
  }

  Future<void> addOrUpdateEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? location,
    bool isAllDay = false,
    String? category,
    String? colorHex,
    RecurrenceType recurrenceType = RecurrenceType.none,
    List<int> reminderMinutes = const [],
    int? eventId,
  }) async {
    final authState = ref.read(authNotifierProvider).valueOrNull;
    if (authState is! AuthAuthenticated) return;

    state = const AsyncValue.loading();
    try {
      final repo = await ref.read(calendarRepositoryProvider.future);
      final event = CalendarEventModel()
        ..userId = authState.user.id
        ..title = title
        ..startTime = startTime
        ..endTime = endTime
        ..description = description
        ..location = location
        ..isAllDay = isAllDay
        ..category = category
        ..colorHex = colorHex
        ..recurrenceType = recurrenceType
        ..reminderMinutes = reminderMinutes;

      if (eventId != null) {
        event.id = eventId;
      }

      final result = await repo.saveEvent(event);
      if (result.error != null) {
        state = AsyncValue.error(result.error!, StackTrace.current);
      } else {
        if (result.event != null) {
          await NotificationService.instance.scheduleEventReminders(result.event!);
        }
        ref.invalidateSelf();
      }
    } catch (e, st) {
      state = AsyncValue.error(
        UnexpectedFailure('Failed to save calendar event', error: e, stackTrace: st),
        st,
      );
    }
  }

  Future<void> deleteEvent(int eventId) async {
    state = const AsyncValue.loading();
    try {
      final repo = await ref.read(calendarRepositoryProvider.future);
      // Move to trash prior to permanent deletion from active collection
      final event = await repo.getEventById(eventId);
      if (event != null) {
        await ref.read(trashNotifierProvider.notifier).moveToTrash(
              itemType: TrashItemType.event,
              originalId: event.id,
              title: event.title,
              snippet: event.description != null && event.description!.isNotEmpty
                  ? (event.description!.length > 100 ? '${event.description!.substring(0, 100)}...' : event.description!)
                  : 'Calendar Event',
            );
      }

      // Cancel notifications first
      await NotificationService.instance.cancelEventReminders(eventId);
      
      final error = await repo.deleteEvent(eventId);
      if (error != null) {
        state = AsyncValue.error(error, StackTrace.current);
      } else {
        ref.invalidateSelf();
      }
    } catch (e, st) {
      state = AsyncValue.error(
        UnexpectedFailure('Failed to delete calendar event', error: e, stackTrace: st),
        st,
      );
    }
  }
}

final calendarEventsProvider =
    AutoDisposeAsyncNotifierProvider<CalendarEventsNotifier, List<CalendarEventModel>>(
  CalendarEventsNotifier.new,
);
