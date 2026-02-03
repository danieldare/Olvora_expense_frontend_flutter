import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/import_repository.dart';
import '../../domain/entities/import_result.dart';
import '../../domain/entities/import_history_entry.dart';
import '../../domain/entities/parsed_expense.dart';
import '../datasources/import_remote_datasource.dart';
import '../datasources/import_local_datasource.dart';

/// Implementation of ImportRepository
class ImportRepositoryImpl implements ImportRepository {
  final ImportRemoteDataSource _remoteDataSource;
  final ImportLocalDataSource _localDataSource;

  ImportRepositoryImpl({
    required ImportRemoteDataSource remoteDataSource,
    required ImportLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<ImportResult> batchImportExpenses({
    required List<ParsedExpense> expenses,
    required String fileName,
  }) async {
    // Call remote API
    final result = await _remoteDataSource.batchImportExpenses(
      expenses: expenses,
      fileName: fileName,
    );

    // Save to local history
    await _localDataSource.saveImportHistory(
      ImportHistoryEntry(
        importId: result.importId,
        importedAt: result.importedAt,
        fileName: result.fileName,
        expenseCount: result.successfulExpenses,
        totalAmount: result.totalAmount,
        canUndo: result.canUndo,
      ),
    );

    return result;
  }

  @override
  Future<List<ImportHistoryEntry>> getImportHistory() async {
    try {
      // Try remote first
      final remoteHistory = await _remoteDataSource.getImportHistory();
      
      // Sync to local
      for (final entry in remoteHistory) {
        await _localDataSource.saveImportHistory(entry);
      }
      
      return remoteHistory;
    } catch (e) {
      // Fallback to local if remote fails
      return await _localDataSource.getImportHistory();
    }
  }

  @override
  Future<void> undoImport(String importId) async {
    await _remoteDataSource.undoImport(importId);
    
    // Update local history
    final history = await _localDataSource.getImportHistory();
    final entry = history.firstWhere(
      (e) => e.importId == importId,
      orElse: () => throw Exception('Import not found'),
    );
    
    final updatedEntry = ImportHistoryEntry(
      importId: entry.importId,
      importedAt: entry.importedAt,
      fileName: entry.fileName,
      expenseCount: entry.expenseCount,
      totalAmount: entry.totalAmount,
      canUndo: entry.canUndo,
      isUndone: true,
      undoneAt: DateTime.now(),
    );
    
    // Remove old and add updated
    final updatedHistory = history.where((e) => e.importId != importId).toList();
    updatedHistory.insert(0, updatedEntry);
    
    // Save updated history
    final prefs = await SharedPreferences.getInstance();
    final jsonList = updatedHistory.map((e) => {
      'importId': e.importId,
      'importedAt': e.importedAt.toIso8601String(),
      'fileName': e.fileName,
      'expenseCount': e.expenseCount,
      'totalAmount': e.totalAmount,
      'canUndo': e.canUndo,
      'isUndone': e.isUndone,
      'undoneAt': e.undoneAt?.toIso8601String(),
    }).toList();
    
    await prefs.setString('import_history', jsonEncode(jsonList));
  }
}
