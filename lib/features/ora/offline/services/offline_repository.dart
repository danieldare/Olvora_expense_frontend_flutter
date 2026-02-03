import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../schemas/offline_message.dart';
import '../schemas/offline_expense.dart';
import '../schemas/sync_metadata.dart';
import 'isar_service.dart';

/// Repository for offline data operations
class OfflineRepository {
  final IsarService _isarService;

  OfflineRepository(this._isarService);

  Isar get _isar => _isarService.isar;

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save a new message
  Future<void> saveMessage(OfflineMessage message) async {
    await _isar.writeTxn(() async {
      await _isar.offlineMessages.put(message);
    });
    await _updateSyncCounts();
  }

  /// Get message by local ID
  Future<OfflineMessage?> getMessageByLocalId(String localId) async {
    return await _isar.offlineMessages
        .where()
        .localIdEqualTo(localId)
        .findFirst();
  }

  /// Get messages for a conversation
  Future<List<OfflineMessage>> getMessagesForConversation(
    String conversationId,
  ) async {
    return await _isar.offlineMessages
        .where()
        .conversationIdEqualTo(conversationId)
        .sortByCreatedAt()
        .findAll();
  }

  /// Watch messages for a conversation (reactive)
  Stream<List<OfflineMessage>> watchMessagesForConversation(
    String conversationId,
  ) {
    return _isar.offlineMessages
        .where()
        .conversationIdEqualTo(conversationId)
        .sortByCreatedAt()
        .watch(fireImmediately: true);
  }

  /// Get pending messages for sync
  Future<List<OfflineMessage>> getPendingMessages({int limit = 50}) async {
    return await _isar.offlineMessages
        .where()
        .syncStatusEqualTo(SyncStatus.pending)
        .sortByCreatedAt()
        .limit(limit)
        .findAll();
  }

  /// Get failed messages that should retry
  Future<List<OfflineMessage>> getRetryableMessages() async {
    final failed = await _isar.offlineMessages
        .where()
        .syncStatusEqualTo(SyncStatus.failed)
        .findAll();
    return failed.where((m) => m.shouldRetry).toList();
  }

  /// Update message sync status
  Future<void> updateMessageStatus(
    String localId,
    SyncStatus status, {
    String? serverId,
    String? serverResponse,
    String? error,
  }) async {
    await _isar.writeTxn(() async {
      final message = await _isar.offlineMessages
          .where()
          .localIdEqualTo(localId)
          .findFirst();

      if (message != null) {
        switch (status) {
          case SyncStatus.syncing:
            message.markSyncing();
            break;
          case SyncStatus.synced:
            message.markSynced(serverId!, serverResponse);
            break;
          case SyncStatus.failed:
            message.markFailed(error ?? 'Unknown error');
            break;
          default:
            message.syncStatus = status;
            message.updatedAt = DateTime.now();
        }
        await _isar.offlineMessages.put(message);
      }
    });
    await _updateSyncCounts();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPENSE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save a new expense
  Future<void> saveExpense(OfflineExpense expense) async {
    await _isar.writeTxn(() async {
      await _isar.offlineExpenses.put(expense);
    });
    await _updateSyncCounts();
  }

  /// Get expense by local ID
  Future<OfflineExpense?> getExpenseByLocalId(String localId) async {
    return await _isar.offlineExpenses
        .where()
        .localIdEqualTo(localId)
        .findFirst();
  }

  /// Get all expenses for a user
  Future<List<OfflineExpense>> getExpenses(String userId) async {
    return await _isar.offlineExpenses
        .where()
        .userIdEqualTo(userId)
        .filter()
        .isDeletedEqualTo(false)
        .sortByExpenseDateDesc()
        .findAll();
  }

  /// Watch all expenses for a user (reactive)
  Stream<List<OfflineExpense>> watchExpenses(String userId) {
    return _isar.offlineExpenses
        .where()
        .userIdEqualTo(userId)
        .filter()
        .isDeletedEqualTo(false)
        .sortByExpenseDateDesc()
        .watch(fireImmediately: true);
  }

  /// Watch pending expenses
  Stream<List<OfflineExpense>> watchPendingExpenses() {
    return _isar.offlineExpenses
        .where()
        .syncStatusEqualTo(SyncStatus.pending)
        .watch(fireImmediately: true);
  }

  /// Get pending expenses for sync
  Future<List<OfflineExpense>> getPendingExpenses({int limit = 50}) async {
    return await _isar.offlineExpenses
        .where()
        .syncStatusEqualTo(SyncStatus.pending)
        .sortByCreatedAt()
        .limit(limit)
        .findAll();
  }

  /// Get expenses with conflicts
  Future<List<OfflineExpense>> getConflictExpenses() async {
    return await _isar.offlineExpenses
        .where()
        .syncStatusEqualTo(SyncStatus.conflict)
        .findAll();
  }

  /// Get expenses by date range
  Future<List<OfflineExpense>> getExpensesByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    return await _isar.offlineExpenses
        .where()
        .userIdEqualTo(userId)
        .filter()
        .isDeletedEqualTo(false)
        .expenseDateBetween(start, end)
        .sortByExpenseDateDesc()
        .findAll();
  }

