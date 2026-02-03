import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../schemas/offline_message.dart';
import '../schemas/offline_expense.dart';
import '../schemas/sync_metadata.dart';

/// Singleton service for Isar database management
class IsarService {
  static IsarService? _instance;
  static IsarService get instance => _instance ??= IsarService._();

  IsarService._();

  Isar? _isar;
  bool _isInitialized = false;

  /// Get the Isar instance
  Isar get isar {
    if (_isar == null || !_isInitialized) {
      throw StateError('IsarService not initialized. Call initialize() first.');
    }
    return _isar!;
  }

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Initialize Isar database
  Future<void> initialize({bool encrypted = true}) async {
    if (_isInitialized) {
      debugPrint('IsarService already initialized');
      return;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = '${dir.path}/ora_offline';

      // Ensure directory exists
      await Directory(dbPath).create(recursive: true);

      _isar = await Isar.open(
        [
          OfflineMessageSchema,
          OfflineExpenseSchema,
          SyncMetadataSchema,
        ],
        directory: dbPath,
        name: 'ora_db',
        // Note: Isar Community doesn't support encryption
        // For encryption, use Isar Inspector or implement app-level encryption
      );

      // Initialize sync metadata if not exists
      await _initializeSyncMetadata();

      _isInitialized = true;
      debugPrint('IsarService initialized at $dbPath');
    } catch (e) {
      debugPrint('Failed to initialize IsarService: $e');
      rethrow;
    }
  }

  /// Initialize sync metadata singleton
  Future<void> _initializeSyncMetadata() async {
    final existing = await _isar!.syncMetadatas.get(0);
    if (existing == null) {
      await _isar!.writeTxn(() async {
        await _isar!.syncMetadatas.put(SyncMetadata.initial());
      });
    }
  }

  /// Close database
  Future<void> close() async {
    if (_isar != null && _isar!.isOpen) {
      await _isar!.close();
      _isInitialized = false;
      debugPrint('IsarService closed');
    }
  }

  /// Clear all data (for logout)
  Future<void> clearAll() async {
    await _isar?.writeTxn(() async {
      await _isar!.offlineMessages.clear();
      await _isar!.offlineExpenses.clear();
      // Reset sync metadata
      await _isar!.syncMetadatas.put(SyncMetadata.initial());
    });
    debugPrint('IsarService cleared all data');
  }

  /// Get database size in bytes
  Future<int> getDatabaseSize() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbFile = File('${dir.path}/ora_offline/ora_db.isar');
    if (await dbFile.exists()) {
      return await dbFile.length();
    }
    return 0;
  }

  /// Export database (for backup)
  Future<List<int>> exportDatabase() async {
    // Implementation would depend on backup strategy
    throw UnimplementedError('Database export not implemented');
  }

  /// Import database (for restore)
  Future<void> importDatabase(List<int> data) async {
    // Implementation would depend on backup strategy
    throw UnimplementedError('Database import not implemented');
  }
}
