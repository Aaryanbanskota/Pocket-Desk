import 'calendar_event_model.dart';

/// Utility class to generate event instances for recurring events.
class RecurrenceEngine {
  /// Expands a list of events to include all recurring instances within a given date range.
  static List<CalendarEventModel> expandEvents(
    List<CalendarEventModel> events,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final List<CalendarEventModel> expanded = [];

    for (final event in events) {
      if (event.recurrenceType == RecurrenceType.none) {
        // Only include if it overlaps with the range
        if (event.startTime.isBefore(rangeEnd) && event.endTime.isAfter(rangeStart)) {
          expanded.add(event);
        }
      } else {
        expanded.addAll(getInstancesForEvent(event, rangeStart, rangeEnd));
      }
    }

    return expanded;
  }

  /// Generates recurring instances of a single event within a date range.
  static List<CalendarEventModel> getInstancesForEvent(
    CalendarEventModel event,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final List<CalendarEventModel> instances = [];

    // The recurrence cannot start before the original event's start time
    final DateTime startLimit = event.startTime;
    final DateTime effectiveStart = rangeStart.isBefore(startLimit) ? startLimit : rangeStart;

    final Duration eventDuration = event.endTime.difference(event.startTime);

    switch (event.recurrenceType) {
      case RecurrenceType.none:
        if (event.startTime.isBefore(rangeEnd) && event.endTime.isAfter(rangeStart)) {
          instances.add(event);
        }
        break;

      case RecurrenceType.daily:
        // Every day starting from event.startTime
        DateTime current = DateTime(
          event.startTime.year,
          event.startTime.month,
          event.startTime.day,
          event.startTime.hour,
          event.startTime.minute,
        );

        // Fast forward to effectiveStart if possible
        if (current.isBefore(effectiveStart)) {
          final diffDays = effectiveStart.difference(current).inDays;
          current = current.add(Duration(days: diffDays));
          // Back up a bit to make sure we don't miss overlap boundary
          if (current.isAfter(effectiveStart)) {
            current = current.subtract(const Duration(days: 1));
          }
        }

        while (current.isBefore(rangeEnd)) {
          if (current.isAfter(startLimit) || current.isAtSameMomentAs(startLimit)) {
            final DateTime instStart = DateTime(
              current.year,
              current.month,
              current.day,
              event.startTime.hour,
              event.startTime.minute,
            );
            final DateTime instEnd = instStart.add(eventDuration);

            // Check if it overlaps with the range
            if (instStart.isBefore(rangeEnd) && instEnd.isAfter(rangeStart)) {
              instances.add(_cloneWithNewTimes(event, instStart, instEnd));
            }
          }
          current = current.add(const Duration(days: 1));
        }
        break;

      case RecurrenceType.weekly:
        // Every week starting from event.startTime
        DateTime current = DateTime(
          event.startTime.year,
          event.startTime.month,
          event.startTime.day,
          event.startTime.hour,
          event.startTime.minute,
        );

        if (current.isBefore(effectiveStart)) {
          final diffWeeks = (effectiveStart.difference(current).inDays / 7).floor();
          current = current.add(Duration(days: diffWeeks * 7));
          if (current.isAfter(effectiveStart)) {
            current = current.subtract(const Duration(days: 7));
          }
        }

        while (current.isBefore(rangeEnd)) {
          if (current.isAfter(startLimit) || current.isAtSameMomentAs(startLimit)) {
            final DateTime instStart = DateTime(
              current.year,
              current.month,
              current.day,
              event.startTime.hour,
              event.startTime.minute,
            );
            final DateTime instEnd = instStart.add(eventDuration);

            if (instStart.isBefore(rangeEnd) && instEnd.isAfter(rangeStart)) {
              instances.add(_cloneWithNewTimes(event, instStart, instEnd));
            }
          }
          current = current.add(const Duration(days: 7));
        }
        break;

      case RecurrenceType.monthly:
        // Every month starting from event.startTime
        int monthOffset = 0;
        while (true) {
          final nextMonthDate = DateTime(
            event.startTime.year,
            event.startTime.month + monthOffset,
            event.startTime.day,
            event.startTime.hour,
            event.startTime.minute,
          );

          if (nextMonthDate.isAfter(rangeEnd)) {
            break;
          }

          // Ensure it's not before the original start time
          if (nextMonthDate.isAfter(startLimit) || nextMonthDate.isAtSameMomentAs(startLimit)) {
            final DateTime instEnd = nextMonthDate.add(eventDuration);
            if (nextMonthDate.isBefore(rangeEnd) && instEnd.isAfter(rangeStart)) {
              instances.add(_cloneWithNewTimes(event, nextMonthDate, instEnd));
            }
          }

          monthOffset++;
        }
        break;

      case RecurrenceType.yearly:
        // Every year starting from event.startTime
        int yearOffset = 0;
        while (true) {
          final nextYearDate = DateTime(
            event.startTime.year + yearOffset,
            event.startTime.month,
            event.startTime.day,
            event.startTime.hour,
            event.startTime.minute,
          );

          if (nextYearDate.isAfter(rangeEnd)) {
            break;
          }

          if (nextYearDate.isAfter(startLimit) || nextYearDate.isAtSameMomentAs(startLimit)) {
            final DateTime instEnd = nextYearDate.add(eventDuration);
            if (nextYearDate.isBefore(rangeEnd) && instEnd.isAfter(rangeStart)) {
              instances.add(_cloneWithNewTimes(event, nextYearDate, instEnd));
            }
          }

          yearOffset++;
        }
        break;

      case RecurrenceType.custom:
        // Parse custom rule (e.g. FREQ=WEEKLY;BYDAY=MO,WE,FR or INTERVAL=2)
        // If empty, fallback to weekly
        final rule = event.recurrenceRule ?? '';
        final parsed = _parseRecurrenceRule(rule, event.startTime);
        
        final freq = parsed['FREQ'] ?? 'WEEKLY';
        final interval = int.tryParse(parsed['INTERVAL'] ?? '1') ?? 1;
        final byDays = parsed['BYDAY']?.split(',') ?? [];

        if (freq == 'DAILY') {
          DateTime current = event.startTime;
          while (current.isBefore(rangeEnd)) {
            final DateTime instEnd = current.add(eventDuration);
            if (current.isBefore(rangeEnd) && instEnd.isAfter(rangeStart)) {
              instances.add(_cloneWithNewTimes(event, current, instEnd));
            }
            current = current.add(Duration(days: interval));
          }
        } else if (freq == 'WEEKLY') {
          // If byDays is specified, we recur on those specific days of each week
          if (byDays.isNotEmpty) {
            DateTime currentWeekStart = _getWeekStart(event.startTime);
            while (currentWeekStart.isBefore(rangeEnd)) {
              for (final day in byDays) {
                final weekdayInt = _getWeekdayInt(day);
                final targetDate = currentWeekStart.add(Duration(days: weekdayInt - 1));
                
                // Set original time
                final instStart = DateTime(
                  targetDate.year,
                  targetDate.month,
                  targetDate.day,
                  event.startTime.hour,
                  event.startTime.minute,
                );

                if (instStart.isBefore(event.startTime)) continue;

                final instEnd = instStart.add(eventDuration);
                if (instStart.isBefore(rangeEnd) && instEnd.isAfter(rangeStart)) {
                  instances.add(_cloneWithNewTimes(event, instStart, instEnd));
                }
              }
              currentWeekStart = currentWeekStart.add(Duration(days: 7 * interval));
            }
          } else {
            // Fallback to simple weekly
            DateTime current = event.startTime;
            while (current.isBefore(rangeEnd)) {
              final DateTime instEnd = current.add(eventDuration);
              if (current.isBefore(rangeEnd) && instEnd.isAfter(rangeStart)) {
                instances.add(_cloneWithNewTimes(event, current, instEnd));
              }
              current = current.add(Duration(days: 7 * interval));
            }
          }
        } else if (freq == 'MONTHLY') {
          int monthOffset = 0;
          while (true) {
            final nextMonthDate = DateTime(
              event.startTime.year,
              event.startTime.month + (monthOffset * interval),
              event.startTime.day,
              event.startTime.hour,
              event.startTime.minute,
            );

            if (nextMonthDate.isAfter(rangeEnd)) {
              break;
            }

            final DateTime instEnd = nextMonthDate.add(eventDuration);
            if (nextMonthDate.isBefore(rangeEnd) && instEnd.isAfter(rangeStart)) {
              instances.add(_cloneWithNewTimes(event, nextMonthDate, instEnd));
            }

            monthOffset++;
          }
        } else {
          // Fallback to single instance
          if (event.startTime.isBefore(rangeEnd) && event.endTime.isAfter(rangeStart)) {
            instances.add(event);
          }
        }
        break;
    }

    return instances;
  }

