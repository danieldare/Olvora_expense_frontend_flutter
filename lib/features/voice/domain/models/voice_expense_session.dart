/// Domain models for voice expense conversation system
library;

/// Confidence level for extracted entities
enum ConfidenceLevel {
  high, // > 0.85 - Auto-fill, no confirmation needed
  medium, // 0.6-0.85 - Show as suggestion
  low, // < 0.6 - Ask for clarification
}

/// State of the conversation
enum ConversationState {
  idle,
  listening,
  processing,
  gathering,
  confirming,
  saved,
  cancelled,
}

/// A single extracted entity with confidence
class ExtractedEntity<T> {
  final T? value;
  final double confidence;
  final String? rawText;
  final List<T>? alternatives; // For ambiguous values

  const ExtractedEntity({
    this.value,
    this.confidence = 0.0,
    this.rawText,
    this.alternatives,
  });

  ConfidenceLevel get confidenceLevel {
    if (confidence >= 0.85) return ConfidenceLevel.high;
    if (confidence >= 0.6) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  bool get isPresent => value != null && confidence > 0.3;
  bool get needsClarification =>
      alternatives != null && alternatives!.length > 1;

  ExtractedEntity<T> merge(ExtractedEntity<T> other) {
    // Later value with higher confidence wins
    if (other.value != null && other.confidence >= confidence) {
      return other;
    }
    return this;
  }

  ExtractedEntity<T> copyWith({
    T? value,
    double? confidence,
    String? rawText,
    List<T>? alternatives,
  }) {
    return ExtractedEntity<T>(
      value: value ?? this.value,
      confidence: confidence ?? this.confidence,
      rawText: rawText ?? this.rawText,
      alternatives: alternatives ?? this.alternatives,
    );
  }
}

/// Voice segment captured during a session
class VoiceSegment {
  final String id;
  final String audioFilePath; // Local file path for raw audio
  final String? transcribedText; // Null if not yet transcribed
  final DateTime timestamp;
  final bool isProcessed;
  final bool isUploaded; // Whether audio has been uploaded to backend
  final String? errorMessage;
  final int? durationMs; // Recording duration in milliseconds
  final double? averageAudioLevel; // Average RMS audio level

  const VoiceSegment({
    required this.id,
    required this.audioFilePath,
    this.transcribedText,
    required this.timestamp,
    this.isProcessed = false,
    this.isUploaded = false,
    this.errorMessage,
    this.durationMs,
    this.averageAudioLevel,
  });

  VoiceSegment copyWith({
    String? id,
    String? audioFilePath,
    String? transcribedText,
    DateTime? timestamp,
    bool? isProcessed,
    bool? isUploaded,
    String? errorMessage,
    int? durationMs,
    double? averageAudioLevel,
  }) {
    return VoiceSegment(
      id: id ?? this.id,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      transcribedText: transcribedText ?? this.transcribedText,
      timestamp: timestamp ?? this.timestamp,
      isProcessed: isProcessed ?? this.isProcessed,
      isUploaded: isUploaded ?? this.isUploaded,
      errorMessage: errorMessage ?? this.errorMessage,
      durationMs: durationMs ?? this.durationMs,
      averageAudioLevel: averageAudioLevel ?? this.averageAudioLevel,
    );
  }
}

/// Chat message in the conversation
class ChatMessage {
  final String id;
  final bool isUser;
  final String content;
  final DateTime timestamp;
  final MessageType type;

  const ChatMessage({
    required this.id,
    required this.isUser,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
  });
}

enum MessageType {
  text,
  summary, // Expense summary card
  suggestion, // Category/merchant suggestion
  clarification, // Asking for clarification
  success, // Expense saved
  error, // Error message
}

/// Accumulated expense data from the session
class AccumulatedExpenseData {
  final ExtractedEntity<double> amount;
  final ExtractedEntity<String> currency;
  final ExtractedEntity<String> merchant;
  final ExtractedEntity<DateTime> date;
  final ExtractedEntity<String> category;
  final ExtractedEntity<String> description;

  const AccumulatedExpenseData({
    this.amount = const ExtractedEntity(),
    this.currency = const ExtractedEntity(value: 'NGN', confidence: 0.5),
    this.merchant = const ExtractedEntity(),
    this.date = const ExtractedEntity(),
    this.category = const ExtractedEntity(),
    this.description = const ExtractedEntity(),
  });

  /// Check if all required fields are present
  bool get isComplete =>
      amount.isPresent &&
      merchant.isPresent &&
      date.isPresent &&
      category.isPresent;

  /// Get list of missing fields
  List<String> get missingFields {
    final missing = <String>[];
    if (!amount.isPresent) missing.add('amount');
    if (!merchant.isPresent) missing.add('merchant');
    if (!date.isPresent) missing.add('date');
    if (!category.isPresent) missing.add('category');
    return missing;
  }

  /// Get list of fields needing clarification
  List<String> get ambiguousFields {
    final ambiguous = <String>[];
    if (amount.needsClarification) ambiguous.add('amount');
    if (merchant.needsClarification) ambiguous.add('merchant');
    if (category.needsClarification) ambiguous.add('category');
    return ambiguous;
  }

  /// Merge with new extracted data
  AccumulatedExpenseData merge(AccumulatedExpenseData other) {
    return AccumulatedExpenseData(
      amount: amount.merge(other.amount),
      currency: currency.merge(other.currency),
      merchant: merchant.merge(other.merchant),
      date: date.merge(other.date),
      category: category.merge(other.category),
      description: description.merge(other.description),
    );
  }

  AccumulatedExpenseData copyWith({
    ExtractedEntity<double>? amount,
    ExtractedEntity<String>? currency,
    ExtractedEntity<String>? merchant,
    ExtractedEntity<DateTime>? date,
    ExtractedEntity<String>? category,
    ExtractedEntity<String>? description,
  }) {
    return AccumulatedExpenseData(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }
}

/// Complete session state
class VoiceExpenseSession {
  final String sessionId;
  final ConversationState state;
  final List<VoiceSegment> voiceSegments;
  final List<ChatMessage> messages;
  final AccumulatedExpenseData expenseData;
  final DateTime createdAt;
  final DateTime? savedAt;
  final bool isOffline;

  const VoiceExpenseSession({
    required this.sessionId,
    this.state = ConversationState.idle,
    this.voiceSegments = const [],
    this.messages = const [],
    this.expenseData = const AccumulatedExpenseData(),
    required this.createdAt,
    this.savedAt,
    this.isOffline = false,
  });

  VoiceExpenseSession copyWith({
    String? sessionId,
    ConversationState? state,
    List<VoiceSegment>? voiceSegments,
    List<ChatMessage>? messages,
    AccumulatedExpenseData? expenseData,
    DateTime? createdAt,
    DateTime? savedAt,
    bool? isOffline,
  }) {
    return VoiceExpenseSession(
      sessionId: sessionId ?? this.sessionId,
      state: state ?? this.state,
      voiceSegments: voiceSegments ?? this.voiceSegments,
      messages: messages ?? this.messages,
      expenseData: expenseData ?? this.expenseData,
      createdAt: createdAt ?? this.createdAt,
      savedAt: savedAt ?? this.savedAt,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}
