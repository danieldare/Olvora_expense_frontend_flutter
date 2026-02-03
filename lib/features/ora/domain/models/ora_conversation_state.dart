import 'ora_message.dart';

/// Input state for Ora conversation
enum OraInputState { idle, typing, recording, processing, awaitingConfirmation }

/// Conversation state for Ora AI Assistant
class OraConversationState {
  final String conversationId;
  final List<OraMessage> messages;
  final OraInputState inputState;
  final bool isProcessing;
  final bool isInitializing;
  final OraError? error;
  final PendingConfirmation? pendingConfirmation;

  const OraConversationState({
    required this.conversationId,
    required this.messages,
    required this.inputState,
    this.isProcessing = false,
    this.isInitializing = false,
    this.error,
    this.pendingConfirmation,
  });

  factory OraConversationState.initial() {
    return const OraConversationState(
      conversationId: '',
      messages: [],
      inputState: OraInputState.idle,
      isProcessing: false,
      isInitializing: true,
    );
  }

  OraConversationState copyWith({
    String? conversationId,
    List<OraMessage>? messages,
    OraInputState? inputState,
    bool? isProcessing,
    bool? isInitializing,
    OraError? error,
    PendingConfirmation? pendingConfirmation,
  }) {
    return OraConversationState(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      inputState: inputState ?? this.inputState,
      isProcessing: isProcessing ?? this.isProcessing,
      isInitializing: isInitializing ?? this.isInitializing,
      error: error ?? this.error,
      pendingConfirmation: pendingConfirmation ?? this.pendingConfirmation,
    );
  }
}

/// Pending confirmation for user actions
class PendingConfirmation {
  final List<Map<String, dynamic>>? expenses;
  final List<String> actions;

  const PendingConfirmation({this.expenses, required this.actions});
}

/// Error in Ora conversation
class OraError {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  const OraError({required this.message, this.code, this.details});

  factory OraError.fromException(dynamic exception) {
    return OraError(message: exception.toString(), code: 'UNKNOWN_ERROR');
  }
}
