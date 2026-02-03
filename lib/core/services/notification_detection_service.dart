import 'dart:async';
import 'package:flutter/foundation.dart';
import 'expense_parsing/expense_parsing.dart';
import 'api_service_v2.dart';

/// Legacy model for backward compatibility
/// @deprecated Use ParsedExpenseResult instead
class DetectedExpense {
  final double amount;
  final String? merchant;
  final String? description;
  final DateTime timestamp;
  final String notificationText;
  final String? packageName;

  DetectedExpense({
    required this.amount,
    this.merchant,
    this.description,
    required this.timestamp,
    required this.notificationText,
    this.packageName,
  });

  /// Create a unique identifier for this expense to detect duplicates
  String get duplicateKey {
    return '${amount.toStringAsFixed(2)}_${merchant ?? description ?? ''}_${timestamp.millisecondsSinceEpoch ~/ 1000}';
  }

  /// Convert to ParsedExpenseResult
  ParsedExpenseResult toExpenseResult() {
    return ParsedExpenseResult(
      amount: amount,
      merchant: merchant,
      description: description,
      date: timestamp,
      rawText: notificationText,
      confidence: 0.7, // Default medium confidence for legacy
      source: ParsingSource.sms,
      suggestedTitle: merchant ?? description,
    );
  }

  /// Create from ParsedExpenseResult
  factory DetectedExpense.fromExpenseResult(ParsedExpenseResult result) {
    return DetectedExpense(
      amount: result.amount ?? 0,
      merchant: result.merchant,
      description: result.description,
      timestamp: result.date ?? DateTime.now(),
      notificationText: result.rawText,
      packageName: result.metadata?['packageName'] as String?,
    );
  }
}

/// Service to detect debit alerts from notifications
///
/// Features:
/// - Smart parsing using HybridParser (generic patterns + AI)
/// - Multi-currency support (30+ currencies globally)
/// - Confidence scoring for parsed results
/// - Duplicate detection with content hashing
/// - Backward compatible with legacy DetectedExpense
class NotificationDetectionService {
  static final NotificationDetectionService _instance =
      NotificationDetectionService._internal();
  factory NotificationDetectionService() => _instance;
  NotificationDetectionService._internal();

  // New: Stream of ParsedExpenseResult (preferred)
  final StreamController<ParsedExpenseResult> _expenseResultController =
      StreamController<ParsedExpenseResult>.broadcast();

  // Legacy: Stream of DetectedExpense (for backward compatibility)
  final StreamController<DetectedExpense> _expenseController =
      StreamController<DetectedExpense>.broadcast();

  /// Stream of parsed expense results (preferred - use this for new code)
  Stream<ParsedExpenseResult> get expenseResults => _expenseResultController.stream;

  /// Stream of detected expenses (legacy - for backward compatibility)
  @Deprecated('Use expenseResults instead')
  Stream<DetectedExpense> get detectedExpenses => _expenseController.stream;

  bool _isListening = false;
  bool _isEnabled = false;

  // Parsers
  HybridExpenseParser? _hybridParser;
  GenericExpenseParser? _genericParser;

  // Track recently processed notifications to prevent duplicates
  final Set<String> _recentlyProcessed = {};
  Timer? _cleanupTimer;

  /// Initialize the service with API service for AI parsing
  void initializeWithApiService(ApiServiceV2 apiService) {
    _hybridParser = HybridExpenseParser.withApiService(
      apiService,
      config: const HybridParserConfig(
        aiParsingThreshold: 0.70,
        preferAIForSources: {ParsingSource.sms},
        respectConnectivity: true,
      ),
    );
    _genericParser = _hybridParser!.genericParser;

    if (kDebugMode) {
      debugPrint('🔔 NotificationDetectionService initialized with HybridParser');
    }
  }

  /// Initialize with generic parser only (offline mode)
  void initializeOffline() {
    _genericParser = GenericExpenseParser();
    _hybridParser = HybridExpenseParser(
      genericParser: _genericParser,
      aiParser: null, // No AI in offline mode
    );

    if (kDebugMode) {
      debugPrint('🔔 NotificationDetectionService initialized in offline mode');
    }
  }

  /// Enable notification detection
  Future<bool> enable() async {
    if (_isEnabled) return true;

    // Ensure parser is initialized
    _genericParser ??= GenericExpenseParser();
    _hybridParser ??= HybridExpenseParser(genericParser: _genericParser);

    _isEnabled = true;
    _startListening();
    _startCleanupTimer();
    return true;
  }

  /// Disable notification detection
  void disable() {
    _isEnabled = false;
    _stopListening();
    _cleanupTimer?.cancel();
    _recentlyProcessed.clear();
  }

