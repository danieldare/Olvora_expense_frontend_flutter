import 'package:isar/isar.dart';

part 'sync_metadata.g.dart';

/// Overall sync state
enum SyncState {
  idle,       // Nothing happening
  syncing,    // Actively syncing
  paused,     // Manually paused
  error,      // Sync error occurred
  offline,    // No network connection
}

/// Sync metadata - single row for global sync state
@collection
class SyncMetadata {
  Id id = 0; // Always use ID 0 for singleton

  /// Current sync state
  @Enumerated(EnumType.ordinal)
  late SyncState state;

  /// Whether device is online
  late bool isOnline;

  /// Last successful full sync
  DateTime? lastFullSync;

  /// Last sync attempt
  DateTime? lastSyncAttempt;

  /// Number of pending items
  late int pendingCount;

  /// Number of failed items
  late int failedCount;

  /// Number of conflicts
  late int conflictCount;

  /// Current error message (if any)
  String? currentError;

  /// Pause reason (if paused)
  String? pauseReason;

  /// Sync progress (0-100)
  late int progressPercent;

  /// Items synced in current batch
  late int currentBatchSynced;

  /// Total items in current batch
  late int currentBatchTotal;

  /// When metadata was last updated
  late DateTime updatedAt;

  /// Creates initial metadata
  static SyncMetadata initial() {
    return SyncMetadata()
      ..state = SyncState.idle
      ..isOnline = true
      ..pendingCount = 0
      ..failedCount = 0
      ..conflictCount = 0
      ..progressPercent = 0
      ..currentBatchSynced = 0
      ..currentBatchTotal = 0
      ..updatedAt = DateTime.now();
  }

  /// Update counts
  void updateCounts({
    required int pending,
    required int failed,
    required int conflicts,
  }) {
    pendingCount = pending;
    failedCount = failed;
    conflictCount = conflicts;
    updatedAt = DateTime.now();
  }

  /// Start syncing
  void startSync(int totalItems) {
    state = SyncState.syncing;
    currentBatchTotal = totalItems;
    currentBatchSynced = 0;
    progressPercent = 0;
    currentError = null;
    lastSyncAttempt = DateTime.now();
    updatedAt = DateTime.now();
  }

  /// Update progress
  void updateProgress(int synced) {
    currentBatchSynced = synced;
    progressPercent = currentBatchTotal > 0
        ? ((synced / currentBatchTotal) * 100).round()
        : 0;
    updatedAt = DateTime.now();
  }

  /// Complete sync
  void completeSync() {
    state = SyncState.idle;
    lastFullSync = DateTime.now();
    progressPercent = 100;
    currentError = null;
    updatedAt = DateTime.now();
  }

  /// Set error
  void setError(String error) {
    state = SyncState.error;
    currentError = error;
    updatedAt = DateTime.now();
  }

  /// Set offline
  void setOffline() {
    state = SyncState.offline;
    isOnline = false;
    updatedAt = DateTime.now();
  }

  /// Set online
  void setOnline() {
    isOnline = true;
    if (state == SyncState.offline) {
      state = SyncState.idle;
    }
    updatedAt = DateTime.now();
  }

  /// Pause sync
  void pause(String reason) {
    state = SyncState.paused;
    pauseReason = reason;
    updatedAt = DateTime.now();
  }

  /// Resume sync
  void resume() {
    state = SyncState.idle;
    pauseReason = null;
    updatedAt = DateTime.now();
  }

  /// Get status text for UI
  String get statusText {
    switch (state) {
      case SyncState.idle:
        if (pendingCount > 0) {
          return '$pendingCount pending';
        }
        if (conflictCount > 0) {
          return '$conflictCount conflicts';
        }
        return lastFullSync != null ? 'Synced' : 'Ready';
      case SyncState.syncing:
        return 'Syncing $currentBatchSynced/$currentBatchTotal...';
      case SyncState.paused:
        return 'Paused: ${pauseReason ?? "Manual"}';
      case SyncState.error:
        return 'Error: ${currentError ?? "Unknown"}';
      case SyncState.offline:
        return 'Offline';
    }
  }
}
