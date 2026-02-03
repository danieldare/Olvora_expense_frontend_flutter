import 'package:isar/isar.dart';

part 'offline_message.g.dart';

/// Sync status for offline items
enum SyncStatus {
  pending, // Queued for sync
  syncing, // Currently syncing
  synced, // Successfully synced
  failed, // Sync failed
  conflict, // Server conflict detected
  deleted, // Marked for deletion
}

/// Message type
enum OfflineMessageType {
  chat, // Regular chat message
  voice, // Voice transcription
  image, // Image/receipt
  action, // Action button response
  system, // System message
}

/// Offline message stored in Isar
@collection
class OfflineMessage {
  Id id = Isar.autoIncrement;

  /// Local UUID for this message
  @Index(unique: true)
  late String localId;

  /// Server ID (null until synced)
  String? serverId;

  /// User who sent this message
  @Index()
  late String userId;

  /// Conversation ID
  @Index()
  late String conversationId;

  /// Message text
  late String text;

  /// Message type
  @Enumerated(EnumType.ordinal)
  late OfflineMessageType messageType;

  /// Optimistic response from local parser (shown immediately offline)
  String? optimisticResponse;

  /// Server response (after sync)
  String? serverResponse;

  /// Sync status
  @Enumerated(EnumType.ordinal)
  @Index()
  late SyncStatus syncStatus;

  /// Number of sync attempts
  late int retryCount;

  /// Last error message
  String? errorMessage;

  /// When the message was created locally
  @Index()
  late DateTime createdAt;

  /// When the message was last modified
  late DateTime updatedAt;

  /// When the message was synced
  DateTime? syncedAt;

  /// Additional metadata (JSON string)
  String? metadata;

  /// Version for conflict detection
  late int version;

  /// Creates a new offline message
  static OfflineMessage create({
    required String localId,
    required String userId,
    required String conversationId,
    required String text,
    OfflineMessageType messageType = OfflineMessageType.chat,
    String? optimisticResponse,
    String? metadata,
  }) {
    final now = DateTime.now();
    return OfflineMessage()
      ..localId = localId
      ..userId = userId
      ..conversationId = conversationId
      ..text = text
      ..messageType = messageType
      ..optimisticResponse = optimisticResponse
      ..syncStatus = SyncStatus.pending
      ..retryCount = 0
      ..createdAt = now
      ..updatedAt = now
      ..metadata = metadata
      ..version = 1;
  }

  /// Mark as syncing
  void markSyncing() {
    syncStatus = SyncStatus.syncing;
    updatedAt = DateTime.now();
  }

  /// Mark as synced
  void markSynced(String serverId, String? response) {
    this.serverId = serverId;
    serverResponse = response;
    syncStatus = SyncStatus.synced;
    syncedAt = DateTime.now();
    updatedAt = DateTime.now();
    errorMessage = null;
  }

  /// Mark as failed
  void markFailed(String error) {
    syncStatus = SyncStatus.failed;
    errorMessage = error;
    retryCount++;
    updatedAt = DateTime.now();
  }

  /// Mark for retry
  void markForRetry() {
    syncStatus = SyncStatus.pending;
    updatedAt = DateTime.now();
  }

  /// Check if should retry
  bool get shouldRetry => retryCount < 5 && syncStatus == SyncStatus.failed;

  /// Get display text (server response if available, otherwise optimistic or original)
  String get displayText => serverResponse ?? optimisticResponse ?? text;
}
