import 'enhanced_date_parser.dart';
import 'amount_parser.dart';
import 'column_mapper.dart';

/// Auto-fix suggestion system for import issues.
///
/// Analyzes import data and suggests fixes for common issues:
/// - Date format inconsistencies
/// - Amount format issues
/// - Missing category assignments
/// - Column mapping improvements
class AutoFixSuggestions {
  /// Analyzes data and generates fix suggestions.
  static List<FixSuggestion> analyze({
    required List<String> dateStrings,
    required List<String> amountStrings,
    required ColumnMapping columnMapping,
    List<String>? categoryStrings,
  }) {
    final suggestions = <FixSuggestion>[];

    // Date format suggestions
    final dateSuggestions = _analyzeDates(dateStrings);
    suggestions.addAll(dateSuggestions);

    // Amount format suggestions
    final amountSuggestions = _analyzeAmounts(amountStrings);
    suggestions.addAll(amountSuggestions);

    // Category suggestions
    if (categoryStrings != null) {
      final categorySuggestions = _analyzeCategories(categoryStrings);
      suggestions.addAll(categorySuggestions);
    }

    // Column mapping suggestions
    final mappingSuggestions = _analyzeMapping(columnMapping);
    suggestions.addAll(mappingSuggestions);

    return suggestions;
  }

  /// Analyzes dates and suggests format fixes.
  static List<FixSuggestion> _analyzeDates(List<String> dateStrings) {
    final suggestions = <FixSuggestion>[];

    if (dateStrings.isEmpty) return suggestions;

    // Detect format
    final detection = EnhancedDateParser.detectFormat(dateStrings);
    if (detection.format != null && detection.confidence > 0.7) {
      suggestions.add(
        FixSuggestion(
          type: FixType.dateFormat,
          title: 'Date Format Detected',
          message:
              'Most dates appear to be in ${detection.format} format. '
              'Would you like us to apply this format to all rows?',
          action: 'Apply Format',
          confidence: detection.confidence,
          data: {'format': detection.format},
        ),
      );
    }

    // Check for ambiguous dates
    final ambiguousCount = dateStrings.where((d) {
      final parts = d.split('/');
      if (parts.length == 3) {
        final first = int.tryParse(parts[0]);
        final second = int.tryParse(parts[1]);
        if (first != null && second != null && first <= 12 && second <= 12) {
          return true;
        }
      }
      return false;
    }).length;

    if (ambiguousCount > dateStrings.length * 0.3) {
      suggestions.add(
        FixSuggestion(
          type: FixType.dateAmbiguity,
          title: 'Date Format Ambiguity',
          message:
              'Some dates could be MM/DD/YYYY or DD/MM/YYYY. '
              'Please select which format to use.',
          action: 'Select Format',
          confidence: 0.8,
          data: {'ambiguousCount': ambiguousCount},
        ),
      );
    }

    return suggestions;
  }

  /// Analyzes amounts and suggests fixes.
  static List<FixSuggestion> _analyzeAmounts(List<String> amountStrings) {
    final suggestions = <FixSuggestion>[];

    if (amountStrings.isEmpty) return suggestions;

    // Detect if amounts are in cents
    final unit = AmountParser.detectAmountUnit(amountStrings);
    if (unit == 0.01) {
      suggestions.add(
        FixSuggestion(
          type: FixType.amountUnit,
          title: 'Amounts in Cents Detected',
          message:
              'Your amounts appear to be in cents (smallest currency unit). '
              'Would you like us to convert them to whole units?',
          action: 'Convert to Whole Units',
          confidence: 0.85,
          data: {'unit': unit},
        ),
      );
    }

    // Check for mixed currency formats
    final currencies = <String>{};
    for (final amountStr in amountStrings.take(50)) {
      final result = AmountParser.parse(amountStr);
      if (result?.currency != null) {
        currencies.add(result!.currency!);
      }
    }

    if (currencies.length > 1) {
      suggestions.add(
        FixSuggestion(
          type: FixType.mixedCurrency,
          title: 'Multiple Currencies Detected',
          message:
              'Your file contains ${currencies.length} different currencies: '
              '${currencies.join(", ")}. You may want to convert them to a single currency.',
          action: 'Review Currencies',
          confidence: 1.0,
          data: {'currencies': currencies.toList()},
        ),
      );
    }

    return suggestions;
  }

  /// Analyzes categories and suggests fixes.
  static List<FixSuggestion> _analyzeCategories(List<String> categoryStrings) {
    final suggestions = <FixSuggestion>[];

    if (categoryStrings.isEmpty) return suggestions;

    // Count uncategorized or invalid categories
    final invalidCategories = categoryStrings.where((c) {
      final normalized = c.toLowerCase().trim();
      return normalized.isEmpty ||
          normalized == 'uncategorized' ||
          normalized == 'other' ||
          normalized == 'misc';
    }).length;

    if (invalidCategories > categoryStrings.length * 0.3) {
      suggestions.add(
        FixSuggestion(
          type: FixType.missingCategories,
          title: 'Many Uncategorized Expenses',
          message:
              '$invalidCategories expenses don\'t have valid categories. '
              'We can assign them to "Uncategorized" and you can fix them later.',
          action: 'Assign to Uncategorized',
          confidence: 0.9,
          data: {'invalidCount': invalidCategories},
        ),
      );
    }

    return suggestions;
  }

  /// Analyzes column mapping and suggests improvements.
  static List<FixSuggestion> _analyzeMapping(ColumnMapping mapping) {
    final suggestions = <FixSuggestion>[];

    // Check for missing required mappings
    if (!mapping.isValid) {
      final missing = mapping.missingRequiredColumns;
      suggestions.add(
        FixSuggestion(
          type: FixType.missingMapping,
          title: 'Missing Column Mappings',
          message:
              'The following required columns are not mapped: ${missing.join(", ")}. '
              'Please map them to continue.',
          action: 'Map Columns',
          confidence: 1.0,
          data: {'missingColumns': missing},
        ),
      );
    }

    return suggestions;
  }
}

/// Fix suggestion model.
class FixSuggestion {
  final FixType type;
  final String title;
  final String message;
  final String action;
  final double confidence; // 0.0 to 1.0
  final Map<String, dynamic>? data;

  FixSuggestion({
    required this.type,
    required this.title,
    required this.message,
    required this.action,
    required this.confidence,
    this.data,
  });

  /// Returns true if this is a high-confidence suggestion.
  bool get isHighConfidence => confidence >= 0.8;
}

/// Types of fixes that can be suggested.
enum FixType {
  dateFormat,
  dateAmbiguity,
  amountUnit,
  mixedCurrency,
  missingCategories,
  missingMapping,
}

