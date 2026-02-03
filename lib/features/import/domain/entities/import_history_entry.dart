/// Entry in import history for undo functionality
class ImportHistoryEntry {
  final String importId;
  final DateTime importedAt;
  final String fileName;
  final int expenseCount;
  final double totalAmount;
  final bool canUndo;
  final bool isUndone;
  final DateTime? undoneAt;

  const ImportHistoryEntry({
    required this.importId,
    required this.importedAt,
    required this.fileName,
    required this.expenseCount,
    required this.totalAmount,
    required this.canUndo,
    this.isUndone = false,
    this.undoneAt,
  });

  /// Undo available for 24 hours after import
  bool get isUndoAvailable =>
    canUndo && 
    !isUndone && 
    DateTime.now().difference(importedAt).inHours < 24;
}