  static CalendarEventModel _cloneWithNewTimes(
    CalendarEventModel event,
    DateTime newStart,
    DateTime newEnd,
  ) {
    return CalendarEventModel()
      ..id = event.id
      ..userId = event.userId
      ..title = event.title
      ..description = event.description
      ..location = event.location
      ..startTime = newStart
      ..endTime = newEnd
      ..isAllDay = event.isAllDay
      ..category = event.category
      ..colorHex = event.colorHex
      ..recurrenceType = event.recurrenceType
      ..recurrenceRule = event.recurrenceRule
      ..timeZone = event.timeZone
      ..reminderMinutes = event.reminderMinutes
      ..attachmentPaths = event.attachmentPaths
      ..createdAt = event.createdAt
      ..updatedAt = event.updatedAt
      ..isSynced = event.isSynced;
  }

  static Map<String, String> _parseRecurrenceRule(String rule, DateTime start) {
    final Map<String, String> map = {};
    final parts = rule.split(';');
    for (final part in parts) {
      final kv = part.split('=');
      if (kv.length == 2) {
        map[kv[0].toUpperCase()] = kv[1];
      }
    }
    return map;
  }

  static DateTime _getWeekStart(DateTime date) {
    // Return Monday of the week containing `date`
    return date.subtract(Duration(days: date.weekday - 1));
  }

  static int _getWeekdayInt(String day) {
    switch (day.toUpperCase()) {
      case 'MO': return 1;
      case 'TU': return 2;
      case 'WE': return 3;
      case 'TH': return 4;
      case 'FR': return 5;
      case 'SA': return 6;
      case 'SU': return 7;
      default: return 1;
    }
  }
}
