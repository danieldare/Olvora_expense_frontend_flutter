import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../../data/repositories/ora_repository.dart';
import '../../data/services/conversation_storage_service.dart';
import '../../domain/models/ora_conversation_state.dart';
import '../../domain/models/ora_message.dart';
import '../../../receipts/data/services/mlkit_ocr_service.dart';
import '../../../../core/utils/app_logger.dart';

/// State notifier for Ora conversation
class OraConversationNotifier extends StateNotifier<OraConversationState> {
  final OraRepository _repository;
  final ConversationStorageService _storage = ConversationStorageService();

  OraConversationNotifier({required OraRepository repository})
    : _repository = repository,
      super(OraConversationState.initial());

  /// Send a text message to Ora (with streaming support)
  Future<void> sendMessage(String text, {bool stream = true}) async {
    if (text.trim().isEmpty) return;

    // 1. Add optimistic user message
    final userMessage = UserMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      inputState: OraInputState.processing,
    );

    // 2. Add typing indicator (will show avatar + loading)
    _addTypingIndicator();
    final typingMessageId = 'typing-indicator';

    try {
      // 3. Send to API with streaming
      final response = await _repository.sendMessage(
        text: text,
        conversationId: state.conversationId.isEmpty
            ? null
            : state.conversationId,
        stream: stream,
        onChunk: stream
            ? (chunk, accumulated) {
                // Update the streaming message in real-time
                _updateStreamingMessage(typingMessageId, accumulated);
              }
            : null,
      );

      // 4. Finalize streaming message (remove typing indicator and mark as complete)
      final finalMessage = response.message;
      if (stream && finalMessage is AssistantMessage) {
        // Replace typing indicator with final message
        _finalizeStreamingMessage(typingMessageId, finalMessage);
      } else {
        // Non-streaming: remove typing and add response
        _removeTypingIndicator();
        state = state.copyWith(
          conversationId: response.conversationId,
          messages: [...state.messages, finalMessage],
        );

        // Persist conversation ID
        await _storage.saveLastConversationId(response.conversationId);
      }

      state = state.copyWith(
        conversationId: response.conversationId,
        inputState: response.pendingConfirmation != null
            ? OraInputState.awaitingConfirmation
            : OraInputState.idle,
        pendingConfirmation: response.pendingConfirmation,
      );

      // Persist conversation ID
      await _storage.saveLastConversationId(response.conversationId);
    } catch (e) {
      _removeTypingIndicator();
      _addErrorMessage(e);
      state = state.copyWith(inputState: OraInputState.idle);
    }
  }

  /// Send a voice message to Ora
  Future<void> sendVoice(File audioFile) async {
    state = state.copyWith(inputState: OraInputState.processing);

    // Store the audio path for cleanup after successful expense creation
    final audioPath = audioFile.path;

    // Add user message with voice indicator and isVoice metadata
    final userMessage = UserMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '🎤 Voice message',
      attachments: [
        // Keep audio path reference for later cleanup
        OraAttachment(type: AttachmentType.audio, localPath: audioPath),
      ],
      metadata: {'isVoice': true}, // Persistent voice flag
      timestamp: DateTime.now(),
    );

    state = state.copyWith(messages: [...state.messages, userMessage]);

    _addTypingIndicator();

    try {
      final response = await _repository.sendVoice(
        audioFile: audioFile,
        conversationId: state.conversationId.isEmpty
            ? null
            : state.conversationId,
      );

      // Remove typing indicator first
      _removeTypingIndicator();

      // Update user message with transcription if available
      // Keep the audio attachment for cleanup later, but show transcription as text
      final updatedMessages = state.messages
          .where((m) => m.id != 'typing-indicator')
          .map((m) {
            if (m.id == userMessage.id &&
                m is UserMessage &&
                response.transcription != null) {
              return UserMessage(
                id: m.id,
                text: response.transcription!, // Show what user said
                attachments: m.attachments, // Keep audio reference
                metadata: m.metadata, // Preserve isVoice flag
                timestamp: m.timestamp,
              );
            }
            return m;
          })
          .toList();

      state = state.copyWith(
        conversationId: response.conversationId,
        messages: [...updatedMessages, response.message],
        inputState: response.pendingConfirmation != null
            ? OraInputState.awaitingConfirmation
            : OraInputState.idle,
        pendingConfirmation: response.pendingConfirmation,
      );

      // Don't delete audio yet - wait until expense is confirmed
    } catch (e) {
      _removeTypingIndicator();
      _addErrorMessage(e);
      state = state.copyWith(inputState: OraInputState.idle);
      // Delete on error since we won't be able to confirm
      _deleteAudioFile(audioPath);
    }
  }

  /// Delete a single audio file to save storage space
  Future<void> _deleteAudioFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted audio file: $path');
      }
    } catch (e) {
      debugPrint('Failed to delete audio file: $e');
      // Non-critical error, don't throw
    }
  }

  /// Clean up all audio files from user messages after successful expense creation
  Future<void> _cleanupAudioFiles() async {
    for (final message in state.messages) {
      if (message is UserMessage) {
        final attachments = message.attachments;
        if (attachments != null && attachments.isNotEmpty) {
          for (final attachment in attachments) {
            if (attachment.type == AttachmentType.audio &&
                attachment.localPath != null) {
              await _deleteAudioFile(attachment.localPath!);
            }
          }
        }
      }
    }
    debugPrint('Audio cleanup completed after expense confirmation');
  }

  /// Send an image (receipt) to Ora
  /// Uses ML Kit OCR first, then sends OCR text to backend for OpenAI parsing
  Future<void> sendImage(File imageFile, {String? caption}) async {
    state = state.copyWith(inputState: OraInputState.processing);

    final userMessage = UserMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: caption ?? 'Sent a receipt',
      attachments: [
        OraAttachment(type: AttachmentType.image, localPath: imageFile.path),
      ],
      timestamp: DateTime.now(),
    );

    state = state.copyWith(messages: [...state.messages, userMessage]);

    _addTypingIndicator();

    try {
      // Step 1: Extract OCR text using ML Kit
      String? ocrText;
      try {
        final mlKitOCR = MLKitOCRService();
        ocrText = await mlKitOCR.extractText(imageFile);
        if (ocrText != null && ocrText.trim().isNotEmpty) {
          AppLogger.d(
            'ML Kit OCR extracted ${ocrText.length} characters',
            tag: 'OraImage',
          );
        } else {
          AppLogger.w('ML Kit OCR returned empty text', tag: 'OraImage');
        }
      } catch (e) {
        AppLogger.w(
          'ML Kit OCR failed, will use Vision API fallback: $e',
          tag: 'OraImage',
        );
        // Continue without OCR text - backend will use Vision API
      }

      // Step 2: Send image with OCR text to backend
      final response = await _repository.sendImage(
        imageFile: imageFile,
        caption: caption,
        ocrText: ocrText,
        conversationId: state.conversationId.isEmpty
            ? null
            : state.conversationId,
      );

      _removeTypingIndicator();

      state = state.copyWith(
        conversationId: response.conversationId,
        messages: [...state.messages, response.message],
        inputState: OraInputState.awaitingConfirmation,
        pendingConfirmation: response.pendingConfirmation,
      );
    } catch (e) {
      _removeTypingIndicator();
      _addErrorMessage(e);
      state = state.copyWith(inputState: OraInputState.idle);
    }
  }

  /// Execute an action (confirm, edit, undo, cancel)
  /// Returns the response from the backend
  Future<OraResponse?> executeAction(OraActionButton action) async {
    if (state.conversationId.isEmpty) return null;

    state = state.copyWith(inputState: OraInputState.processing);
    _addTypingIndicator();

    try {
      // Find the last assistant message that has actions
      final lastMessageWithActions = state.messages.lastWhere(
        (m) =>
            m is AssistantMessage && m.actions != null && m.actions!.isNotEmpty,
        orElse: () => state.messages.last,
      );

      final response = await _repository.executeAction(
        conversationId: state.conversationId,
        messageId: lastMessageWithActions.id,
        actionId: action.id,
        actionType: action.actionType,
        payload: action.payload,
      );

      _removeTypingIndicator();

      // Remove actions AND structured content (pending expenses) from the message that had them
      // Also filter out any remaining typing indicators
      final updatedMessages = state.messages
          .where((m) => m.id != 'typing-indicator')
          .map((m) {
            if (m.id == lastMessageWithActions.id && m is AssistantMessage) {
              return AssistantMessage(
                id: m.id,
                text: m.text,
                structuredContent: null, // Clear pending expenses display
                actions: null, // Clear actions
                isStreaming: false,
                timestamp: m.timestamp,
              );
            }
            return m;
          })
          .toList();

      // Add the response message
      final messagesWithResponse = [...updatedMessages, response.message];

      // For successful actions, add a follow-up message with its own avatar
      final isConfirmAction =
          action.actionType == OraActionType.confirm ||
          action.actionType == OraActionType.confirmAll;

      final isSuccess =
          isConfirmAction ||
          action.actionType == OraActionType.cancel ||
          action.actionType == OraActionType.undo;

      if (isSuccess) {
        // Add a separate follow-up message
        final followUpMessage = AssistantMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}-followup',
          text: _getFollowUpPrompt(),
          timestamp: DateTime.now().add(const Duration(milliseconds: 100)),
        );
        messagesWithResponse.add(followUpMessage);
      }

      // If expense was confirmed, clean up audio files to save space
      if (isConfirmAction) {
        _cleanupAudioFiles();
      }

      state = state.copyWith(
        messages: messagesWithResponse,
        inputState: OraInputState.idle,
        pendingConfirmation: null,
      );

      // Return the response so caller can check if expense was successfully created
      return response;
    } catch (e) {
      _removeTypingIndicator();
      _addErrorMessage(e);
      state = state.copyWith(inputState: OraInputState.idle);
      return null;
    }
  }

  /// Load conversation history
  Future<void> loadConversationHistory({
    String? conversationId,
    int limit = 50,
  }) async {
    final targetConversationId = conversationId ?? state.conversationId;
    if (targetConversationId.isEmpty) {
      // No conversation ID, start new one
      return startNewConversation();
    }

    try {
      state = state.copyWith(isProcessing: true);

      final history = await _repository.getHistory(
        conversationId: targetConversationId,
        limit: limit,
        offset: 0,
      );

      state = state.copyWith(
        conversationId: targetConversationId,
        messages: history.messages,
        isProcessing: false,
        isInitializing: false,
      );

      // Persist conversation ID
      await _storage.saveLastConversationId(targetConversationId);
    } catch (e) {
      _addErrorMessage(e);
      state = state.copyWith(isProcessing: false, isInitializing: false);
      // If loading fails, start new conversation
      await startNewConversation();
    }
  }

  /// Load more messages (pagination)
  Future<void> loadMoreMessages() async {
    if (state.conversationId.isEmpty || state.isProcessing) return;

    try {
      state = state.copyWith(isProcessing: true);

      final currentCount = state.messages.length;
      // Backend returns messages in chronological order (oldest first)
      // So offset gets us the next batch of older messages
      final history = await _repository.getHistory(
        conversationId: state.conversationId,
        limit: 50,
        offset: currentCount,
      );

      if (history.messages.isNotEmpty) {
        // Prepend older messages to the beginning of the list
        // Since backend returns chronological (oldest first), these are older than what we have
        state = state.copyWith(
          messages: [...history.messages, ...state.messages],
          isProcessing: false,
        );
      } else {
        state = state.copyWith(isProcessing: false);
      }
    } catch (e) {
      _addErrorMessage(e);
      state = state.copyWith(isProcessing: false);
    }
  }

  /// Get user's first name for personalization
  String? _getUserFirstName() {
    try {
      final firebaseUser = firebase.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return null;

      if (firebaseUser.displayName != null &&
          firebaseUser.displayName!.isNotEmpty) {
        // Extract first name from display name
        final nameParts = firebaseUser.displayName!.split(' ');
        return nameParts.first;
      } else if (firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
        // Fall back to email username (part before @)
        return firebaseUser.email!.split('@').first;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Initialize conversation - loads most recent or starts new
  Future<void> initializeConversation() async {
    try {
      state = state.copyWith(isInitializing: true);

      // Try to get most recent conversation from backend
      String? conversationId = await _repository.getMostRecentConversationId();

      // Fallback to local storage if backend doesn't have one
      if (conversationId == null || conversationId.isEmpty) {
        conversationId = await _storage.getLastConversationId();
      }

      if (conversationId != null && conversationId.isNotEmpty) {
        // Load existing conversation
        await loadConversationHistory(conversationId: conversationId);
      } else {
        // Start new conversation
        await startNewConversation();
      }
    } catch (e) {
      // If loading fails, start fresh
      await startNewConversation();
    }
  }

  /// Start a new conversation
  Future<void> startNewConversation() async {
    try {
      final conversationId = await _repository.startNewConversation();
      final userName = _getUserFirstName();

      final welcomeText = userName != null
          ? "Hi $userName! I'm Ora, your expense assistant. What would you like to do today?"
          : "Hi! I'm Ora, your expense assistant. What would you like to do today?";

      state = OraConversationState(
        conversationId: conversationId,
        messages: [
          AssistantMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: welcomeText,
            timestamp: DateTime.now(),
            isStreaming: false,
          ),
        ],
        inputState: OraInputState.idle,
        isProcessing: false,
        isInitializing: false,
      );

      // Persist new conversation ID
      await _storage.saveLastConversationId(conversationId);
    } catch (e) {
      _addErrorMessage(e);
      state = state.copyWith(isProcessing: false, isInitializing: false);
    }
  }

  void _addTypingIndicator() {
    // Create an AssistantMessage with streaming state to show avatar + loading
    final typingMessage = AssistantMessage(
      id: 'typing-indicator',
      text: '',
      isStreaming: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(messages: [...state.messages, typingMessage]);
  }

  void _removeTypingIndicator() {
    state = state.copyWith(
      messages: state.messages
          .where((m) => m.id != 'typing-indicator')
          .toList(),
    );
  }

  /// Update streaming message text (for ChatGPT-like streaming)
  void _updateStreamingMessage(String messageId, String newText) {
    final updatedMessages = state.messages.map((m) {
      if (m.id == messageId && m is AssistantMessage) {
        return AssistantMessage(
          id: m.id,
          text: newText,
          structuredContent: m.structuredContent,
          actions: m.actions,
          isStreaming: true,
          timestamp: m.timestamp,
        );
      }
      return m;
    }).toList();

    state = state.copyWith(messages: updatedMessages);
  }

  /// Finalize streaming message (mark as complete)
  void _finalizeStreamingMessage(
    String messageId,
    AssistantMessage finalMessage,
  ) {
    final updatedMessages = state.messages.map((m) {
      if (m.id == messageId) {
        // Return final message without streaming flag
        return AssistantMessage(
          id: finalMessage.id,
          text: finalMessage.text,
          structuredContent: finalMessage.structuredContent,
          actions: finalMessage.actions,
          isStreaming: false, // Mark as complete
          timestamp: finalMessage.timestamp,
        );
      }
      return m;
    }).toList();

    state = state.copyWith(messages: updatedMessages);
  }

  /// Returns a natural, varied follow-up prompt
  String _getFollowUpPrompt() {
    final prompts = [
      // Natural conversational - like a helpful assistant
      'Is there anything else I can help you with?',
      'Anything else you need to track?',
      'What else can I help you with?',
      'Got any more expenses to log?',
      'Need help with anything else?',
      // Short and friendly
      'Anything else?',
      'What else?',
      'More to add?',
      // Warm and inviting
      "I'm here if you need anything else.",
      'Let me know if you have more.',
      'Just say the word when you need me.',
    ];
    return prompts[DateTime.now().millisecond % prompts.length];
  }

  void _addErrorMessage(dynamic error) {
    // Extract detailed error message
    String errorText = 'Something went wrong. Please try again.';

    if (error is DioException) {
      // Try to get message from response data
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final message = responseData['message'] ?? responseData['error'];
        if (message != null) {
          errorText = message.toString();
        } else if (error.response?.statusMessage != null) {
          errorText = error.response!.statusMessage!;
        } else if (error.message != null) {
          errorText = error.message!;
        }
      } else if (error.response?.statusMessage != null) {
        errorText = error.response!.statusMessage!;
      } else if (error.message != null) {
        errorText = error.message!;
      }

      // Add status code context for debugging
      if (error.response?.statusCode != null) {
        errorText = '$errorText (${error.response!.statusCode})';
      }
    } else if (error is Exception) {
      errorText = error.toString();
    } else if (error != null) {
      errorText = error.toString();
    }

    final errorMessage = SystemMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: errorText,
      type: OraSystemMessageType.error,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, errorMessage],
      error: OraError.fromException(error),
    );
  }
}
