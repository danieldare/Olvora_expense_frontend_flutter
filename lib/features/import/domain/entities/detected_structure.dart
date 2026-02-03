/// Type of file structure detected
enum FileStructureType {
  /// Each row is one expense: Date | Amount | Category | Description
  transactional,
  
  /// Pivot table: Months as columns, categories as rows (or vice versa)
  pivotMonthColumns,
  
  /// Pivot table: Categories as columns, months as rows
  pivotMonthRows,
  
  /// Could not determine structure
  unknown,
}

/// Result of structure detection analysis
class DetectedStructure {
  final FileStructureType type;
  final double confidence;           // 0.0 - 1.0
  final ColumnMapping? columnMapping; // For transactional
  final PivotMapping? pivotMapping;   // For pivot tables
  final int? detectedYear;           // null if ambiguous
  final List<String> detectedMonths;
  final String? suggestedYear;
  final List<SkippedRow> skippedRows;

  const DetectedStructure({
    required this.type,
    required this.confidence,
    this.columnMapping,
    this.pivotMapping,
    this.detectedYear,
    this.detectedMonths = const [],
    this.suggestedYear,
    this.skippedRows = const [],
  });

  bool get needsYearInput => detectedYear == null && detectedMonths.isNotEmpty;
  bool get isHighConfidence => confidence >= 0.8;
}

/// Column mapping for transactional structure
class ColumnMapping {
  final int? dateColumn;
  final int amountColumn;
  final int? categoryColumn;
  final int? descriptionColumn;
  final int? merchantColumn;
  final int? currencyColumn;
  final int headerRow;          // Which row contains headers (0-indexed)
  final int dataStartRow;       // Which row data starts (0-indexed)

  const ColumnMapping({
    this.dateColumn,
    required this.amountColumn,
    this.categoryColumn,
    this.descriptionColumn,
    this.merchantColumn,
    this.currencyColumn,
    this.headerRow = 0,
    this.dataStartRow = 1,
  });
}

/// Mapping for pivot table structure
class PivotMapping {
  final int categoryColumn;           // Column containing category names
  final int categoryValueColumn;      // Column containing amounts (relative to month)
  final Map<String, int> monthColumns; // "January" -> column index
  final int dataStartRow;
  final bool monthsInFirstRow;

  const PivotMapping({
    required this.categoryColumn,
    required this.categoryValueColumn,
    required this.monthColumns,
    required this.dataStartRow,
    this.monthsInFirstRow = true,
  });
}

/// Information about a skipped row
class SkippedRow {
  final int rowIndex;
  final SkipReason reason;
  final String? description;

  const SkippedRow({
    required this.rowIndex,
    required this.reason,
    this.description,
  });
}

/// Reason why a row was skipped
enum SkipReason {
  emptyRow,
  headerRow,
  totalRow,
  zeroAmount,
  unparseable,
}
