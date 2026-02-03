/// Source of the parsed expense data
enum ParsingSource {
  /// From SMS/push notification
  sms,

  /// From clipboard (copy-paste)
  clipboard,

  /// From voice input
  voice,

  /// From receipt image/PDF
  receipt,

  /// Manual entry
  manual,
}

/// Confidence level for parsed expense
enum ConfidenceLevel {
  /// 90%+ confidence - can auto-create
  high,

  /// 70-89% confidence - show preview modal
  medium,

  /// 50-69% confidence - show subtle notification
  low,

  /// Below 50% - log for learning, don't interrupt
  veryLow,
}

/// Unified result model for parsed expenses from any source
///
/// This model is used by SMS detection, clipboard monitoring, voice input,
/// and receipt scanning to provide a consistent interface for expense data.
class ParsedExpenseResult {
  /// Extracted amount (required for valid expense)
  final double? amount;

  /// Detected currency code (USD, EUR, GBP, NGN, INR, etc.)
  final String? currency;

  /// Currency symbol if detected ($, £, €, ₦, ₹, etc.)
  final String? currencySymbol;

  /// Merchant/vendor name
  final String? merchant;

  /// Suggested category based on merchant or keywords
  final String? category;

  /// Transaction date
  final DateTime? date;

  /// Additional description or notes
  final String? description;

  /// Account identifier (e.g., last 4 digits of card/account)
  final String? accountIdentifier;

  /// Account balance after transaction (if available)
  final double? balance;

  /// Transaction type (debit, credit, transfer, etc.)
  final String? transactionType;

  /// Original raw text that was parsed
  final String rawText;

  /// Confidence score from 0.0 to 1.0
  final double confidence;

  /// List of fields that were successfully extracted
  final List<String> extractedFields;

  /// List of fields that could not be extracted
  final List<String> missingFields;

  /// Source of this parsed expense
  final ParsingSource source;

  /// Suggested title for the expense
  final String? suggestedTitle;

  /// Unique hash for duplicate detection
  final String? contentHash;

  /// Timestamp when parsing occurred
  final DateTime parsedAt;

  /// Additional metadata from parsing
  final Map<String, dynamic>? metadata;

  ParsedExpenseResult({
    this.amount,
    this.currency,
    this.currencySymbol,
    this.merchant,
    this.category,
    this.date,
    this.description,
    this.accountIdentifier,
    this.balance,
    this.transactionType,
    required this.rawText,
    required this.confidence,
    this.extractedFields = const [],
    this.missingFields = const [],
    required this.source,
    this.suggestedTitle,
    this.contentHash,
    DateTime? parsedAt,
    this.metadata,
  }) : parsedAt = parsedAt ?? DateTime.now();

  /// Whether this result has a valid amount
  bool get hasAmount => amount != null && amount! > 0;

  /// Whether this result has enough data to create an expense
  bool get isValid => hasAmount;

  /// Get confidence level based on score
  ConfidenceLevel get confidenceLevel {
    if (confidence >= 0.90) return ConfidenceLevel.high;
    if (confidence >= 0.70) return ConfidenceLevel.medium;
    if (confidence >= 0.50) return ConfidenceLevel.low;
    return ConfidenceLevel.veryLow;
  }

  /// Human-readable confidence percentage
  String get confidencePercentage => '${(confidence * 100).round()}%';

  /// Get formatted amount with currency
  String get formattedAmount {
    if (amount == null) return '';
    final symbol = currencySymbol ?? currency ?? '';
    return '$symbol${amount!.toStringAsFixed(2)}';
  }

  /// Create a copy with updated fields
  ParsedExpenseResult copyWith({
    double? amount,
    String? currency,
    String? currencySymbol,
    String? merchant,
    String? category,
    DateTime? date,
    String? description,
    String? accountIdentifier,
    double? balance,
    String? transactionType,
    String? rawText,
    double? confidence,
    List<String>? extractedFields,
    List<String>? missingFields,
    ParsingSource? source,
    String? suggestedTitle,
    String? contentHash,
    DateTime? parsedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ParsedExpenseResult(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      accountIdentifier: accountIdentifier ?? this.accountIdentifier,
      balance: balance ?? this.balance,
      transactionType: transactionType ?? this.transactionType,
      rawText: rawText ?? this.rawText,
      confidence: confidence ?? this.confidence,
      extractedFields: extractedFields ?? this.extractedFields,
      missingFields: missingFields ?? this.missingFields,
      source: source ?? this.source,
      suggestedTitle: suggestedTitle ?? this.suggestedTitle,
      contentHash: contentHash ?? this.contentHash,
      parsedAt: parsedAt ?? this.parsedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for API calls or storage
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'currencySymbol': currencySymbol,
      'merchant': merchant,
      'category': category,
      'date': date?.toIso8601String(),
      'description': description,
      'accountIdentifier': accountIdentifier,
      'balance': balance,
      'transactionType': transactionType,
      'rawText': rawText,
      'confidence': confidence,
      'extractedFields': extractedFields,
      'missingFields': missingFields,
      'source': source.name,
      'suggestedTitle': suggestedTitle,
      'contentHash': contentHash,
      'parsedAt': parsedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory ParsedExpenseResult.fromJson(Map<String, dynamic> json) {
    return ParsedExpenseResult(
      amount: (json['amount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      currencySymbol: json['currencySymbol'] as String?,
      merchant: json['merchant'] as String?,
      category: json['category'] as String?,
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      description: json['description'] as String?,
      accountIdentifier: json['accountIdentifier'] as String?,
      balance: (json['balance'] as num?)?.toDouble(),
      transactionType: json['transactionType'] as String?,
      rawText: json['rawText'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      extractedFields: (json['extractedFields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      missingFields: (json['missingFields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      source: ParsingSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => ParsingSource.manual,
      ),
      suggestedTitle: json['suggestedTitle'] as String?,
      contentHash: json['contentHash'] as String?,
      parsedAt: json['parsedAt'] != null
          ? DateTime.parse(json['parsedAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Generate a content hash for duplicate detection
  static String generateContentHash(String text, double? amount, String? merchant) {
    final normalizedText = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final amountStr = amount?.toStringAsFixed(2) ?? '';
    final merchantStr = merchant?.toLowerCase().trim() ?? '';
    return '${normalizedText.hashCode}_${amountStr}_$merchantStr';
  }

  @override
  String toString() {
    return 'ParsedExpenseResult('
        'amount: $formattedAmount, '
        'merchant: $merchant, '
        'confidence: $confidencePercentage, '
        'source: ${source.name}'
        ')';
  }
}
