import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../../../core/services/import_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/state/auth_state.dart';

/// Provider for ImportService
final importServiceProvider = Provider<ImportService>((ref) {
  return ImportService();
});

/// Provider for batch importing expenses
final batchImportExpensesProvider = FutureProvider.family<BatchImportResult, BatchImportParams>(
  (ref, params) async {
    final authState = ref.watch(authNotifierProvider);

    if (authState is! AuthStateAuthenticated) {
      throw Exception('User not authenticated');
    }

    final apiService = ref.read(apiServiceV2Provider);
    
    // Prepare the request body
    final requestBody = {
      'expenses': params.expenses.map((e) => e.toDto()).toList(),
      'fileName': params.fileName,
    };

    try {
      final response = await apiService.dio.post(
        '/expenses/batch-import',
        data: requestBody,
      );

      dynamic actualData = response.data;
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap.containsKey('data')) {
          actualData = responseMap['data'];
        }
      }

      return BatchImportResult.fromJson(actualData as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to import expenses: ${e.toString()}');
    }
  },
);

/// Parameters for batch import
class BatchImportParams {
  final List<ImportExpense> expenses;
  final String fileName;

  BatchImportParams({
    required this.expenses,
    required this.fileName,
  });
}

/// Result of batch import
class BatchImportResult {
  final String importId;
  final String importedAt;
  final String fileName;
  final int totalExpenses;
  final int successfulExpenses;
  final int failedExpenses;
  final double totalAmount;
  final List<ImportError> errors;
  final bool canUndo;

  BatchImportResult({
    required this.importId,
    required this.importedAt,
    required this.fileName,
    required this.totalExpenses,
    required this.successfulExpenses,
    required this.failedExpenses,
    required this.totalAmount,
    required this.errors,
    required this.canUndo,
  });

  factory BatchImportResult.fromJson(Map<String, dynamic> json) {
    return BatchImportResult(
      importId: json['importId'] as String,
      importedAt: json['importedAt'] as String,
      fileName: json['fileName'] as String,
      totalExpenses: json['totalExpenses'] as int,
      successfulExpenses: json['successfulExpenses'] as int,
      failedExpenses: json['failedExpenses'] as int,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      errors: json['errors'] != null
          ? (json['errors'] as List)
              .map((e) => ImportError.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      canUndo: json['canUndo'] as bool? ?? false,
    );
  }
}

/// Import error
class ImportError {
  final int rowIndex;
  final String errorMessage;
  final String? expenseTitle;

  ImportError({
    required this.rowIndex,
    required this.errorMessage,
    this.expenseTitle,
  });

  factory ImportError.fromJson(Map<String, dynamic> json) {
    return ImportError(
      rowIndex: json['rowIndex'] as int,
      errorMessage: json['errorMessage'] as String,
      expenseTitle: json['expenseTitle'] as String?,
    );
  }
}
