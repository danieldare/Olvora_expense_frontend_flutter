import '../../domain/repositories/import_repository.dart';
import '../../domain/entities/parsed_expense.dart';
import '../../domain/entities/import_result.dart';

/// Use case: Execute the import (save expenses to backend)
class ExecuteImport {
  final ImportRepository _repository;

  ExecuteImport({
    required ImportRepository repository,
  }) : _repository = repository;

  /// Import expenses
  Future<ImportResult> execute({
    required List<ParsedExpense> expenses,
    required String fileName,
  }) async {
    // Filter out expenses without category mapping
    final validExpenses = expenses.where((e) => e.mappedCategoryName != null).toList();
    
    if (validExpenses.isEmpty) {
      throw Exception('No valid expenses to import');
    }

    return await _repository.batchImportExpenses(
      expenses: validExpenses,
      fileName: fileName,
    );
  }
}