  /// Get expenses by category
  Future<List<OfflineExpense>> getExpensesByCategory(
    String userId,
    String category,
  ) async {
    return await _isar.offlineExpenses
        .where()
        .userIdEqualTo(userId)
        .filter()
        .isDeletedEqualTo(false)
        .categoryEqualTo(category)
        .sortByExpenseDateDesc()
        .findAll();
  }

  /// Update expense locally
  Future<void> updateExpenseLocally(
    String localId, {
    double? amount,
    String? currency,
    String? description,
    String? merchant,
    String? category,
    DateTime? expenseDate,
    String? notes,
    List<String>? tags,
  }) async {
    await _isar.writeTxn(() async {
      final expense = await _isar.offlineExpenses
          .where()
          .localIdEqualTo(localId)
          .findFirst();

      if (expense != null) {
        expense.updateLocally(
          amount: amount,
          currency: currency,
          description: description,
          merchant: merchant,
          category: category,
          expenseDate: expenseDate,
          notes: notes,
          tags: tags,
        );
        await _isar.offlineExpenses.put(expense);
      }
    });
    await _updateSyncCounts();
  }

  /// Mark expense as deleted
  Future<void> markExpenseDeleted(String localId) async {
    await _isar.writeTxn(() async {
      final expense = await _isar.offlineExpenses
          .where()
          .localIdEqualTo(localId)
          .findFirst();

      if (expense != null) {
        expense.markDeleted();
        await _isar.offlineExpenses.put(expense);
      }
    });
    await _updateSyncCounts();
  }

  /// Update expense sync status
  Future<void> updateExpenseStatus(
    String localId,
    SyncStatus status, {
    String? serverId,
    int? serverVersion,
    String? error,
  }) async {
    await _isar.writeTxn(() async {
      final expense = await _isar.offlineExpenses
          .where()
          .localIdEqualTo(localId)
          .findFirst();

      if (expense != null) {
        switch (status) {
          case SyncStatus.syncing:
            expense.markSyncing();
            break;
          case SyncStatus.synced:
            expense.markSynced(serverId!, serverVersion ?? 1);
            break;
          case SyncStatus.failed:
            expense.markFailed(error ?? 'Unknown error');
            break;
          case SyncStatus.conflict:
            expense.markConflict(error ?? 'Server conflict');
            break;
          default:
            expense.syncStatus = status;
            expense.updatedAt = DateTime.now();
        }
        await _isar.offlineExpenses.put(expense);
      }
    });
    await _updateSyncCounts();
  }

  /// Resolve conflict - keep local version
  Future<void> resolveConflictKeepLocal(String localId) async {
    await _isar.writeTxn(() async {
      final expense = await _isar.offlineExpenses
          .where()
          .localIdEqualTo(localId)
          .findFirst();

      if (expense != null) {
        expense.syncStatus = SyncStatus.pending;
        expense.localVersion++;
        expense.updatedAt = DateTime.now();
        await _isar.offlineExpenses.put(expense);
      }
    });
    await _updateSyncCounts();
  }

