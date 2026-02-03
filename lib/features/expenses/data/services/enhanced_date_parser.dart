import 'package:intl/intl.dart';

/// Enhanced date parser with auto-detection and format learning.
///
/// Features:
/// - Auto-detects date format from sample data
/// - Supports 20+ date formats
/// - Handles text months (January, Jan, etc.)
/// - Detects locale-specific formats
/// - Returns format suggestions for user confirmation
class EnhancedDateParser {
  /// All supported date formats ordered by commonality.
  static final List<DateFormat> _formats = [
    // ISO 8601 (most reliable)
    DateFormat('yyyy-MM-dd'),
    DateFormat('yyyy-MM-dd HH:mm:ss'),
    DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'"),
    DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"),

    // US formats
    DateFormat('MM/dd/yyyy'),
    DateFormat('MM/dd/yyyy HH:mm:ss'),
    DateFormat('MM-dd-yyyy'),
    DateFormat('M/d/yyyy'),
    DateFormat('M/d/yy'),

    // European formats
    DateFormat('dd/MM/yyyy'),
    DateFormat('dd-MM-yyyy'),
    DateFormat('dd.MM.yyyy'),
    DateFormat('d/M/yyyy'),
    DateFormat('d/M/yy'),

    // Written formats (US)
    DateFormat('MMM dd, yyyy'),
    DateFormat('MMMM dd, yyyy'),
    DateFormat('MMM d, yyyy'),
    DateFormat('MMMM d, yyyy'),

    // Written formats (European)
    DateFormat('dd MMM yyyy'),
    DateFormat('dd MMMM yyyy'),
    DateFormat('d MMM yyyy'),
    DateFormat('d MMMM yyyy'),

    // With time
    DateFormat('MM/dd/yyyy HH:mm:ss'),
    DateFormat('dd/MM/yyyy HH:mm:ss'),
  ];

  /// Parses a date string with format auto-detection.
  ///
  /// Returns DateParseResult with parsed date and detected format.
  static DateParseResult? parse(String dateString) {
    if (dateString.isEmpty || dateString.trim().isEmpty) {
      return null;
    }

    final trimmed = dateString.trim();

    // Fast path 1: Try ISO 8601 parse first (handles most cases)
    try {
      final date = DateTime.parse(trimmed);
      return DateParseResult(
        date: date,
        format: 'ISO 8601',
        confidence: 1.0,
      );
    } catch (e) {
      // Continue to other formats
    }

    // Fast path 2: Try timestamp
    final timestamp = int.tryParse(trimmed);
    if (timestamp != null && timestamp > 0) {
      final date = timestamp < 10000000000
          ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
          : DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateParseResult(
        date: date,
        format: 'Unix timestamp',
        confidence: 1.0,
      );
    }

    // Try all formats
    for (final format in _formats) {
      try {
        final date = format.parseStrict(trimmed);
        return DateParseResult(
          date: date,
          format: format.pattern ?? 'Unknown',
          confidence: 0.9,
        );
      } catch (e) {
        // Try lenient parse
        try {
          final date = format.parse(trimmed);
          return DateParseResult(
            date: date,
            format: format.pattern ?? 'Unknown',
            confidence: 0.8,
          );
        } catch (e2) {
          // Continue to next format
        }
      }
    }

    return null;
  }

  /// Auto-detects date format from sample dates.
  ///
  /// Analyzes multiple date strings to determine the most likely format.
  /// Returns detected format and confidence score.
  static FormatDetectionResult detectFormat(List<String> dateStrings) {
    if (dateStrings.isEmpty) {
      return FormatDetectionResult(
        format: null,
        confidence: 0.0,
        sampleFormat: null,
      );
    }

    final formatCounts = <String, int>{};
    final formatSamples = <String, String>{};

    // Try to parse each date string with each format
    for (final dateStr in dateStrings.take(20)) { // Sample first 20
      for (final format in _formats) {
        try {
          format.parseStrict(dateStr.trim());
          final pattern = format.pattern ?? 'Unknown';
          formatCounts[pattern] = (formatCounts[pattern] ?? 0) + 1;
          if (!formatSamples.containsKey(pattern)) {
            formatSamples[pattern] = dateStr;
          }
        } catch (e) {
          // Format doesn't match
        }
      }
    }

    // Find most common format
    if (formatCounts.isEmpty) {
      return FormatDetectionResult(
        format: null,
        confidence: 0.0,
        sampleFormat: null,
      );
    }

    final mostCommon = formatCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    final totalSamples = dateStrings.length.clamp(1, 20);
    final confidence = (mostCommon.value / totalSamples).clamp(0.0, 1.0);

    return FormatDetectionResult(
      format: mostCommon.key,
      confidence: confidence,
      sampleFormat: formatSamples[mostCommon.key] ?? dateStrings.first,
    );
  }

  /// Suggests format fixes for a list of date strings.
  ///
  /// Returns suggestions like "Most dates appear to be in DD/MM/YYYY format.
  /// Apply this format to all rows?"
  static List<FormatSuggestion> suggestFixes(List<String> dateStrings) {
    final suggestions = <FormatSuggestion>[];

    // Detect format
    final detection = detectFormat(dateStrings);
    if (detection.format != null && detection.confidence > 0.7) {
      final format = detection.format;
      if (format != null) {
        suggestions.add(FormatSuggestion(
          message: 'Most dates appear to be in $format format. '
              'Apply this format to all rows?',
          format: format,
          confidence: detection.confidence,
          action: 'Apply format',
        ));
      }
    }

    // Check for ambiguous dates (could be MM/DD or DD/MM)
    final ambiguousDates = dateStrings.where((d) {
      final parts = d.split('/');
      if (parts.length == 3) {
        final first = int.tryParse(parts[0]);
        final second = int.tryParse(parts[1]);
        if (first != null && second != null) {
          // If first part > 12, it's likely DD/MM
          // If second part > 12, it's likely MM/DD
          return (first <= 12 && second <= 12);
        }
      }
      return false;
    }).length;

    if (ambiguousDates > dateStrings.length * 0.3) {
      suggestions.add(FormatSuggestion(
        message: 'Some dates could be interpreted as either MM/DD/YYYY or DD/MM/YYYY. '
            'Please confirm which format to use.',
        format: null,
        confidence: 0.5,
        action: 'Select format',
      ));
    }

    return suggestions;
  }
}

/// Result of date parsing.
class DateParseResult {
  final DateTime date;
  final String format;
  final double confidence; // 0.0 to 1.0

  DateParseResult({
    required this.date,
    required this.format,
    required this.confidence,
  });
}

/// Result of format detection.
class FormatDetectionResult {
  final String? format;
  final double confidence; // 0.0 to 1.0
  final String? sampleFormat; // Example date string

  FormatDetectionResult({
    required this.format,
    required this.confidence,
    required this.sampleFormat,
  });
}

/// Format suggestion for user.
class FormatSuggestion {
  final String message;
  final String? format;
  final double confidence;
  final String action;

  FormatSuggestion({
    required this.message,
    required this.format,
    required this.confidence,
    required this.action,
  });
}

