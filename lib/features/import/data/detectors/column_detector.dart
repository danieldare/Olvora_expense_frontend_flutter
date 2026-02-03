import 'dart:math' show min;
import 'date_detector.dart';
import '../parsers/models/raw_sheet_data.dart';

/// Result of column detection
class ColumnDetectionResult {
  final int? dateColumn;
  final int? amountColumn;
  final int? categoryColumn;
  final int? descriptionColumn;
  final int? merchantColumn;
  final int? currencyColumn;
  final int headerRow;
  final int dataStartRow;
  final double confidence;

  const ColumnDetectionResult({
    this.dateColumn,
    this.amountColumn,
    this.categoryColumn,
    this.descriptionColumn,
    this.merchantColumn,
    this.currencyColumn,
    required this.headerRow,
    required this.dataStartRow,
    required this.confidence,
  });
}

/// Detects which columns contain which data types
class ColumnDetector {
  final DateDetector _dateDetector = DateDetector();

  // Keywords for column detection (case-insensitive)
  static const _dateKeywords = ['date', 'time', 'when', 'day', 'tarikh'];
  static const _amountKeywords = ['amount', 'sum', 'total', 'price', 'cost', 'value', 'debit', 'credit', 'payment', 'spend'];
  static const _categoryKeywords = ['category', 'type', 'group', 'class', 'kind'];
  static const _descriptionKeywords = ['description', 'desc', 'details', 'note', 'notes', 'memo', 'narration', 'particulars'];
  static const _merchantKeywords = ['merchant', 'vendor', 'store', 'shop', 'payee', 'beneficiary', 'recipient'];
  static const _currencyKeywords = ['currency', 'curr', 'ccy', 'iso'];

  ColumnDetectionResult detectColumns(RawSheetData sheet) {
    // Find header row (first row with mostly string values that look like headers)
    int headerRow = _findHeaderRow(sheet);
    int dataStartRow = headerRow + 1;

    // Get header values
    final headers = sheet.getRow(headerRow)
      .map((h) => h?.toString().toLowerCase().trim() ?? '')
      .toList();

    // Detect by header keywords first
    int? dateCol = _findColumnByKeywords(headers, _dateKeywords);
    int? amountCol = _findColumnByKeywords(headers, _amountKeywords);
    int? categoryCol = _findColumnByKeywords(headers, _categoryKeywords);
    int? descriptionCol = _findColumnByKeywords(headers, _descriptionKeywords);
    int? merchantCol = _findColumnByKeywords(headers, _merchantKeywords);
    int? currencyCol = _findColumnByKeywords(headers, _currencyKeywords);

    // If no amount column found by keyword, detect by data type
    amountCol ??= _findAmountColumnByData(sheet, dataStartRow);

    // If no date column found by keyword, detect by data type
    dateCol ??= _findDateColumnByData(sheet, dataStartRow);

    // If no category column, look for low-cardinality string column
    categoryCol ??= _findCategoryColumnByData(sheet, dataStartRow, [dateCol, amountCol]);

    // If no description, look for high-cardinality string column
    descriptionCol ??= _findDescriptionColumnByData(
        sheet, 
        dataStartRow, 
        [dateCol, amountCol, categoryCol],
      );

    // Calculate confidence
    double confidence = _calculateConfidence(
      amountCol: amountCol,
      dateCol: dateCol,
      categoryCol: categoryCol,
    );

    return ColumnDetectionResult(
      dateColumn: dateCol,
      amountColumn: amountCol,
      categoryColumn: categoryCol,
      descriptionColumn: descriptionCol,
      merchantColumn: merchantCol,
      currencyColumn: currencyCol,
      headerRow: headerRow,
      dataStartRow: dataStartRow,
      confidence: confidence,
    );
  }

  int _findHeaderRow(RawSheetData sheet) {
    for (int row = 0; row < min(5, sheet.rowCount); row++) {
      final rowData = sheet.getRow(row);
      int stringCount = 0;
      int nonEmpty = 0;

      for (final cell in rowData) {
        if (cell == null || cell.toString().trim().isEmpty) continue;
        nonEmpty++;
        if (cell is String || (cell is! num && cell is! DateTime)) {
          stringCount++;
        }
      }

      // Header row: mostly strings, few numbers
      if (nonEmpty >= 2 && stringCount / nonEmpty > 0.6) {
        return row;
      }
    }
    return 0;
  }

