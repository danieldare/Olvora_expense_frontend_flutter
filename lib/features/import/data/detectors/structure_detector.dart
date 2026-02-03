import 'column_detector.dart';
import 'month_detector.dart';
import 'date_detector.dart';
import '../parsers/models/raw_sheet_data.dart';
import '../../domain/entities/detected_structure.dart';

/// Main detector that identifies file structure (transactional vs pivot)
class StructureDetector {
  final ColumnDetector _columnDetector;
  final MonthDetector _monthDetector;
  final DateDetector _dateDetector;

  StructureDetector({
    ColumnDetector? columnDetector,
    MonthDetector? monthDetector,
    DateDetector? dateDetector,
  })  : _columnDetector = columnDetector ?? ColumnDetector(),
        _monthDetector = monthDetector ?? MonthDetector(),
        _dateDetector = dateDetector ?? DateDetector();

  DetectedStructure detect(RawSheetData sheet) {
    // First, check for pivot table structure (months as columns)
    final pivotResult = _detectPivotStructure(sheet);
    if (pivotResult != null && pivotResult.confidence > 0.7) {
      return pivotResult;
    }

    // Then, check for transactional structure
    final transactionalResult = _detectTransactionalStructure(sheet);
    if (transactionalResult != null && transactionalResult.confidence > 0.5) {
      return transactionalResult;
    }

    // If pivot detection had some confidence, prefer it
    if (pivotResult != null && pivotResult.confidence > 0.4) {
      return pivotResult;
    }

    // Return unknown
    return DetectedStructure(
      type: FileStructureType.unknown,
      confidence: 0.0,
      skippedRows: _findSkippableRows(sheet),
    );
  }

  DetectedStructure? _detectPivotStructure(RawSheetData sheet) {
    // Look for month names in first few rows
    for (int row = 0; row < _min(5, sheet.rowCount); row++) {
      final rowData = sheet.getRow(row);
      final monthColumns = <String, int>{};
      
      for (int col = 0; col < rowData.length; col++) {
        final value = rowData[col];
        if (value == null) continue;
        
        final monthName = _monthDetector.detectMonth(value.toString());
        if (monthName != null) {
          monthColumns[monthName] = col;
        }
      }

      // If we found at least 3 months, likely a pivot table
      if (monthColumns.length >= 3) {
        // Find category column (usually first non-empty column before months)
        int categoryCol = 0;
        final firstMonthCol = monthColumns.values.reduce((a, b) => _min(a, b));
        for (int c = 0; c < firstMonthCol; c++) {
          if (_columnHasCategories(sheet, c)) {
            categoryCol = c;
            break;
          }
        }

        // Detect year
        final yearInfo = _detectYear(sheet, monthColumns.keys.toList());

        final skippedRows = _findSkippableRows(sheet, dataStartRow: row + 1);

        return DetectedStructure(
          type: FileStructureType.pivotMonthColumns,
          confidence: _calculatePivotConfidence(monthColumns.length, sheet),
          pivotMapping: PivotMapping(
            categoryColumn: categoryCol,
            categoryValueColumn: 1, // Value is in same row, different col
            monthColumns: monthColumns,
            dataStartRow: row + 1,
            monthsInFirstRow: row == 0,
          ),
          detectedYear: yearInfo.year,
          suggestedYear: yearInfo.suggestion,
          detectedMonths: monthColumns.keys.toList(),
          skippedRows: skippedRows,
        );
      }
    }

    return null;
  }

