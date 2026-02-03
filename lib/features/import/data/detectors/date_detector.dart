import 'package:intl/intl.dart';

/// Detects and parses dates from various formats
class DateDetector {
  // Common date formats to try
  static final _formats = [
    DateFormat('yyyy-MM-dd'),
    DateFormat('dd/MM/yyyy'),
    DateFormat('MM/dd/yyyy'),
    DateFormat('dd-MM-yyyy'),
    DateFormat('dd.MM.yyyy'),
    DateFormat('d/M/yyyy'),
    DateFormat('d-M-yyyy'),
    DateFormat('yyyy/MM/dd'),
    DateFormat('dd MMM yyyy'),
    DateFormat('MMM dd, yyyy'),
    DateFormat('MMMM dd, yyyy'),
    DateFormat('dd MMMM yyyy'),
  ];

  DateTime? parse(dynamic value) {
    if (value == null) return null;
    
    // Already a DateTime
    if (value is DateTime) return value;
    
    // Excel serial date number
    if (value is num) {
      return _fromExcelSerial(value.toDouble());
    }

    final str = value.toString().trim();
    if (str.isEmpty) return null;

    // Try each format
    for (final format in _formats) {
      try {
        return format.parseStrict(str);
      } catch (_) {
        // Continue to next format
      }
    }

    // Try loose parsing as last resort
    return DateTime.tryParse(str);
  }

  DateTime? _fromExcelSerial(double serial) {
    // Excel dates are days since 1899-12-30
    // (with a bug for 1900 leap year)
    if (serial < 1 || serial > 2958465) return null; // Reasonable range
    
    final base = DateTime(1899, 12, 30);
    return base.add(Duration(days: serial.floor()));
  }
}
