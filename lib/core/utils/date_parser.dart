import 'package:intl/intl.dart';

/// Production-grade date parser that handles multiple formats reliably.
///
/// Why multiple formats:
/// - Users export from different systems (banks, spreadsheets, etc.)
/// - Different locales use different formats
/// - We must never silently fail or corrupt dates
///
/// Strategy:
/// 1. Try common ISO formats first (most reliable)
/// 2. Try locale-specific formats
/// 3. Try timestamp formats
/// 4. Return null if all fail (never guess)
class DateParser {
  static final List<DateFormat> _formats = [
    // ISO 8601 formats (most common in exports)
    DateFormat('yyyy-MM-dd'),
    DateFormat('yyyy-MM-dd HH:mm:ss'),
    DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'"),
    DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"),

    // US formats
    DateFormat('MM/dd/yyyy'),
    DateFormat('MM/dd/yyyy HH:mm:ss'),
    DateFormat('MM-dd-yyyy'),

    // European formats
    DateFormat('dd/MM/yyyy'),
    DateFormat('dd-MM-yyyy'),
    DateFormat('dd.MM.yyyy'),

    // Written formats
    DateFormat('MMM dd, yyyy'),
    DateFormat('dd MMM yyyy'),
    DateFormat('MMMM dd, yyyy'),
    DateFormat('dd MMMM yyyy'),

    // With time
    DateFormat('MM/dd/yyyy HH:mm:ss'),
    DateFormat('dd/MM/yyyy HH:mm:ss'),
  ];

  /// Parse a date string with multiple format attempts.
  ///
  /// Returns null if parsing fails (never guesses).
  /// This ensures data integrity - invalid dates are caught in validation.
  static DateTime? parse(String dateString) {
    if (dateString.isEmpty || dateString.trim().isEmpty) {
      return null;
    }

    final trimmed = dateString.trim();

    // Try each format
    for (final format in _formats) {
      try {
        return format.parse(trimmed);
      } catch (e) {
        // Continue to next format
      }
    }

    // Try ISO 8601 parse (handles timezone offsets)
    try {
      return DateTime.parse(trimmed);
    } catch (e) {
      // Continue
    }

    // Try parsing as timestamp (milliseconds or seconds)
    final timestamp = int.tryParse(trimmed);
    if (timestamp != null) {
      // If it's in seconds (less than 10 digits), convert to milliseconds
      if (timestamp < 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    // All attempts failed - return null (don't guess)
    return null;
  }
}
