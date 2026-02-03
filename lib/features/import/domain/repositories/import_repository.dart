import '../entities/import_result.dart';
import '../entities/import_history_entry.dart';
import '../entities/parsed_expense.dart';

/// Repository interface for import operations
abstract class ImportRepository {
  /// Batch import expenses
  Future<ImportResult> batchImportExpenses({
    required List<ParsedExpense> expenses,
    required String fileName,
  });

  /// Get import history
  Future<List<ImportHistoryEntry>> getImportHistory();

  /// Undo an import
  Future<void> undoImport(String importId);
}
