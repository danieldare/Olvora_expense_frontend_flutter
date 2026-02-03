import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../schemas/offline_message.dart';
import '../schemas/offline_expense.dart';
import '../schemas/sync_metadata.dart';
import 'isar_service.dart';
import 'offline_repository.dart';

/// Configuration for sync engine
class SyncConfig {
  final int minSyncIntervalSeconds;
  final int batchSize;
  final int maxRetries;
  final bool autoSyncEnabled;
  final bool wifiOnly;
  final Duration retryDelay;

  const SyncConfig({
    this.minSyncIntervalSeconds = 5,
    this.batchSize = 10,
    this.maxRetries = 5,
    this.autoSyncEnabled = true,
    this.wifiOnly = false,
    this.retryDelay = const Duration(seconds: 5),
  });
}

/// Progress information for sync
class SyncProgress {
  final int total;
  final int synced;
  final int failed;
  final String? currentItem;

  const SyncProgress({
    required this.total,
    required this.synced,
    required this.failed,
    this.currentItem,
  });

  double get percent => total > 0 ? synced / total : 0;
}

/// Background sync engine
class SyncEngine {
  // ignore: unused_field - kept for potential direct Isar access
  final IsarService _isarService;
  final OfflineRepository _repository;
  final SyncConfig config;

  // API callback - set this to your actual API call
  Future<Map<String, dynamic>> Function(
    String text,
    String? conversationId,
  )? onSendMessage;

  Future<Map<String, dynamic>> Function(OfflineExpense expense)? onSyncExpense;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  // Controllers for streams
  final _syncStateController = StreamController<SyncMetadata>.broadcast();
  final _syncProgressController = StreamController<SyncProgress>.broadcast();

  Stream<SyncMetadata> get syncStateStream => _syncStateController.stream;
  Stream<SyncProgress> get syncProgressStream => _syncProgressController.stream;

  SyncEngine(
    this._isarService,
    this._repository, {
    this.config = const SyncConfig(),
  });

  /// Start the sync engine
  Future<void> start() async {
    debugPrint('SyncEngine starting...');

    // Start connectivity monitoring
    _startConnectivityMonitor();

    // Start periodic sync
    if (config.autoSyncEnabled) {
      _startPeriodicSync();
    }

    // Initial sync
    await syncNow();
  }

  /// Stop the sync engine
  Future<void> stop() async {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    debugPrint('SyncEngine stopped');
  }

