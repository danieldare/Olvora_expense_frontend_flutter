/// Detects month names in various formats
class MonthDetector {
  static const _monthNames = {
    'january': 1, 'jan': 1,
    'february': 2, 'feb': 2,
    'march': 3, 'mar': 3,
    'april': 4, 'apr': 4,
    'may': 5,
    'june': 6, 'jun': 6,
    'july': 7, 'jul': 7,
    'august': 8, 'aug': 8,
    'september': 9, 'sep': 9, 'sept': 9,
    'october': 10, 'oct': 10,
    'november': 11, 'nov': 11,
    'december': 12, 'dec': 12,
  };

  static const _reverseMonths = {
    1: 'January', 2: 'February', 3: 'March', 4: 'April',
    5: 'May', 6: 'June', 7: 'July', 8: 'August',
    9: 'September', 10: 'October', 11: 'November', 12: 'December',
  };

  /// Detect if a string is a month name, return normalized name
  String? detectMonth(String value) {
    final normalized = value.toLowerCase().trim();
    final monthNum = _monthNames[normalized];
    if (monthNum == null) return null;
    return _reverseMonths[monthNum];
  }

  /// Convert month name to number (1-12)
  int? monthToNumber(String monthName) {
    final normalized = monthName.toLowerCase().trim();
    return _monthNames[normalized];
  }

  /// Convert month number to full name
  String? numberToMonth(int monthNum) {
    return _reverseMonths[monthNum];
  }

  /// Get last day of a month in a given year
  DateTime lastDayOfMonth(int year, int month) {
    // Get first day of next month, then subtract 1 day
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    return DateTime(nextYear, nextMonth, 1).subtract(const Duration(days: 1));
  }
}
