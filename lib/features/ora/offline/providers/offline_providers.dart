import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../schemas/offline_message.dart';
import '../schemas/offline_expense.dart';
import '../schemas/sync_metadata.dart';
import '../services/isar_service.dart';
import '../services/offline_repository.dart';
import '../services/sync_engine.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CORE SERVICE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Isar service singleton
final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService.instance;
});

/// Offline repository
final offlineRepositoryProvider = Provider<OfflineRepository>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return OfflineRepository(isarService);
});

/// Sync engine
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  final repository = ref.watch(offlineRepositoryProvider);

  return SyncEngine(
    isarService,
    repository,
    config: const SyncConfig(
      minSyncIntervalSeconds: 5,
      batchSize: 10,
      maxRetries: 5,
      autoSyncEnabled: true,
      wifiOnly: false,
    ),
  );
});

// ═══════════════════════════════════════════════════════════════════════════════
// SYNC STATE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Current sync metadata stream
final syncMetadataStreamProvider = StreamProvider<SyncMetadata>((ref) {
  final syncEngine = ref.watch(syncEngineProvider);
  return syncEngine.syncStateStream;
});

/// Current sync progress stream
final syncProgressStreamProvider = StreamProvider<SyncProgress>((ref) {
  final syncEngine = ref.watch(syncEngineProvider);
  return syncEngine.syncProgressStream;
});

/// State for sync status UI
class SyncStatusState {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final int conflictCount;
  final String statusText;
  final DateTime? lastSyncTime;

  const SyncStatusState({
    required this.isOnline,
    required this.isSyncing,
    required this.pendingCount,
    required this.conflictCount,
    required this.statusText,
    this.lastSyncTime,
  });

  factory SyncStatusState.initial() => const SyncStatusState(
        isOnline: true,
        isSyncing: false,
        pendingCount: 0,
        conflictCount: 0,
        statusText: 'Initializing...',
      );

  bool get hasPending => pendingCount > 0;
  bool get hasConflicts => conflictCount > 0;
  bool get isAllSynced => pendingCount == 0 && conflictCount == 0;
}

/// Sync status notifier
class SyncStatusNotifier extends StateNotifier<SyncStatusState> {
  final Ref _ref;
  StreamSubscription<SyncMetadata>? _subscription;

  SyncStatusNotifier(this._ref) : super(SyncStatusState.initial()) {
    _init();
  }

  void _init() {
    final syncEngine = _ref.read(syncEngineProvider);
    _subscription = syncEngine.syncStateStream.listen((meta) {
      state = SyncStatusState(
        isOnline: meta.isOnline,
        isSyncing: meta.state == SyncState.syncing,
        pendingCount: meta.pendingCount,
        conflictCount: meta.conflictCount,
        statusText: meta.statusText,
        lastSyncTime: meta.lastFullSync,
      );
    });
  }

  Future<void> syncNow() async {
    final syncEngine = _ref.read(syncEngineProvider);
    await syncEngine.syncNow();
  }

  Future<void> pause(String reason) async {
    final syncEngine = _ref.read(syncEngineProvider);
    await syncEngine.pause(reason);
  }