  DetectedStructure? _detectTransactionalStructure(RawSheetData sheet) {
    final columnResult = _columnDetector.detectColumns(sheet);
    
    if (columnResult.amountColumn == null) {
      return null; // Must have at least an amount column
    }

    final skippedRows = _findSkippableRows(
      sheet, 
      dataStartRow: columnResult.dataStartRow,
    );

    // Detect year from date column if present
    int? year;
    String? suggestedYear;
    if (columnResult.dateColumn != null) {
      final dates = _extractDates(sheet, columnResult.dateColumn!, columnResult.dataStartRow);
      if (dates.isNotEmpty) {
        year = dates.first.year;
      }
    }

    return DetectedStructure(
      type: FileStructureType.transactional,
      confidence: columnResult.confidence,
      columnMapping: ColumnMapping(
        dateColumn: columnResult.dateColumn,
        amountColumn: columnResult.amountColumn!,
        categoryColumn: columnResult.categoryColumn,
        descriptionColumn: columnResult.descriptionColumn,
        merchantColumn: columnResult.merchantColumn,
        currencyColumn: columnResult.currencyColumn,
        headerRow: columnResult.headerRow,
        dataStartRow: columnResult.dataStartRow,
      ),
      detectedYear: year,
      suggestedYear: suggestedYear,
      skippedRows: skippedRows,
    );
  }

  bool _columnHasCategories(RawSheetData sheet, int col) {
    // A category column has repeating string values
    final values = <String>{};
    int nonEmpty = 0;
    
    for (int row = 1; row < _min(20, sheet.rowCount); row++) {
      final cell = sheet.getCell(row, col);
      if (cell != null && cell.toString().trim().isNotEmpty) {
        values.add(cell.toString().trim().toLowerCase());
        nonEmpty++;
      }
    }

    // Categories: multiple non-empty values, some repeats likely
    return nonEmpty >= 3 && values.length <= nonEmpty * 0.9;
  }

  double _calculatePivotConfidence(int monthsFound, RawSheetData sheet) {
    // More months = higher confidence
    double confidence = monthsFound / 12.0;
    
    // Bonus for having exactly 12 months
    if (monthsFound == 12) confidence += 0.1;
    
    return confidence.clamp(0.0, 1.0);
  }

  List<SkippedRow> _findSkippableRows(RawSheetData sheet, {int dataStartRow = 0}) {
    final skipped = <SkippedRow>[];
    
    for (int row = dataStartRow; row < sheet.rowCount; row++) {
      if (sheet.isRowEmpty(row)) {
        skipped.add(SkippedRow(
          rowIndex: row,
          reason: SkipReason.emptyRow,
        ));
        continue;
      }

      // Check for "Total" rows
      final firstCell = sheet.getCell(row, 0)?.toString().toLowerCase() ?? '';
      final secondCell = sheet.getCell(row, 1)?.toString().toLowerCase() ?? '';
      
      if (firstCell.contains('total') || secondCell.contains('total')) {
        skipped.add(SkippedRow(
          rowIndex: row,
          reason: SkipReason.totalRow,
          description: 'Total row',
        ));
      }
    }

    return skipped;
  }

  ({int? year, String? suggestion}) _detectYear(
    RawSheetData sheet, 
    List<String> months,
  ) {
    // Try to find year in the sheet
    for (int row = 0; row < _min(10, sheet.rowCount); row++) {
      for (int col = 0; col < sheet.columnCount; col++) {
        final cell = sheet.getCell(row, col);
        if (cell == null) continue;
        
        final str = cell.toString();
        final yearMatch = RegExp(r'\b(20\d{2})\b').firstMatch(str);
        if (yearMatch != null) {
          return (year: int.parse(yearMatch.group(1)!), suggestion: null);
        }
      }
    }

    // No year found, suggest based on current date and months
    final now = DateTime.now();
    final currentMonth = now.month;
    
    // If file has months past current month, likely previous year
    final hasLateMonths = months.any((m) {
      final monthNum = _monthDetector.monthToNumber(m);
      return monthNum != null && monthNum > currentMonth;
    });

    final suggestedYear = hasLateMonths 
      ? (now.year - 1).toString() 
      : now.year.toString();

    return (year: null, suggestion: suggestedYear);
  }

  List<DateTime> _extractDates(RawSheetData sheet, int col, int startRow) {
    final dates = <DateTime>[];
    
    for (int row = startRow; row < _min(startRow + 10, sheet.rowCount); row++) {
      final cell = sheet.getCell(row, col);
      if (cell == null) continue;
      
      final date = _dateDetector.parse(cell);
      if (date != null) dates.add(date);
    }
    
    return dates;
  }

  int _min(int a, int b) => a < b ? a : b;
}