  int? _findColumnByKeywords(List<String> headers, List<String> keywords) {
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i];
      if (keywords.any((kw) => header.contains(kw))) {
        return i;
      }
    }
    return null;
  }

  int? _findAmountColumnByData(RawSheetData sheet, int startRow) {
    // Find column with highest percentage of numeric values
    double bestScore = 0;
    int? bestCol;

    for (int col = 0; col < sheet.columnCount; col++) {
      int numericCount = 0;
      int totalCount = 0;
      double variance = 0;
      List<double> values = [];

      for (int row = startRow; row < min(startRow + 20, sheet.rowCount); row++) {
        final cell = sheet.getCell(row, col);
        if (cell == null) continue;
        totalCount++;

        final numValue = _parseNumber(cell);
        if (numValue != null && numValue > 0) {
          numericCount++;
          values.add(numValue);
        }
      }

      if (totalCount == 0) continue;

      // Calculate variance (amounts typically have high variance)
      if (values.length >= 3) {
        final mean = values.reduce((a, b) => a + b) / values.length;
        variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
      }

      final score = (numericCount / totalCount) * (variance > 1000 ? 1.2 : 1.0);
      if (score > bestScore && numericCount >= 3) {
        bestScore = score;
        bestCol = col;
      }
    }

    return bestCol;
  }

  int? _findDateColumnByData(RawSheetData sheet, int startRow) {
    for (int col = 0; col < sheet.columnCount; col++) {
      int dateCount = 0;
      int totalCount = 0;

      for (int row = startRow; row < min(startRow + 15, sheet.rowCount); row++) {
        final cell = sheet.getCell(row, col);
        if (cell == null || cell.toString().trim().isEmpty) continue;
        totalCount++;

        if (_dateDetector.parse(cell) != null) {
          dateCount++;
        }
      }

      if (totalCount >= 3 && dateCount / totalCount > 0.7) {
        return col;
      }
    }
    return null;
  }

  int? _findCategoryColumnByData(
    RawSheetData sheet, 
    int startRow, 
    List<int?> excludeCols,
  ) {
    // Category column: low cardinality (few unique values), all strings
    double bestScore = 0;
    int? bestCol;

    for (int col = 0; col < sheet.columnCount; col++) {
      if (excludeCols.contains(col)) continue;

      final uniqueValues = <String>{};
      int stringCount = 0;
      int totalCount = 0;

      for (int row = startRow; row < min(startRow + 30, sheet.rowCount); row++) {
        final cell = sheet.getCell(row, col);
        if (cell == null || cell.toString().trim().isEmpty) continue;
        totalCount++;

        final strValue = cell.toString().trim();
        if (_parseNumber(cell) == null && _dateDetector.parse(cell) == null) {
          stringCount++;
          uniqueValues.add(strValue.toLowerCase());
        }
      }

      if (totalCount < 3) continue;

      // Low cardinality: few unique values relative to total
      final cardinality = uniqueValues.length / totalCount;
      if (cardinality > 0 && cardinality < 0.5 && stringCount / totalCount > 0.8) {
        final score = (1 - cardinality) * (stringCount / totalCount);
        if (score > bestScore) {
          bestScore = score;
          bestCol = col;
        }
      }
    }

    return bestCol;
  }

  int? _findDescriptionColumnByData(
    RawSheetData sheet,
    int startRow,
    List<int?> excludeCols,
  ) {
    // Description column: high cardinality, longer strings
    double bestScore = 0;
    int? bestCol;

    for (int col = 0; col < sheet.columnCount; col++) {
      if (excludeCols.contains(col)) continue;

      final uniqueValues = <String>{};
      int stringCount = 0;
      int totalCount = 0;
      double avgLength = 0;

      for (int row = startRow; row < min(startRow + 20, sheet.rowCount); row++) {
        final cell = sheet.getCell(row, col);
        if (cell == null || cell.toString().trim().isEmpty) continue;
        totalCount++;

        final strValue = cell.toString().trim();
        if (_parseNumber(cell) == null) {
          stringCount++;
          uniqueValues.add(strValue);
          avgLength += strValue.length;
        }
      }

      if (totalCount < 3 || stringCount == 0) continue;
      avgLength /= stringCount;

      // High cardinality, decent length
      final cardinality = uniqueValues.length / totalCount;
      if (cardinality > 0.5 && avgLength > 5) {
        final score = cardinality * (avgLength / 20).clamp(0.5, 1.5);
        if (score > bestScore) {
          bestScore = score;
          bestCol = col;
        }
      }
    }

    return bestCol;
  }

  double _calculateConfidence({int? amountCol, int? dateCol, int? categoryCol}) {
    if (amountCol == null) return 0.0;
    
    double confidence = 0.4; // Base for having amount
    if (dateCol != null) confidence += 0.3;
    if (categoryCol != null) confidence += 0.2;
    
    return confidence.clamp(0.0, 1.0);
  }

  double? _parseNumber(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();

    final str = value.toString().replaceAll(RegExp(r'[\$€£¥₹₦₱฿₩R\s,]'), '');
    return double.tryParse(str);
  }
}
