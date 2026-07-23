import 'package:intl/intl.dart';

/// Date/time formatting helpers used throughout PocketDesk.
abstract final class DateTimeUtils {
  // --------------------------------------------------------------------------
  // Formatters (cached for performance)
  // --------------------------------------------------------------------------

  static final DateFormat _timeHm = DateFormat('HH:mm');
  static final DateFormat _timeHma = DateFormat('h:mm a');
  static final DateFormat _dateFull = DateFormat('EEEE, MMMM d, y');
  static final DateFormat _dateMedium = DateFormat('MMM d, y');
  static final DateFormat _dateShort = DateFormat('MM/dd/yyyy');
  static final DateFormat _monthYear = DateFormat('MMMM y');
  static final DateFormat _dayName = DateFormat('EEEE');
  static final DateFormat _dayShort = DateFormat('E');
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  // --------------------------------------------------------------------------
  // Time
  // --------------------------------------------------------------------------

  /// Returns time as "14:30".
  static String toTime24(DateTime dt) => _timeHm.format(dt);

  /// Returns time as "2:30 PM".
  static String toTime12(DateTime dt) => _timeHma.format(dt);

  // --------------------------------------------------------------------------
  // Date
  // --------------------------------------------------------------------------

  /// Returns "Monday, January 1, 2024".
  static String toFullDate(DateTime dt) => _dateFull.format(dt);

  /// Returns "Jan 1, 2024".
  static String toMediumDate(DateTime dt) => _dateMedium.format(dt);

  /// Returns "01/01/2024".
  static String toShortDate(DateTime dt) => _dateShort.format(dt);

  /// Returns "January 2024".
  static String toMonthYear(DateTime dt) => _monthYear.format(dt);

  /// Returns "Monday".
  static String toDayName(DateTime dt) => _dayName.format(dt);

  /// Returns "Mon".
  static String toDayNameShort(DateTime dt) => _dayShort.format(dt);

  /// Returns ISO-8601 date string "2024-01-01".
  static String toIsoDate(DateTime dt) => _isoDate.format(dt);

  // --------------------------------------------------------------------------
  // Relative labels
  // --------------------------------------------------------------------------

  /// Returns "Today", "Yesterday", "Tomorrow", or a formatted date.
  static String toRelativeLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = target.difference(today).inDays;

    return switch (diff) {
      0 => 'Today',
      -1 => 'Yesterday',
      1 => 'Tomorrow',
      _ => toMediumDate(dt),
    };
  }

  /// Human-readable "X min ago", "X hours ago", "just now".
  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return toMediumDate(dt);
  }

  // --------------------------------------------------------------------------
  // Boundaries
  // --------------------------------------------------------------------------

  static DateTime startOfDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static DateTime endOfDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day, 23, 59, 59, 999);

  static DateTime startOfWeek(DateTime dt) {
    final weekday = dt.weekday; // 1 = Monday
    return startOfDay(dt.subtract(Duration(days: weekday - 1)));
  }

  static DateTime endOfWeek(DateTime dt) =>
      endOfDay(startOfWeek(dt).add(const Duration(days: 6)));

  static DateTime startOfMonth(DateTime dt) =>
      DateTime(dt.year, dt.month);

  static DateTime endOfMonth(DateTime dt) =>
      DateTime(dt.year, dt.month + 1, 0, 23, 59, 59, 999);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isToday(DateTime dt) => isSameDay(dt, DateTime.now());

  static bool isPast(DateTime dt) => dt.isBefore(DateTime.now());

  static bool isFuture(DateTime dt) => dt.isAfter(DateTime.now());
}
