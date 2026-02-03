import 'package:isar/isar.dart';
import 'offline_message.dart';

part 'offline_expense.g.dart';

/// Expense entry mode
enum ExpenseEntryMode {
  ora,          // Created via Ora AI
  manual,       // Manual entry
  receipt,      // From receipt scan
  notification, // From bank notification
  import_,      // Imported from external source
}

/// Offline expense stored in Isar
@collection
class OfflineExpense {
  Id id = Isar.autoIncrement;

  /// Local UUID for this expense
  @Index(unique: true)
  late String localId;

  /// Server ID (null until synced)
  String? serverId;

  /// User who owns this expense
  @Index()
  late String userId;

  /// Amount (stored as integer cents to avoid floating point issues)
  late int amountCents;

  /// Currency code (ISO 4217)
  @Index()
  late String currency;

  /// Description/title
  late String description;

  /// Merchant name
  String? merchant;

  /// Category
  @Index()
  String? category;

  /// Date of the expense
  @Index()
  late DateTime expenseDate;

  /// Trip ID (if part of a trip)
  @Index()
  String? tripId;

  /// Entry mode
  @Enumerated(EnumType.ordinal)
  late ExpenseEntryMode entryMode;

  /// Notes
  String? notes;

  /// Tags (comma-separated for Isar compatibility)
  String? tagsString;

  /// Receipt image local path
  String? receiptLocalPath;

  /// Receipt image URL (after upload)
  String? receiptUrl;

  /// Sync status
  @Enumerated(EnumType.ordinal)
  @Index()
  late SyncStatus syncStatus;

  /// Number of sync attempts
  late int retryCount;

  /// Last error message
  String? errorMessage;

  /// Local ID of the message that created this expense
  String? sourceMessageLocalId;

  /// When created locally
  @Index()
  late DateTime createdAt;

  /// When last modified locally
  late DateTime updatedAt;

  /// When synced to server
  DateTime? syncedAt;

  /// Server version (for conflict detection)
  int? serverVersion;

  /// Local version
  late int localVersion;

  /// Soft delete flag
  @Index()
  late bool isDeleted;

  /// Creates a new offline expense
  static OfflineExpense create({
    required String localId,
    required String userId,
    required double amount,
    required String currency,
    required String description,
    String? merchant,
    String? category,
    DateTime? expenseDate,
    String? tripId,
    ExpenseEntryMode entryMode = ExpenseEntryMode.ora,
    String? notes,
    List<String>? tags,
    String? receiptLocalPath,
    String? sourceMessageLocalId,
  }) {
    final now = DateTime.now();
    return OfflineExpense()
      ..localId = localId
      ..userId = userId
      ..amountCents = (amount * 100).round()
      ..currency = currency
      ..description = description
      ..merchant = merchant
      ..category = category
      ..expenseDate = expenseDate ?? now
      ..tripId = tripId
      ..entryMode = entryMode
      ..notes = notes
      ..tagsString = tags?.join(',')
      ..receiptLocalPath = receiptLocalPath
      ..syncStatus = SyncStatus.pending
      ..retryCount = 0
      ..sourceMessageLocalId = sourceMessageLocalId
      ..createdAt = now
      ..updatedAt = now
      ..localVersion = 1
      ..isDeleted = false;
  }

  /// Get amount as double
  double get amount => amountCents / 100.0;

  /// Set amount from double
  set amount(double value) => amountCents = (value * 100).round();

  /// Get tags as list
  List<String> get tags =>
      tagsString?.split(',').where((t) => t.isNotEmpty).toList() ?? [];

  /// Set tags from list
  set tags(List<String> value) => tagsString = value.join(',');

  /// Mark as syncing
  void markSyncing() {
    syncStatus = SyncStatus.syncing;
    updatedAt = DateTime.now();
  }

  /// Mark as synced
  void markSynced(String serverId, int serverVersion) {
    this.serverId = serverId;
    this.serverVersion = serverVersion;
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

  /// Mark as conflict
  void markConflict(String error) {
    syncStatus = SyncStatus.conflict;
    errorMessage = error;
    updatedAt = DateTime.now();
  }

  /// Mark for soft delete
  void markDeleted() {
    isDeleted = true;
    syncStatus = SyncStatus.pending;
    updatedAt = DateTime.now();
    localVersion++;
  }

  /// Update locally
  void updateLocally({
    double? amount,
    String? currency,
    String? description,
    String? merchant,
    String? category,
    DateTime? expenseDate,
    String? notes,
    List<String>? tags,
  }) {
    if (amount != null) amountCents = (amount * 100).round();
    if (currency != null) this.currency = currency;
    if (description != null) this.description = description;
    if (merchant != null) this.merchant = merchant;
    if (category != null) this.category = category;
    if (expenseDate != null) this.expenseDate = expenseDate;
    if (notes != null) this.notes = notes;
    if (tags != null) tagsString = tags.join(',');

    syncStatus = SyncStatus.pending;
    updatedAt = DateTime.now();
    localVersion++;
  }

  /// Check if should retry
  bool get shouldRetry => retryCount < 5 && syncStatus == SyncStatus.failed;

  /// Format amount with currency symbol
  String get formattedAmount {
    final symbols = {
      'NGN': '₦',
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
    };
    final symbol = symbols[currency] ?? currency;
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}
