
/// Production-grade amount parser supporting multiple currency formats.
///
/// Handles:
/// - Multiple currency symbols (₦, $, €, £, ₹, ¥, etc.)
/// - Different decimal separators (1,200.50 vs 1.200,50)
/// - Thousands separators (commas, periods, spaces)
/// - Negative numbers in parentheses: (1,200.50)
/// - Credit/Debit indicators: CR, DR, -, +
/// - Integer amounts (4500, 6500)
/// - Mixed formats in same file
///
/// Returns parsed amount with currency detection.
class AmountParser {
  /// Supported currency symbols and their codes.
  static const Map<String, String> currencySymbols = {
    '₦': 'NGN', // Nigerian Naira
    '\$': 'USD', // US Dollar
    '€': 'EUR', // Euro
    '£': 'GBP', // British Pound
    '₹': 'INR', // Indian Rupee
    '¥': 'JPY', // Japanese Yen / Chinese Yuan
    'R': 'ZAR', // South African Rand
    'KSh': 'KES', // Kenyan Shilling
    '₵': 'GHS', // Ghanaian Cedi
    'C\$': 'CAD', // Canadian Dollar
    'A\$': 'AUD', // Australian Dollar
    'Fr': 'CHF', // Swiss Franc
  };

  /// Parses an amount string and returns parsed result.
  ///
  /// Handles all common formats and edge cases.
  /// Returns null if amount cannot be parsed.
  static AmountParseResult? parse(String amountStr) {
    if (amountStr.isEmpty || amountStr.trim().isEmpty) {
      return null;
    }

    final trimmed = amountStr.trim();

    // Detect if negative (parentheses or minus sign)
    bool isNegative = false;
    String workingStr = trimmed;

    // Check for parentheses (accounting style: (1,200.50) = -1200.50)
    if (workingStr.startsWith('(') && workingStr.endsWith(')')) {
      isNegative = true;
      workingStr = workingStr.substring(1, workingStr.length - 1).trim();
    }

    // Check for minus sign
    if (workingStr.startsWith('-')) {
      isNegative = true;
      workingStr = workingStr.substring(1).trim();
    }

    // Check for credit/debit indicators
    final upperStr = workingStr.toUpperCase();
    if (upperStr.contains(' CR') || upperStr.endsWith('CR')) {
      // Credit = negative (money coming in)
      isNegative = true;
      workingStr = workingStr.replaceAll(RegExp(r'\s*CR\s*', caseSensitive: false), '').trim();
    }
    if (upperStr.contains(' DR') || upperStr.endsWith('DR')) {
      // Debit = positive (money going out)
      isNegative = false;
      workingStr = workingStr.replaceAll(RegExp(r'\s*DR\s*', caseSensitive: false), '').trim();
    }

    // Detect currency symbol
    String? detectedCurrency;
    for (final entry in currencySymbols.entries) {
      if (workingStr.contains(entry.key)) {
        detectedCurrency = entry.value;
        // Remove currency symbol
        workingStr = workingStr.replaceAll(entry.key, '').trim();
        break;
      }
    }

    // Try to detect currency code (NGN, USD, etc.)
    if (detectedCurrency == null) {
      final currencyCodePattern = RegExp(r'\b(USD|EUR|GBP|NGN|INR|JPY|CAD|AUD|CHF|ZAR|KES|GHS)\b', caseSensitive: false);
      final match = currencyCodePattern.firstMatch(workingStr);
      if (match != null) {
        detectedCurrency = match.group(1)?.toUpperCase();
        workingStr = workingStr.replaceAll(currencyCodePattern, '').trim();
      }
    }

    // Detect decimal separator style
    // European: 1.200,50 (period for thousands, comma for decimals)
    // US/International: 1,200.50 (comma for thousands, period for decimals)
    final hasEuropeanDecimal = workingStr.contains(',') && 
        workingStr.contains('.') &&
        workingStr.indexOf(',') > workingStr.indexOf('.');

    if (hasEuropeanDecimal) {
      // European format: 1.200,50
      workingStr = workingStr.replaceAll('.', ''); // Remove thousands separator
      workingStr = workingStr.replaceAll(',', '.'); // Convert decimal separator
    } else {
      // US/International format: 1,200.50 or 1200.50
      // Remove thousands separators (commas, spaces, periods)
      workingStr = workingStr.replaceAll(RegExp(r'[\s,]'), '');
      // Keep only one period as decimal separator
      final parts = workingStr.split('.');
      if (parts.length > 2) {
        // Multiple periods - likely thousands separator
        workingStr = parts.join(''); // Remove all periods
      }
    }

    // Extract numeric value
    // Allow digits, single decimal point, and optional minus
    final numericPattern = RegExp(r'^-?\d+\.?\d*$');
    if (!numericPattern.hasMatch(workingStr)) {
      // Try to extract just the numbers
      final numberOnly = workingStr.replaceAll(RegExp(r'[^\d.-]'), '');
      if (numberOnly.isEmpty) {
        return null;
      }
      workingStr = numberOnly;
    }

    // Parse as double
    final amount = double.tryParse(workingStr);
    if (amount == null) {
      // Try parsing as integer (e.g., 4500)
      final intAmount = int.tryParse(workingStr);
      if (intAmount != null) {
        return AmountParseResult(
          amount: intAmount.toDouble(),
          currency: detectedCurrency,
          isNegative: isNegative,
          originalString: trimmed,
        );
      }
      return null;
    }

    // Apply negative sign
    final finalAmount = isNegative ? -amount.abs() : amount.abs();

    return AmountParseResult(
      amount: finalAmount,
      currency: detectedCurrency,
      isNegative: isNegative,
      originalString: trimmed,
    );
  }

  /// Parses multiple amounts and detects if they're in cents/smallest unit.
  ///
  /// If most amounts are integers > 1000, they might be in cents.
  /// Returns conversion factor (1.0 for normal, 0.01 for cents).
  static double detectAmountUnit(List<String> amountStrings) {
    if (amountStrings.isEmpty) return 1.0;

    int integerCount = 0;
    int largeIntegerCount = 0; // > 1000

    for (final str in amountStrings.take(100)) { // Sample first 100
      final result = parse(str);
      if (result != null) {
        final amount = result.amount.abs();
        if (amount == amount.roundToDouble()) {
          integerCount++;
          if (amount > 1000) {
            largeIntegerCount++;
          }
        }
      }
    }

    // If > 80% are large integers, likely in cents
    if (integerCount > 0 && largeIntegerCount / integerCount > 0.8) {
      return 0.01; // Convert from cents
    }

    return 1.0; // Normal units
  }
}

/// Result of amount parsing.
class AmountParseResult {
  final double amount;
  final String? currency;
  final bool isNegative;
  final String originalString;

  AmountParseResult({
    required this.amount,
    this.currency,
    required this.isNegative,
    required this.originalString,
  });

  /// Returns absolute amount (always positive).
  double get absoluteAmount => amount.abs();

  /// Returns formatted string for display.
  String toDisplayString() {
    final abs = absoluteAmount;
    if (isNegative) {
      return '-${abs.toStringAsFixed(2)}';
    }
    return abs.toStringAsFixed(2);
  }
}