  /// Check if detection is enabled
  bool get isEnabled => _isEnabled;

  /// Start listening to notifications
  void _startListening() {
    if (_isListening) return;
    _isListening = true;

    if (kDebugMode) {
      debugPrint('🔔 Notification detection started');
    }
  }

  /// Stop listening to notifications
  void _stopListening() {
    if (!_isListening) return;
    _isListening = false;

    if (kDebugMode) {
      debugPrint('🔕 Notification detection stopped');
    }
  }

  /// Start cleanup timer to remove old entries from duplicate tracking
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _recentlyProcessed.clear();
    });
  }

  /// Process a notification and extract expense data
  ///
  /// This method should be called by the platform channel when a notification is received.
  /// Only processes if detection is enabled in settings.
  Future<void> processNotification(
    String title,
    String body, {
    String? packageName,
  }) async {
    // Don't process if not enabled
    if (!_isEnabled) {
      if (kDebugMode) {
        debugPrint('⚠️ Notification detection is disabled in settings, skipping processing');
      }
      return;
    }

    final text = '$title $body'.trim();
    if (text.isEmpty) return;

    // Create a unique key for duplicate detection
    final notificationKey = '${text.hashCode}_${DateTime.now().millisecondsSinceEpoch ~/ 1000}';

    // Check if we've recently processed this notification
    if (_recentlyProcessed.contains(notificationKey)) {
      if (kDebugMode) {
        debugPrint('⚠️ Duplicate notification ignored: $title');
      }
      return;
    }

    // Parse using HybridParser
    final result = await parseNotificationAsync(title, body, packageName: packageName);

    if (result != null && result.hasAmount) {
      // Mark as processed
      _recentlyProcessed.add(notificationKey);

      // Emit to new stream
      _expenseResultController.add(result);

      // Emit to legacy stream for backward compatibility
      _expenseController.add(DetectedExpense.fromExpenseResult(result));

      if (kDebugMode) {
        debugPrint('✅ Detected expense: ${result.formattedAmount} from ${result.merchant ?? "unknown"}');
        debugPrint('   Confidence: ${result.confidencePercentage}');
      }
    }
  }

  /// Parse notification text asynchronously using HybridParser
  ///
  /// Returns ParsedExpenseResult with confidence score, or null if not a valid expense.
  Future<ParsedExpenseResult?> parseNotificationAsync(
    String title,
    String body, {
    String? packageName,
  }) async {
    final text = '$title $body'.trim();
    if (text.isEmpty) return null;

    // Initialize parser if needed
    _genericParser ??= GenericExpenseParser();
    _hybridParser ??= HybridExpenseParser(genericParser: _genericParser);

    // Check if it looks like a debit transaction first (fast check)
    if (!_genericParser!.isDebitTransaction(text)) {
      if (kDebugMode) {
        debugPrint('⚠️ Not a debit notification, skipping');
      }
      return null;
    }

    // Parse using hybrid parser (tries generic first, then AI if needed)
    final result = await _hybridParser!.parse(text, ParsingSource.sms);

    // Only return if we got a valid amount
    if (!result.hasAmount) {
      if (kDebugMode) {
        debugPrint('⚠️ No amount found in notification');
      }
      return null;
    }

    // Add package name to metadata
    if (packageName != null) {
      return result.copyWith(
        metadata: {...?result.metadata, 'packageName': packageName},
      );
    }

    return result;
  }

  /// Parse notification text synchronously (legacy method)
  ///
  /// Use parseNotificationAsync for better results with AI fallback.
  @Deprecated('Use parseNotificationAsync for better results')
  DetectedExpense? parseNotification(
    String title,
    String body, {
    String? packageName,
  }) {
    final text = '$title $body'.trim();
    if (text.isEmpty) return null;

    // Initialize parser if needed
    _genericParser ??= GenericExpenseParser();

    // Check if it's a debit notification
    if (!_genericParser!.isDebitTransaction(text)) return null;

    // Parse using generic parser only (synchronous)
    final result = _genericParser!.parse(text, ParsingSource.sms);

    // Only return if we got a valid amount
    if (!result.hasAmount) return null;

    return DetectedExpense.fromExpenseResult(result.copyWith(
      metadata: packageName != null ? {'packageName': packageName} : null,
    ));
  }

  /// Get the hybrid parser instance
  HybridExpenseParser? get hybridParser => _hybridParser;

  /// Get the generic parser instance
  GenericExpenseParser? get genericParser => _genericParser;

  void dispose() {
    _stopListening();
    _cleanupTimer?.cancel();
    _recentlyProcessed.clear();
    _expenseResultController.close();
    _expenseController.close();
  }
}
