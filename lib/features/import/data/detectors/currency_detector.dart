import '../parsers/models/raw_sheet_data.dart';

/// Detects currency from import file data
/// 
/// Detection strategies:
/// 1. Check for currency column in headers
/// 2. Detect currency symbols in amount cells
/// 3. Detect currency codes (USD, NGN, EUR, etc.) in amount cells or adjacent cells
class CurrencyDetector {
  /// Currency symbols and their codes
  static const Map<String, String> _currencySymbols = {
    '\$': 'USD',
    '€': 'EUR',
    '£': 'GBP',
    '¥': 'JPY',
    '₹': 'INR',
    '₦': 'NGN',
    '₱': 'PHP',
    'R': 'ZAR',
    'KSh': 'KES',
    'GH₵': 'GHS',
    'C\$': 'CAD',
    'A\$': 'AUD',
  };

  /// Currency codes (ISO 4217)
  static const List<String> _currencyCodes = [
    'USD', 'EUR', 'GBP', 'JPY', 'CNY', 'INR', 'NGN', 'ZAR', 'KES', 'GHS',
    'CAD', 'AUD', 'CHF', 'PHP', 'PKR', 'BDT', 'IDR', 'EGP',
  ];

  /// Detect currency from sheet data
  /// 
  /// Returns detected currency code, or null if not detected
  String? detectCurrency(RawSheetData sheet, int? currencyColumn) {
    // Strategy 1: Check currency column if available
    if (currencyColumn != null) {
      final currency = _detectFromColumn(sheet, currencyColumn);
      if (currency != null) return currency;
    }

    // Strategy 2: Scan amount cells for currency symbols/codes
    return _detectFromAmountCells(sheet);
  }

  /// Detect currency from a specific column
  String? _detectFromColumn(RawSheetData sheet, int column) {
    // Check header first
    for (int row = 0; row < _min(5, sheet.rowCount); row++) {
      final cell = sheet.getCell(row, column);
      if (cell != null) {
        final currency = _parseCurrencyFromText(cell.toString());
        if (currency != null) return currency;
      }
    }

    // Check data rows (sample first 10 rows)
    for (int row = 0; row < _min(10, sheet.rowCount); row++) {
      final cell = sheet.getCell(row, column);
      if (cell != null) {
        final currency = _parseCurrencyFromText(cell.toString());
        if (currency != null) return currency;
      }
    }

    return null;
  }

  /// Detect currency by scanning amount cells for symbols/codes
  String? _detectFromAmountCells(RawSheetData sheet) {
    final currencyCounts = <String, int>{};

    // Sample first 20 rows to detect currency pattern
    for (int row = 0; row < _min(20, sheet.rowCount); row++) {
      final rowData = sheet.getRow(row);
      
      for (int col = 0; col < rowData.length; col++) {
        final cell = rowData[col];
        if (cell == null) continue;

        final cellStr = cell.toString();
        
        // Check for currency symbols
        for (final entry in _currencySymbols.entries) {
          if (cellStr.contains(entry.key)) {
            currencyCounts[entry.value] = (currencyCounts[entry.value] ?? 0) + 1;
          }
        }

        // Check for currency codes (3-letter uppercase)
        for (final code in _currencyCodes) {
          final pattern = RegExp('\\b$code\\b', caseSensitive: false);
          if (pattern.hasMatch(cellStr)) {
            currencyCounts[code] = (currencyCounts[code] ?? 0) + 1;
          }
        }
      }
    }

    // Return most frequently detected currency
    if (currencyCounts.isEmpty) return null;
    
    final sorted = currencyCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Only return if detected with some confidence (at least 2 occurrences)
    if (sorted.first.value >= 2) {
      return sorted.first.key;
    }

    return null;
  }

  /// Parse currency code from text
  String? _parseCurrencyFromText(String text) {
    final normalized = text.trim().toUpperCase();

    // Check for exact currency code match
    for (final code in _currencyCodes) {
      if (normalized == code || normalized.contains(code)) {
        return code;
      }
    }

    // Check for currency symbols
    for (final entry in _currencySymbols.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  int _min(int a, int b) => a < b ? a : b;
}
