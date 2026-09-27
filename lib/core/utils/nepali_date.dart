import 'package:flutter/foundation.dart';

/// Representation of a Bikram Sambat (BS) date.
@immutable
class NepaliDate implements Comparable<NepaliDate> {
  const NepaliDate({
    required this.year,
    required this.month,
    required this.day,
    this.hour = 0,
    this.minute = 0,
    this.second = 0,
  })  : assert(month >= 1 && month <= 12, 'Month must be between 1 and 12'),
        assert(day >= 1 && day <= 32, 'Day must be between 1 and 32');

  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final int second;

  static const List<String> monthNamesEn = [
    'Baisakh',
    'Jestha',
    'Ashadh',
    'Shrawan',
    'Bhadra',
    'Ashwin',
    'Kartik',
    'Mangsir',
    'Poush',
    'Magh',
    'Falgun',
    'Chaitra',
  ];

  static const List<String> monthNamesNp = [
    'वैशाख',
    'जेठ',
    'असार',
    'साउन',
    'भदौ',
    'असोज',
    'कार्तिक',
    'मंसिर',
    'पुस',
    'माघ',
    'फागुन',
    'चैत',
  ];

  static const List<String> weekDaysEn = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  /// Lookup map for days in each BS month from year 2000 to 2090 BS.
  static const Map<int, List<int>> bsMonthData = {
    2000: [30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31],
    2001: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2002: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2003: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2004: [30, 32, 31, 32, 31, 30, 30, 30, 29, 30, 29, 31],
    2005: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2006: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2007: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2008: [31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 29, 31],
    2009: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2010: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2011: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2012: [31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30],
    2013: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2014: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2015: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2016: [31, 31, 31, 32, 31, 31, 29, 30, 30, 29, 30, 30],
    2017: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2018: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2019: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2020: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
    2021: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2022: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2023: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2024: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
    2025: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2026: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2027: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2028: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
    2029: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2030: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2031: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2032: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
    2033: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2034: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2035: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2036: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
    2037: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2038: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2039: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2040: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
    2041: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2042: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2043: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2044: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
    2045: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2046: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2047: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2048: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
    2049: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2050: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2051: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2052: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
    2053: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2054: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2055: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2056: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
    2057: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2058: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2059: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2060: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
    2061: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2062: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2063: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2064: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
    2065: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2066: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2067: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2068: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
    2069: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2070: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2071: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2072: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
    2073: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2074: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2075: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2076: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
    2077: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2078: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2079: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2080: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
    2081: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2082: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2083: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2084: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
    2085: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2086: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
    2087: [31, 32, 31, 32, 31, 30, 30, 30, 29, 29, 30, 31],
    2088: [31, 31, 31, 32, 31, 31, 30, 29, 30, 29, 30, 30],
    2089: [31, 31, 32, 31, 31, 31, 30, 29, 30, 29, 30, 30],
    2090: [31, 31, 32, 32, 31, 30, 30, 29, 30, 29, 30, 30],
  };

  // Base reference date: 2000 Baisakh 1 = 1943-04-14 (Wednesday = 3 in Dart 1..7)
  static final DateTime _refAd = DateTime(1943, 4, 14);
  static const int _refBsYear = 2000;

  /// Total days in the given BS month.
  static int getDaysInBsMonth(int year, int month) {
    if (!bsMonthData.containsKey(year)) return 30;
    return bsMonthData[year]![month - 1];
  }

  /// Converts a Gregorian AD [DateTime] to a [NepaliDate].
  factory NepaliDate.fromDateTime(DateTime dt) {
    var totalDays = dt.difference(_refAd).inDays;
    if (totalDays < 0) {
      // Fallback for dates before 2000 BS
      return NepaliDate(year: 2000, month: 1, day: 1, hour: dt.hour, minute: dt.minute, second: dt.second);
    }

    var currentYear = _refBsYear;
    var currentMonth = 1;

    while (true) {
      final daysInYear = bsMonthData[currentYear]?.reduce((a, b) => a + b) ?? 365;
      if (totalDays >= daysInYear) {
        totalDays -= daysInYear;
        currentYear++;
      } else {
        break;
      }
    }

    final months = bsMonthData[currentYear] ?? List.filled(12, 30);
    for (var i = 0; i < 12; i++) {
      final daysInMonth = months[i];
      if (totalDays >= daysInMonth) {
        totalDays -= daysInMonth;
        currentMonth++;
      } else {
        break;
      }
    }

    final day = totalDays + 1;
    return NepaliDate(
      year: currentYear,
      month: currentMonth,
      day: day,
      hour: dt.hour,
      minute: dt.minute,
      second: dt.second,
    );
  }

  /// Converts this [NepaliDate] to a Gregorian AD [DateTime].
  DateTime toDateTime() {
    var totalDays = 0;

    for (var y = _refBsYear; y < year; y++) {
      final daysInYear = bsMonthData[y]?.reduce((a, b) => a + b) ?? 365;
      totalDays += daysInYear;
    }

    final months = bsMonthData[year] ?? List.filled(12, 30);
    for (var m = 1; m < month; m++) {
      totalDays += months[m - 1];
    }

    totalDays += (day - 1);

    return _refAd.add(Duration(
      days: totalDays,
      hours: hour,
      minutes: minute,
      seconds: second,
    ));
  }

  /// Weekday (1 = Monday, 7 = Sunday).
  int get weekday => toDateTime().weekday;

  String get monthNameEn => monthNamesEn[month - 1];
  String get monthNameNp => monthNamesNp[month - 1];

  /// Formatted string "Baisakh 2081 BS"
  String get monthYearEn => '$monthNameEn $year BS';

  /// Formatted string "वैशाख २०८१"
  String get monthYearNp => '$monthNameNp $year';

  NepaliDate addMonths(int months) {
    var newMonth = month + months;
    var newYear = year;

    while (newMonth > 12) {
      newMonth -= 12;
      newYear++;
    }
    while (newMonth < 1) {
      newMonth += 12;
      newYear--;
    }

    final maxDays = getDaysInBsMonth(newYear, newMonth);
    final newDay = day > maxDays ? maxDays : day;

    return NepaliDate(
      year: newYear,
      month: newMonth,
      day: newDay,
      hour: hour,
      minute: minute,
      second: second,
    );
  }

  @override
  int compareTo(NepaliDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    if (day != other.day) return day.compareTo(other.day);
    if (hour != other.hour) return hour.compareTo(other.hour);
    return minute.compareTo(other.minute);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NepaliDate &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => year.hashCode ^ month.hashCode ^ day.hashCode;

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}