  /// Resolve conflict - keep server version
  Future<void> resolveConflictKeepServer(String localId) async {
    // This would fetch server version and replace local
    // For now, just mark as synced
    await updateExpenseStatus(localId, SyncStatus.synced);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AGGREGATE QUERIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get total spending by currency for date range
  Future<Map<String, double>> getTotalSpendingByCurrency(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final expenses = await _isar.offlineExpenses
        .where()
        .userIdEqualTo(userId)
        .filter()
        .isDeletedEqualTo(false)
        .expenseDateBetween(start, end)
        .findAll();

    final totals = <String, double>{};
    for (final expense in expenses) {
      totals[expense.currency] =
          (totals[expense.currency] ?? 0) + expense.amount;
    }
    return totals;
  }

  /// Get spending by category
  Future<Map<String, double>> getSpendingByCategory(
    String userId,
    String currency,
    DateTime start,
    DateTime end,
  ) async {
    final expenses = await _isar.offlineExpenses
        .where()
        .userIdEqualTo(userId)
        .filter()
        .isDeletedEqualTo(false)
        .currencyEqualTo(currency)
        .expenseDateBetween(start, end)
        .findAll();

    final byCategory = <String, double>{};
    for (final expense in expenses) {
      final cat = expense.category ?? 'Other';
      byCategory[cat] = (byCategory[cat] ?? 0) + expense.amount;
    }
    return byCategory;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SYNC METADATA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get sync metadata
  Future<SyncMetadata> getSyncMetadata() async {
    final meta = await _isar.syncMetadatas.get(0);
    return meta ?? SyncMetadata.initial();
  }

  /// Watch sync metadata
  Stream<SyncMetadata> watchSyncMetadata() {
    return _isar.syncMetadatas.watchObject(0, fireImmediately: true).map(
          (meta) => meta ?? SyncMetadata.initial(),
        );
  }

  /// Update sync metadata
  Future<void> updateSyncMetadata(
    void Function(SyncMetadata meta) update,
  ) async {
    await _isar.writeTxn(() async {
      final meta = await _isar.syncMetadatas.get(0) ?? SyncMetadata.initial();
      update(meta);
      await _isar.syncMetadatas.put(meta);
    });
  }

  /// Update sync counts from actual data
  Future<void> _updateSyncCounts() async {
    final pendingMessages = await _isar.offlineMessages
        .where()
        .syncStatusEqualTo(SyncStatus.pending)
        .count();
    final pendingExpenses = await _isar.offlineExpenses
        .where()
        .syncStatusEqualTo(SyncStatus.pending)
        .count();

    final failedMessages = await _isar.offlineMessages
        .where()
        .syncStatusEqualTo(SyncStatus.failed)
        .count();
    final failedExpenses = await _isar.offlineExpenses
        .where()
        .syncStatusEqualTo(SyncStatus.failed)
        .count();

    final conflictExpenses = await _isar.offlineExpenses
        .where()
        .syncStatusEqualTo(SyncStatus.conflict)
        .count();

    await updateSyncMetadata((meta) {
      meta.updateCounts(
        pending: pendingMessages + pendingExpenses,
        failed: failedMessages + failedExpenses,
        conflicts: conflictExpenses,
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BULK OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Bulk save expenses (for import)
  Future<void> bulkSaveExpenses(List<OfflineExpense> expenses) async {
    await _isar.writeTxn(() async {
      await _isar.offlineExpenses.putAll(expenses);
    });
    await _updateSyncCounts();
  }

  /// Bulk update status (for batch sync)
  Future<void> bulkUpdateExpenseStatus(
    List<String> localIds,
    SyncStatus status,
  ) async {
    await _isar.writeTxn(() async {
      for (final localId in localIds) {
        final expense = await _isar.offlineExpenses
            .where()
            .localIdEqualTo(localId)
            .findFirst();
        if (expense != null) {
          expense.syncStatus = status;
          expense.updatedAt = DateTime.now();
          await _isar.offlineExpenses.put(expense);
        }
      }
    });
    await _updateSyncCounts();
  }

  /// Clean up old synced items
  Future<int> cleanupSyncedItems({
    Duration olderThan = const Duration(days: 30),
  }) async {
    final cutoff = DateTime.now().subtract(olderThan);
    int deleted = 0;

    await _isar.writeTxn(() async {
      // Clean old synced messages
      final oldMessages = await _isar.offlineMessages
          .where()
          .syncStatusEqualTo(SyncStatus.synced)
          .filter()
          .syncedAtLessThan(cutoff)
          .findAll();

      final deletedCount = await _isar.offlineMessages
          .deleteAll(oldMessages.map((m) => m.id).toList());
      deleted += deletedCount;

      // Don't delete synced expenses - they're needed for queries
    });

    debugPrint('Cleaned up $deleted old synced items');
    return deleted;
  }
}
