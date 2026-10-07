import 'package:nepali_utils/nepali_utils.dart';

class NepaliCalendarConverter {
  NepaliCalendarConverter._();

  /// Converts standard Gregorian (AD) DateTime to Bikram Sambat (BS) NepaliDateTime
  static NepaliDateTime toBS(DateTime adDate) {
    return adDate.toNepaliDateTime();
  }

  /// Converts Bikram Sambat (BS) NepaliDateTime to Gregorian (AD) DateTime
  static DateTime toAD(NepaliDateTime bsDate) {
    return bsDate.toDateTime();
  }

  /// Current BS date and time
  static NepaliDateTime nowBS() {
    return NepaliDateTime.now();
  }

  /// Formats date according to BS format: e.g. "२०८३ कार्तिक २, आइतबार" or "2083 Kartik 2, Sunday"
  static String formatBS(DateTime adDate, {bool inEnglish = true}) {
    final bs = toBS(adDate);
    if (inEnglish) {
      return NepaliDateFormat('yyyy MMMM d, EEEE', Language.english).format(bs);
    }
    return NepaliDateFormat('yyyy MMMM d, EEEE', Language.nepali).format(bs);
  }

  /// Formats short BS string: e.g. "Kartik 2, 2083"
  static String formatBSShort(DateTime adDate) {
    final bs = toBS(adDate);
    return NepaliDateFormat('MMMM d, yyyy', Language.english).format(bs);
  }

  /// Total days in a given Nepali month of a year using nepali_utils
  static int getDaysInNepaliMonth(int year, int month) {
    return NepaliDateTime(year, month, 1).totalDays;
  }

  /// Weekday of the 1st day of a Nepali month (1 = Sunday, 2 = Monday, ..., 7 = Saturday)
  static int getNepaliMonthStartWeekday(int year, int month) {
    return NepaliDateTime(year, month, 1).weekday;
  }

  /// English name of a Nepali month (1 = Baisakh, 2 = Jestha, ..., 12 = Chaitra)
  static String getNepaliMonthName(int month) {
    const months = [
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
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }

  /// Converts standard English digits (0-9) to Nepali Unicode numerals (०-९)
  static String toNepaliDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const nepali = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    var result = input;
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], nepali[i]);
    }
    return result;
  }

  /// Formats short BS string in Devanagari script: e.g. "कार्तिक २, २०८३"
  static String formatBSDevanagari(DateTime adDate) {
    final bs = toBS(adDate);
    return NepaliDateFormat('MMMM d, yyyy', Language.nepali).format(bs);
  }
}
