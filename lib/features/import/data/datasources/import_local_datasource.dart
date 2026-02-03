import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/entities/import_history_entry.dart';

/// Local data source for import operations (caching, local storage)
class ImportLocalDataSource {
  static const String _historyKey = 'import_history';

  /// Save import history entry locally
  Future<void> saveImportHistory(ImportHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getImportHistory();
    
    // Add new entry at the beginning
    history.insert(0, entry);
    
    // Keep only last 50 entries
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }
    
    // Save as JSON
    final jsonList = history.map((e) => {
      'importId': e.importId,
      'importedAt': e.importedAt.toIso8601String(),
      'fileName': e.fileName,
      'expenseCount': e.expenseCount,
      'totalAmount': e.totalAmount,
      'canUndo': e.canUndo,
      'isUndone': e.isUndone,
      'undoneAt': e.undoneAt?.toIso8601String(),
    }).toList();
    
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  /// Get import history from local storage
  Future<List<ImportHistoryEntry>> getImportHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);
    
    if (jsonString == null) return [];
    
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((e) {
        final entry = e as Map<String, dynamic>;
        return ImportHistoryEntry(
          importId: entry['importId'] as String,
          importedAt: DateTime.parse(entry['importedAt'] as String),
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
    } catch (e) {
      return [];
    }
  }

  /// Clear import history
  Future<void> clearImportHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