  void _startConnectivityMonitor() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (results) async {
        final isOnline = results.isNotEmpty &&
            !results.contains(ConnectivityResult.none);
        final isWifi = results.contains(ConnectivityResult.wifi);

        // Update metadata
        await _repository.updateSyncMetadata((meta) {
          if (isOnline) {
            meta.setOnline();
          } else {
            meta.setOffline();
          }
        });

        // Emit state update
        final meta = await _repository.getSyncMetadata();
        _syncStateController.add(meta);

        // Sync if came back online
        if (isOnline && !_isSyncing) {
          if (!config.wifiOnly || isWifi) {
            debugPrint('Back online, triggering sync');
            syncNow();
          }
        }
      },
    );

    // Check initial connectivity
    Connectivity().checkConnectivity().then((results) async {
      final isOnline = results.isNotEmpty &&
          !results.contains(ConnectivityResult.none);

      await _repository.updateSyncMetadata((meta) {
        if (isOnline) {
          meta.setOnline();
        } else {
          meta.setOffline();
        }
      });
    });
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(
      Duration(seconds: config.minSyncIntervalSeconds),
      (_) => _periodicSync(),
    );
  }

  Future<void> _periodicSync() async {
    final meta = await _repository.getSyncMetadata();

    // Don't sync if offline, paused, or no pending items
    if (!meta.isOnline ||
        meta.state == SyncState.paused ||
        meta.pendingCount == 0) {
      return;
    }

    // Respect minimum interval
    if (_lastSyncTime != null) {
      final elapsed = DateTime.now().difference(_lastSyncTime!);
      if (elapsed.inSeconds < config.minSyncIntervalSeconds) {
        return;
      }
    }

    await syncNow();
  }

  /// Trigger immediate sync
  Future<void> syncNow() async {
    if (_isSyncing) {
      debugPrint('Sync already in progress');
      return;
    }

    final meta = await _repository.getSyncMetadata();
    if (!meta.isOnline) {
      debugPrint('Cannot sync - offline');
      return;
    }

    if (meta.state == SyncState.paused) {
      debugPrint('Cannot sync - paused');
      return;
    }

    _isSyncing = true;
    _lastSyncTime = DateTime.now();

    try {
      // Get pending items
      final pendingMessages = await _repository.getPendingMessages(
        limit: config.batchSize,
      );
      final pendingExpenses = await _repository.getPendingExpenses(
        limit: config.batchSize,
      );
      final retryableMessages = await _repository.getRetryableMessages();

      final totalItems = pendingMessages.length +
          pendingExpenses.length +
          retryableMessages.length;

      if (totalItems == 0) {
        debugPrint('Nothing to sync');
        await _repository.updateSyncMetadata((m) => m.completeSync());
        final newMeta = await _repository.getSyncMetadata();
        _syncStateController.add(newMeta);
        return;
      }

      debugPrint('Syncing $totalItems items...');

      // Update metadata
      await _repository.updateSyncMetadata((m) => m.startSync(totalItems));
      var currentMeta = await _repository.getSyncMetadata();
      _syncStateController.add(currentMeta);

      int synced = 0;
      int failed = 0;

      // Sync messages
      for (final message in [...pendingMessages, ...retryableMessages]) {
        try {
          await _syncMessage(message);
          synced++;
        } catch (e) {
          failed++;
          debugPrint('Failed to sync message ${message.localId}: $e');
        }

        _emitProgress(totalItems, synced, failed, message.text);
        await _repository.updateSyncMetadata((m) => m.updateProgress(synced));
      }

      // Sync expenses
      for (final expense in pendingExpenses) {
        try {
          await _syncExpense(expense);
          synced++;
        } catch (e) {
          failed++;
          debugPrint('Failed to sync expense ${expense.localId}: $e');
        }

        _emitProgress(totalItems, synced, failed, expense.description);
        await _repository.updateSyncMetadata((m) => m.updateProgress(synced));
      }

      // Complete
      await _repository.updateSyncMetadata((m) => m.completeSync());
      currentMeta = await _repository.getSyncMetadata();
      _syncStateController.add(currentMeta);

      debugPrint('Sync complete: $synced synced, $failed failed');
    } catch (e) {
      debugPrint('Sync error: $e');
      await _repository.updateSyncMetadata((m) => m.setError(e.toString()));
      final errorMeta = await _repository.getSyncMetadata();
      _syncStateController.add(errorMeta);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncMessage(OfflineMessage message) async {
    await _repository.updateMessageStatus(message.localId, SyncStatus.syncing);

    if (onSendMessage != null) {
      try {
        final result = await onSendMessage!(
          message.text,
          message.conversationId,
        );

        await _repository.updateMessageStatus(
          message.localId,
          SyncStatus.synced,
          serverId: result['id'] as String?,
          serverResponse: result['response'] as String?,
        );
      } catch (e) {
        await _repository.updateMessageStatus(
          message.localId,
          SyncStatus.failed,
          error: e.toString(),
        );
        rethrow;
      }
    } else {
      // No callback - just mark as synced for testing
      await _repository.updateMessageStatus(
        message.localId,
        SyncStatus.synced,
        serverId: 'mock-${message.localId}',
      );
    }
  }

  Future<void> _syncExpense(OfflineExpense expense) async {
    await _repository.updateExpenseStatus(expense.localId, SyncStatus.syncing);

    if (onSyncExpense != null) {
      try {
        final result = await onSyncExpense!(expense);

        // Check for conflict
        if (result['conflict'] == true) {
          await _repository.updateExpenseStatus(
            expense.localId,
            SyncStatus.conflict,
            error: result['message'] as String? ?? 'Server conflict',
          );
          return;
        }

        await _repository.updateExpenseStatus(
          expense.localId,
          SyncStatus.synced,
          serverId: result['id'] as String?,
          serverVersion: result['version'] as int? ?? 1,
        );
      } catch (e) {
        await _repository.updateExpenseStatus(
          expense.localId,
          SyncStatus.failed,
          error: e.toString(),
        );
        rethrow;
      }
    } else {
      // No callback - just mark as synced for testing
      await _repository.updateExpenseStatus(
        expense.localId,
        SyncStatus.synced,
        serverId: 'mock-${expense.localId}',
        serverVersion: 1,
      );
    }
  }

  void _emitProgress(int total, int synced, int failed, String? current) {
    _syncProgressController.add(SyncProgress(
      total: total,
      synced: synced,
      failed: failed,
      currentItem: current,
    ));
  }

  /// Pause sync
  Future<void> pause(String reason) async {
    await _repository.updateSyncMetadata((m) => m.pause(reason));
    final meta = await _repository.getSyncMetadata();
    _syncStateController.add(meta);
    debugPrint('Sync paused: $reason');
  }

  /// Resume sync
  Future<void> resume() async {
    await _repository.updateSyncMetadata((m) => m.resume());
    final meta = await _repository.getSyncMetadata();
    _syncStateController.add(meta);
    debugPrint('Sync resumed');
    await syncNow();
  }

  /// Dispose
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _syncStateController.close();
    _syncProgressController.close();
  }
}
