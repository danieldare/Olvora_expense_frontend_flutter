import 'package:dio/dio.dart';
import '../../../../core/services/api_service_v2.dart';
import '../../domain/entities/parsed_expense.dart';
import '../../domain/entities/import_result.dart';
import '../../domain/entities/import_history_entry.dart';
import '../../../../features/expenses/domain/entities/expense_entity.dart';

/// Remote data source for import operations (API calls)
class ImportRemoteDataSource {
  final ApiServiceV2 _apiService;

  ImportRemoteDataSource(this._apiService);

  /// Batch import expenses
  Future<ImportResult> batchImportExpenses({
    required List<ParsedExpense> expenses,
    required String fileName,
  }) async {
    try {
      // Convert ParsedExpense to CreateExpenseDto format
      final expensesData = expenses.map((e) {
        final category = e.categoryEnum ?? ExpenseCategory.other;
        return {
          'title': e.title,
          'amount': e.amount,
          'category': category.name,
          'date': e.date.toIso8601String().split('T')[0],
          'entryMode': 'manual', // Mark as imported
          if (e.currency != null && e.currency!.isNotEmpty) 'currency': e.currency,
          if (e.merchant != null) 'merchant': e.merchant,
          if (e.notes != null) 'description': e.notes,
        };
      }).toList();

      // Call batch import endpoint (will create this in backend)
      final response = await _apiService.dio.post(
        '/expenses/batch-import',
        data: {
          'expenses': expensesData,
          'fileName': fileName,
        },
      );

      // Parse response
      final data = response.data as Map<String, dynamic>;
      return ImportResult(
        importId: data['importId'] as String,
        importedAt: DateTime.parse(data['importedAt'] as String),
        fileName: data['fileName'] as String,
        totalExpenses: data['totalExpenses'] as int,
        successfulExpenses: data['successfulExpenses'] as int,
        failedExpenses: data['failedExpenses'] as int,
        totalAmount: (data['totalAmount'] as num).toDouble(),
        errors: (data['errors'] as List<dynamic>?)
                ?.map((e) => ImportError(
                      rowIndex: e['rowIndex'] as int,
                      errorMessage: e['errorMessage'] as String,
                      expenseTitle: e['expenseTitle'] as String?,
                    ))
                .toList() ??
            [],
        canUndo: data['canUndo'] as bool? ?? true,
      );
    } on DioException catch (e) {
      throw ImportException('Failed to import expenses: ${e.message}');
    }
  }

  /// Get import history
  Future<List<ImportHistoryEntry>> getImportHistory() async {
    try {
      final response = await _apiService.dio.get('/expenses/import-history');
      final data = response.data as List<dynamic>;
      return data.map((e) {
        final entry = e as Map<String, dynamic>;
        return ImportHistoryEntry(
          importId: entry['importId'] as String,
          importedAt: DateTime.parse(entry['createdAt'] as String),
          fileName: entry['fileName'] as String,
          expenseCount: entry['expenseCount'] as int,
          totalAmount: (entry['totalAmount'] as num).toDouble(),
          canUndo: entry['canUndo'] as bool? ?? true,
          isUndone: entry['isUndone'] as bool? ?? false,
          undoneAt: entry['undoneAt'] != null
              ? DateTime.parse(entry['undoneAt'] as String)
              : null,
        );
      }).toList();
    } on DioException catch (e) {
      throw ImportException('Failed to get import history: ${e.message}');
    }
  }

  /// Undo an import
  Future<void> undoImport(String importId) async {
    try {
      await _apiService.dio.post('/expenses/import-history/$importId/undo');
    } on DioException catch (e) {
      throw ImportException('Failed to undo import: ${e.message}');
    }
  }
}

class ImportException implements Exception {
  final String message;
  ImportException(this.message);
  
  @override
  String toString() => message;
}
