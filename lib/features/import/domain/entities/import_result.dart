/// Result of an import operation
class ImportResult {
  final String importId;
  final DateTime importedAt;
  final String fileName;
  final int totalExpenses;
  final int successfulExpenses;
  final int failedExpenses;
  final double totalAmount;
  final List<ImportError> errors;
  final bool canUndo;

  const ImportResult({
    required this.importId,
    required this.importedAt,
    required this.fileName,
    required this.totalExpenses,
    required this.successfulExpenses,
    required this.failedExpenses,
    required this.totalAmount,
    this.errors = const [],
    this.canUndo = true,
  });

  bool get isFullySuccessful => failedExpenses == 0;
  bool get isPartialSuccess => successfulExpenses > 0 && failedExpenses > 0;
  bool get isFailed => successfulExpenses == 0;
}

/// Error that occurred during import
class ImportError {
  final int rowIndex;
  final String errorMessage;
  final String? expenseTitle;

  const ImportError({
    required this.rowIndex,
    required this.errorMessage,
    this.expenseTitle,
  });
}
