import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/isar_provider.dart';
import '../../../../core/error/app_failure.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/calendar_event_model.dart';
import '../../data/repositories/calendar_repository.dart';


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
    return repo.getEventsForUser(authState.user.id);
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
