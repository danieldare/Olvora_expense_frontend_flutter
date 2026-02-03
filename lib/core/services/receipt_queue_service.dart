import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

/// Priority levels for queued receipts
enum QueuePriority {
  high,
  normal,
  low,
}

/// Status of a queued receipt
enum QueuedReceiptStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

/// Represents a queued receipt for offline processing
class QueuedReceipt {
  final String id;
  final String originalPath;
  final String? cachedPath;
  final String? tripId;
  final String fileType;
  final QueuePriority priority;
  final QueuedReceiptStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;
  final int retryCount;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  QueuedReceipt({
    required this.id,
    required this.originalPath,
    this.cachedPath,
    this.tripId,
    required this.fileType,
    this.priority = QueuePriority.normal,
    this.status = QueuedReceiptStatus.pending,
    required this.createdAt,
    this.processedAt,
    this.retryCount = 0,
    this.errorMessage,
    this.metadata,
  });

  QueuedReceipt copyWith({
    String? id,
    String? originalPath,
    String? cachedPath,
    String? tripId,
    String? fileType,
    QueuePriority? priority,
    QueuedReceiptStatus? status,
    DateTime? createdAt,
    DateTime? processedAt,
    int? retryCount,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return QueuedReceipt(
      id: id ?? this.id,
      originalPath: originalPath ?? this.originalPath,
      cachedPath: cachedPath ?? this.cachedPath,
      tripId: tripId ?? this.tripId,
      fileType: fileType ?? this.fileType,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalPath': originalPath,
      'cachedPath': cachedPath,
      'tripId': tripId,
      'fileType': fileType,
      'priority': priority.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'retryCount': retryCount,
      'errorMessage': errorMessage,
      'metadata': metadata,
    };
  }

  factory QueuedReceipt.fromJson(Map<String, dynamic> json) {
    return QueuedReceipt(
      id: json['id'] as String,
      originalPath: json['originalPath'] as String,
      cachedPath: json['cachedPath'] as String?,
      tripId: json['tripId'] as String?,
      fileType: json['fileType'] as String? ?? 'image',
      priority: QueuePriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => QueuePriority.normal,
      ),
      status: QueuedReceiptStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => QueuedReceiptStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String)
          : null,
      retryCount: json['retryCount'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  String get fileName => originalPath.split('/').last;
  bool get isPdf => fileType == 'pdf';
  bool get isImage => fileType == 'image';
  bool get isPending => status == QueuedReceiptStatus.pending;
  bool get canRetry => retryCount < 3 && status == QueuedReceiptStatus.failed;
}

/// Service for managing offline receipt queue
///
/// Features:
/// - Persists queue to local storage
/// - Caches files locally for reliability
/// - Automatic retry with exponential backoff
/// - Priority-based processing
/// - Progress tracking
class ReceiptQueueService {
  static final ReceiptQueueService _instance = ReceiptQueueService._internal();
  factory ReceiptQueueService() => _instance;
  ReceiptQueueService._internal();

  static const String _queueKey = 'receipt_queue';

  // Max retries and delay used by external processing logic
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 30);

  final List<QueuedReceipt> _queue = [];
  final bool _isProcessing = false;
  bool _isInitialized = false;

  // Stream controllers
  final StreamController<List<QueuedReceipt>> _queueController =
      StreamController<List<QueuedReceipt>>.broadcast();
  final StreamController<QueuedReceipt> _processedController =
      StreamController<QueuedReceipt>.broadcast();

  /// Stream of queue updates
  Stream<List<QueuedReceipt>> get queueStream => _queueController.stream;

  /// Stream of processed receipts
  Stream<QueuedReceipt> get processedStream => _processedController.stream;

  /// Current queue
  List<QueuedReceipt> get queue => List.unmodifiable(_queue);

  /// Number of pending items
  int get pendingCount =>
      _queue.where((r) => r.status == QueuedReceiptStatus.pending).length;

  /// Whether processing is in progress
  bool get isProcessing => _isProcessing;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadQueue();
      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('📋 ReceiptQueueService initialized with ${_queue.length} items');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing ReceiptQueueService: $e');
      }
    }
  }

  /// Queue a receipt for processing
  Future<String> queueReceipt({
    required String filePath,
    String? tripId,
    required String fileType,
    QueuePriority priority = QueuePriority.normal,
    Map<String, dynamic>? metadata,
  }) async {
    await initialize();

    // Generate unique ID
    final id = '${DateTime.now().millisecondsSinceEpoch}_${_queue.length}';

    // Cache the file locally
    String? cachedPath;
    try {
      cachedPath = await _cacheFile(filePath, id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Could not cache file: $e');
      }
    }

    final receipt = QueuedReceipt(
      id: id,
      originalPath: filePath,
      cachedPath: cachedPath,
      tripId: tripId,
      fileType: fileType,
      priority: priority,
      status: QueuedReceiptStatus.pending,
      createdAt: DateTime.now(),
      metadata: metadata,
    );

    // Insert based on priority
    final insertIndex = _findInsertIndex(receipt);
    _queue.insert(insertIndex, receipt);

    await _saveQueue();
    _notifyQueueUpdate();

    if (kDebugMode) {
      debugPrint('📋 Queued receipt: ${receipt.fileName} (priority: ${priority.name})');
    }

    return id;
  }

  /// Find the correct insert position based on priority
  int _findInsertIndex(QueuedReceipt receipt) {
    for (int i = 0; i < _queue.length; i++) {
      if (_queue[i].priority.index > receipt.priority.index) {
        return i;
      }
    }
    return _queue.length;
  }

  /// Cache file locally for reliability
  Future<String?> _cacheFile(String originalPath, String id) async {
    try {
      final file = File(originalPath);
      if (!await file.exists()) {
        return null;
      }

      final cacheDir = await getApplicationDocumentsDirectory();
      final receiptCacheDir = Directory('${cacheDir.path}/receipt_cache');
      if (!await receiptCacheDir.exists()) {
        await receiptCacheDir.create(recursive: true);
      }

      final extension = originalPath.split('.').last;
      final cachedPath = '${receiptCacheDir.path}/$id.$extension';
      await file.copy(cachedPath);

      if (kDebugMode) {
        debugPrint('📋 Cached file: $cachedPath');
      }

      return cachedPath;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error caching file: $e');
      }
      return null;
    }
  }

  /// Remove a receipt from the queue
  Future<void> removeReceipt(String id) async {
    final index = _queue.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final receipt = _queue[index];

    // Delete cached file if exists
    if (receipt.cachedPath != null) {
      try {
        final cachedFile = File(receipt.cachedPath!);
        if (await cachedFile.exists()) {
          await cachedFile.delete();
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Error deleting cached file: $e');
        }
      }
    }

    _queue.removeAt(index);
    await _saveQueue();
    _notifyQueueUpdate();

    if (kDebugMode) {
      debugPrint('📋 Removed receipt from queue: ${receipt.fileName}');
    }
  }

  /// Update a receipt's status
  Future<void> updateReceiptStatus(
    String id,
    QueuedReceiptStatus status, {
    String? errorMessage,
  }) async {
    final index = _queue.indexWhere((r) => r.id == id);
    if (index == -1) return;

    _queue[index] = _queue[index].copyWith(
      status: status,
      errorMessage: errorMessage,
      processedAt: status == QueuedReceiptStatus.completed ||
              status == QueuedReceiptStatus.failed
          ? DateTime.now()
          : null,
    );

    await _saveQueue();
    _notifyQueueUpdate();

    if (status == QueuedReceiptStatus.completed ||
        status == QueuedReceiptStatus.failed) {
      _processedController.add(_queue[index]);
    }
  }

  /// Retry a failed receipt
  Future<void> retryReceipt(String id) async {
    final index = _queue.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final receipt = _queue[index];
    if (!receipt.canRetry) return;

    _queue[index] = receipt.copyWith(
      status: QueuedReceiptStatus.pending,
      retryCount: receipt.retryCount + 1,
      errorMessage: null,
    );

    await _saveQueue();
    _notifyQueueUpdate();

    if (kDebugMode) {
      debugPrint('📋 Retrying receipt: ${receipt.fileName} (attempt ${receipt.retryCount + 1})');
    }
  }

  /// Get the next pending receipt to process
  QueuedReceipt? getNextPending() {
    try {
      return _queue.firstWhere((r) => r.status == QueuedReceiptStatus.pending);
    } catch (e) {
      return null;
    }
  }

  /// Get the file path for a queued receipt (prefers cached)
  String? getFilePath(QueuedReceipt receipt) {
    // Prefer cached path
    if (receipt.cachedPath != null) {
      final cachedFile = File(receipt.cachedPath!);
      if (cachedFile.existsSync()) {
        return receipt.cachedPath;
      }
    }

    // Fall back to original path
    final originalFile = File(receipt.originalPath);
    if (originalFile.existsSync()) {
      return receipt.originalPath;
    }

    return null;
  }

  /// Clear completed receipts from queue
  Future<void> clearCompleted() async {
    _queue.removeWhere((r) =>
        r.status == QueuedReceiptStatus.completed ||
        r.status == QueuedReceiptStatus.cancelled);
    await _saveQueue();
    _notifyQueueUpdate();
  }

  /// Clear all receipts from queue
  Future<void> clearAll() async {
    // Delete cached files
    for (final receipt in _queue) {
      if (receipt.cachedPath != null) {
        try {
          final cachedFile = File(receipt.cachedPath!);
          if (await cachedFile.exists()) {
            await cachedFile.delete();
          }
        } catch (e) {
          // Ignore errors
        }
      }
    }

    _queue.clear();
    await _saveQueue();
    _notifyQueueUpdate();
  }

  /// Load queue from persistent storage
  Future<void> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);

      if (queueJson != null) {
        final List<dynamic> queueList = jsonDecode(queueJson) as List<dynamic>;
        _queue.clear();
        _queue.addAll(
          queueList
              .map((item) => QueuedReceipt.fromJson(item as Map<String, dynamic>))
              .toList(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading queue: $e');
      }
    }
  }

  /// Save queue to persistent storage
  Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = jsonEncode(_queue.map((r) => r.toJson()).toList());
      await prefs.setString(_queueKey, queueJson);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving queue: $e');
      }
    }
  }

  /// Notify listeners of queue update
  void _notifyQueueUpdate() {
    _queueController.add(List.unmodifiable(_queue));
  }

  /// Dispose resources
  void dispose() {
    _queueController.close();
    _processedController.close();
  }
}