  Future<void> resume() async {
    final syncEngine = _ref.read(syncEngineProvider);
    await syncEngine.resume();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Sync status provider
final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, SyncStatusState>((ref) {
  return SyncStatusNotifier(ref);
});

// ═══════════════════════════════════════════════════════════════════════════════
// MESSAGE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Messages for a conversation (reactive) - family provider
final conversationMessagesProvider =
    StreamProvider.family<List<OfflineMessage>, String>((ref, conversationId) {
  final repository = ref.watch(offlineRepositoryProvider);
  return repository.watchMessagesForConversation(conversationId);
});

/// Message sender state
class MessageSenderState {
  final bool isLoading;
  final String? error;

  const MessageSenderState({this.isLoading = false, this.error});
}

/// Message sender notifier
class MessageSenderNotifier extends StateNotifier<MessageSenderState> {
  final Ref _ref;

  MessageSenderNotifier(this._ref) : super(const MessageSenderState());

  Future<OfflineMessage> sendMessage({
    required String userId,
    required String conversationId,
    required String text,
    OfflineMessageType type = OfflineMessageType.chat,
    String? optimisticResponse,
    Map<String, dynamic>? metadata,
  }) async {
    state = const MessageSenderState(isLoading: true);

    try {
      final repository = _ref.read(offlineRepositoryProvider);

      final message = OfflineMessage.create(
        localId: const Uuid().v4(),
        userId: userId,
        conversationId: conversationId,
        text: text,
        messageType: type,
        optimisticResponse: optimisticResponse,
        metadata: metadata != null ? jsonEncode(metadata) : null,
      );

      await repository.saveMessage(message);

      // Trigger sync
      final syncEngine = _ref.read(syncEngineProvider);
      syncEngine.syncNow(); // Fire and forget

      state = const MessageSenderState();
      return message;
    } catch (e) {
      state = MessageSenderState(error: e.toString());
      rethrow;
    }
  }
}

/// Message sender provider
final messageSenderProvider =
    StateNotifierProvider<MessageSenderNotifier, MessageSenderState>((ref) {
  return MessageSenderNotifier(ref);
});

// ═══════════════════════════════════════════════════════════════════════════════
// EXPENSE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// All expenses for a user (reactive) - family provider
final userExpensesProvider =
    StreamProvider.family<List<OfflineExpense>, String>((ref, userId) {
  final repository = ref.watch(offlineRepositoryProvider);
  return repository.watchExpenses(userId);
});

/// Pending expenses (for sync indicator)
final pendingExpensesProvider = StreamProvider<List<OfflineExpense>>((ref) {
  final repository = ref.watch(offlineRepositoryProvider);
  return repository.watchPendingExpenses();
});

/// Expenses with conflicts
final conflictExpensesProvider = FutureProvider<List<OfflineExpense>>((ref) {
  final repository = ref.watch(offlineRepositoryProvider);
  return repository.getConflictExpenses();
});

/// Expense manager state
class ExpenseManagerState {
  final bool isLoading;
  final String? error;

  const ExpenseManagerState({this.isLoading = false, this.error});
}

/// Expense manager notifier
class ExpenseManagerNotifier extends StateNotifier<ExpenseManagerState> {
  final Ref _ref;

  ExpenseManagerNotifier(this._ref) : super(const ExpenseManagerState());

  Future<OfflineExpense> createExpense({
    required String userId,
    required double amount,
    required String currency,
    required String description,
    String? merchant,
    String? category,
    DateTime? date,
    String? tripId,
    String? notes,
    List<String>? tags,
    String? sourceMessageLocalId,
  }) async {
    state = const ExpenseManagerState(isLoading: true);

    try {
      final repository = _ref.read(offlineRepositoryProvider);

      final expense = OfflineExpense.create(
        localId: const Uuid().v4(),
        userId: userId,
        amount: amount,
        currency: currency,
        description: description,
        merchant: merchant,
        category: category,
        expenseDate: date,
        tripId: tripId,
        notes: notes,
        tags: tags,
        sourceMessageLocalId: sourceMessageLocalId,
      );

      await repository.saveExpense(expense);

      // Trigger sync
      final syncEngine = _ref.read(syncEngineProvider);
      syncEngine.syncNow();

      state = const ExpenseManagerState();
      return expense;
    } catch (e) {
      state = ExpenseManagerState(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateExpense(
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
    state = const ExpenseManagerState(isLoading: true);

    try {
      final repository = _ref.read(offlineRepositoryProvider);

      await repository.updateExpenseLocally(
        localId,
        amount: amount,
        currency: currency,
        description: description,
        merchant: merchant,
        category: category,
        expenseDate: expenseDate,
        notes: notes,
        tags: tags,
      );

      // Trigger sync
      final syncEngine = _ref.read(syncEngineProvider);
      syncEngine.syncNow();

      state = const ExpenseManagerState();
    } catch (e) {
      state = ExpenseManagerState(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteExpense(String localId) async {
    state = const ExpenseManagerState(isLoading: true);

    try {
      final repository = _ref.read(offlineRepositoryProvider);
      await repository.markExpenseDeleted(localId);

      // Trigger sync
      final syncEngine = _ref.read(syncEngineProvider);
      syncEngine.syncNow();

      state = const ExpenseManagerState();
    } catch (e) {
      state = ExpenseManagerState(error: e.toString());
      rethrow;
    }
  }

  Future<void> resolveConflictKeepLocal(String localId) async {
    final repository = _ref.read(offlineRepositoryProvider);
    await repository.resolveConflictKeepLocal(localId);

    final syncEngine = _ref.read(syncEngineProvider);
    syncEngine.syncNow();
  }

  Future<void> resolveConflictKeepServer(String localId) async {
    final repository = _ref.read(offlineRepositoryProvider);
    await repository.resolveConflictKeepServer(localId);
  }
}

/// Expense manager provider
final expenseManagerProvider =
    StateNotifierProvider<ExpenseManagerNotifier, ExpenseManagerState>((ref) {
  return ExpenseManagerNotifier(ref);
});

// ═══════════════════════════════════════════════════════════════════════════════
// AGGREGATE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Total spending by currency for a date range - family provider
final totalSpendingProvider = FutureProvider.family<
    Map<String, double>,
    ({String userId, DateTime start, DateTime end})>((ref, params) {
  final repository = ref.watch(offlineRepositoryProvider);
  return repository.getTotalSpendingByCurrency(
    params.userId,
    params.start,
    params.end,
  );
});

/// Spending by category - family provider
final spendingByCategoryProvider = FutureProvider.family<
    Map<String, double>,
    ({
      String userId,
      String currency,
      DateTime start,
      DateTime end
    })>((ref, params) {
  final repository = ref.watch(offlineRepositoryProvider);
  return repository.getSpendingByCategory(
    params.userId,
    params.currency,
    params.start,
    params.end,
  );
});

// ═══════════════════════════════════════════════════════════════════════════════
// INITIALIZATION PROVIDER
// ═══════════════════════════════════════════════════════════════════════════════

/// Initialize the offline system
final initializeOfflineSystemProvider = FutureProvider<void>((ref) async {
  final isarService = ref.read(isarServiceProvider);

  // Initialize Isar
  await isarService.initialize(encrypted: true);

  // Start sync engine
  final syncEngine = ref.read(syncEngineProvider);
  await syncEngine.start();

  debugPrint('Offline system initialized');
});
