import '../models/calendar_event_model.dart';

/// Minimal iCalendar (RFC 5545) ICS serializer/deserializer.
class IcsService {
  const IcsService();

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  /// Converts a list of [CalendarEventModel] to an ICS string.
  String exportToIcs(List<CalendarEventModel> events, {String calendarName = 'PocketDesk'}) {
    final buf = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//PocketDesk//PocketDesk//EN')
      ..writeln('CALSCALE:GREGORIAN')
      ..writeln('X-WR-CALNAME:$calendarName');

    for (final event in events) {
      buf
        ..writeln('BEGIN:VEVENT')
        ..writeln('UID:pocketdesk-${event.id}@pocketdesk')
        ..writeln('SUMMARY:${_escapeText(event.title)}');

      if (event.isAllDay) {
        buf
          ..writeln('DTSTART;VALUE=DATE:${_toDateString(event.startTime)}')
          ..writeln('DTEND;VALUE=DATE:${_toDateString(event.endTime)}');
      } else {
        buf
          ..writeln('DTSTART:${_toDateTimeString(event.startTime)}')
          ..writeln('DTEND:${_toDateTimeString(event.endTime)}');
      }

      if (event.description != null && event.description!.isNotEmpty) {
        buf.writeln('DESCRIPTION:${_escapeText(event.description!)}');
      }
      if (event.location != null && event.location!.isNotEmpty) {
        buf.writeln('LOCATION:${_escapeText(event.location!)}');
      }
      if (event.recurrenceRule != null && event.recurrenceRule!.isNotEmpty) {
        buf.writeln('RRULE:${event.recurrenceRule}');
      }
      for (final mins in event.reminderMinutes) {
        buf
          ..writeln('BEGIN:VALARM')
          ..writeln('TRIGGER:-PT${mins}M')
          ..writeln('ACTION:DISPLAY')
          ..writeln('DESCRIPTION:Reminder')
          ..writeln('END:VALARM');
      }

      buf
        ..writeln('DTSTAMP:${_toDateTimeString(event.updatedAt)}')
        ..writeln('CREATED:${_toDateTimeString(event.createdAt)}')
        ..writeln('END:VEVENT');
    }

    buf.writeln('END:VCALENDAR');
    return buf.toString();
  }

  // ---------------------------------------------------------------------------
  // Import
  // ---------------------------------------------------------------------------

  /// Parses an ICS string and returns a list of partially-populated [CalendarEventModel] objects.
  List<CalendarEventModel> importFromIcs(String icsContent) {
    final events = <CalendarEventModel>[];
    final lines = _unfoldLines(icsContent);

    CalendarEventModel? current;
    final List<int> currentReminders = [];

    for (final line in lines) {
      if (line.startsWith('BEGIN:VEVENT')) {
        current = CalendarEventModel()
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        currentReminders.clear();
      } else if (line.startsWith('END:VEVENT') && current != null) {
        current.reminderMinutes = List<int>.from(currentReminders);
        events.add(current);
        current = null;
      } else if (current != null) {
        final colonIdx = line.indexOf(':');
        if (colonIdx < 0) continue;
        final key = line.substring(0, colonIdx).split(';').first;
        final value = line.substring(colonIdx + 1);

        switch (key) {
          case 'SUMMARY':
            current.title = _unescapeText(value);
            break;
          case 'DESCRIPTION':
            current.description = _unescapeText(value);
            break;
          case 'LOCATION':
            current.location = _unescapeText(value);
            break;
          case 'DTSTART':
            if (line.contains('VALUE=DATE')) {
              current.startTime = _parseDateString(value);
              current.isAllDay = true;
            } else {
              current.startTime = _parseDateTimeString(value);
            }
            break;
          case 'DTEND':
            if (line.contains('VALUE=DATE')) {
              current.endTime = _parseDateString(value);
            } else {
              current.endTime = _parseDateTimeString(value);
            }
            break;
          case 'RRULE':
            current.recurrenceRule = value;
            _setRecurrenceType(current, value);
            break;
          case 'TRIGGER':
            // Parse -PT15M style
            final match = RegExp(r'PT(\d+)M').firstMatch(value);
            if (match != null) {
              currentReminders.add(int.parse(match.group(1)!));
            }
            break;
        }
      }
    }

    return events;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _toDateString(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';

  String _toDateTimeString(DateTime dt) {
    final utc = dt.toUtc();
    return '${_toDateString(utc)}T${utc.hour.toString().padLeft(2, '0')}${utc.minute.toString().padLeft(2, '0')}${utc.second.toString().padLeft(2, '0')}Z';
  }

  DateTime _parseDateString(String value) {
    final clean = value.trim();
    return DateTime(
      int.parse(clean.substring(0, 4)),
      int.parse(clean.substring(4, 6)),
      int.parse(clean.substring(6, 8)),
    );
  }

  DateTime _parseDateTimeString(String value) {
    final clean = value.trim().replaceAll('Z', '');
    if (clean.length < 15) return DateTime.now();
    return DateTime.utc(
      int.parse(clean.substring(0, 4)),
      int.parse(clean.substring(4, 6)),
      int.parse(clean.substring(6, 8)),
      int.parse(clean.substring(9, 11)),
      int.parse(clean.substring(11, 13)),
      int.parse(clean.substring(13, 15)),
    ).toLocal();
  }

  String _escapeText(String text) => text.replaceAll(',', '\\,').replaceAll(';', '\\;').replaceAll('\n', '\\n');
  String _unescapeText(String text) => text.replaceAll('\\,', ',').replaceAll('\\;', ';').replaceAll('\\n', '\n');

  List<String> _unfoldLines(String content) {
    return content.replaceAll('\r\n ', '').replaceAll('\n ', '').split(RegExp(r'\r?\n'));
  }

  void _setRecurrenceType(CalendarEventModel event, String rrule) {
    final upper = rrule.toUpperCase();
    if (upper.contains('FREQ=DAILY')) {
      event.recurrenceType = RecurrenceType.daily;
    } else if (upper.contains('FREQ=WEEKLY')) {
      event.recurrenceType = RecurrenceType.weekly;
    } else if (upper.contains('FREQ=MONTHLY')) {
      event.recurrenceType = RecurrenceType.monthly;
    } else if (upper.contains('FREQ=YEARLY')) {
      event.recurrenceType = RecurrenceType.yearly;
    } else {
      event.recurrenceType = RecurrenceType.custom;
    }
  }
}
