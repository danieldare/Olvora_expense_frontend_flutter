import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../../../core/utils/auth_error_handler.dart';
import '../../data/services/voice_conversation_service.dart';
import '../../data/services/voice_input_service.dart';
import '../../data/services/raw_audio_recorder_service.dart';
import '../../domain/models/voice_expense_session.dart';

/// Provider for voice conversation service
final voiceConversationServiceProvider = Provider<VoiceConversationService>((
  ref,
) {
  final apiService = ref.watch(apiServiceV2Provider);
  return VoiceConversationService(apiService);
});

/// Provider for voice input service (legacy - using speech_to_text)
final voiceInputServiceProvider = Provider<VoiceInputService>((ref) {
  return VoiceInputService();
});

/// Provider for raw audio recorder service (world-class implementation)
final rawAudioRecorderServiceProvider = Provider<RawAudioRecorderService>((
  ref,
) {
  final service = RawAudioRecorderService();
  // Don't initialize immediately - let it initialize lazily when recording starts
  // This ensures the EventChannel is ready before we try to listen
  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Main state notifier for voice expense session
class VoiceExpenseNotifier extends StateNotifier<VoiceExpenseSession> {
  final VoiceConversationService _service;
  final Uuid _uuid = const Uuid();
  StreamSubscription<List<ConnectivityResult>>? _networkSubscription;

  VoiceExpenseNotifier(this._service)
    : super(
        VoiceExpenseSession(
          sessionId: const Uuid().v4(),
          createdAt: DateTime.now(),
        ),
      ) {
    // Set up network listener on initialization
    _setupNetworkListener();
    // Clean up old recordings on initialization
    _cleanupOldRecordings();
  }

  @override
  void dispose() {
    _networkSubscription?.cancel();
    _networkSubscription = null;
    super.dispose();
  }

  /// Clean up audio file after successful upload and transcription
  Future<void> _cleanupAudioFile(String filePath) async {
    if (filePath.isEmpty) return;

    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        if (kDebugMode) {
          debugPrint('✅ Cleaned up audio file: ${file.path}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to clean up audio file: $e');
      }
      // Don't throw - file cleanup failure shouldn't break the app
    }
  }

  /// Clean up old recordings on app start (files older than 7 days)
  Future<void> _cleanupOldRecordings() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final voiceDir = Directory('${dir.path}/voice_recordings');

      if (!await voiceDir.exists()) {
        return;
      }

      final files = await voiceDir.list().toList();
      final now = DateTime.now();
      int deletedCount = 0;

      for (final file in files) {
        if (file is File) {
          try {
            final stat = await file.stat();
            final age = now.difference(stat.modified);

            // Delete files older than 7 days
            if (age.inDays > 7) {
              await file.delete();
              deletedCount++;
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ Error checking file age: $e');
            }
          }
        }
      }

      if (kDebugMode && deletedCount > 0) {
        debugPrint('✅ Cleaned up $deletedCount old recording(s)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to clean up old recordings: $e');
      }
      // Don't throw - cleanup failure shouldn't break the app
    }
  }

  /// Start a new session
  void startNewSession() {
    state = VoiceExpenseSession(
      sessionId: _uuid.v4(),
      createdAt: DateTime.now(),
      messages: [
        ChatMessage(
          id: _uuid.v4(),
          isUser: false,
          content:
              "Hi! Tell me about your expense. For example:\n\n\"Lunch at Chicken Republic, ₦4,500 yesterday\"",
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  /// Update state to listening
  void startListening() {
    state = state.copyWith(state: ConversationState.listening);
  }

  /// Stop listening
  void stopListening() {
    state = state.copyWith(state: ConversationState.gathering);
  }

  /// Add a voice segment with audio file path (World-Class Raw Audio)
  Future<void> addVoiceSegment({
    required String audioFilePath,
    int? durationMs,
    double? averageAudioLevel,
  }) async {
    // Add voice segment (transcription will happen on backend)
    final segment = VoiceSegment(
      id: _uuid.v4(),
      audioFilePath: audioFilePath,
      timestamp: DateTime.now(),
      durationMs: durationMs,
      averageAudioLevel: averageAudioLevel,
    );

    state = state.copyWith(
      state: ConversationState.processing,
      voiceSegments: [...state.voiceSegments, segment],
    );

    // Process with backend (upload audio, transcribe, extract)
    await _processVoiceSegment(segment);
  }

  /// Legacy method for text-based segments (kept for backward compatibility)
  Future<void> addVoiceSegmentFromText(String transcribedText) async {
    if (transcribedText.isEmpty) {
      _addAssistantMessage(
        "I didn't catch that. Could you try again?",
        type: MessageType.error,
      );
      state = state.copyWith(state: ConversationState.gathering);
      return;
    }

    // Add user message to chat
    _addUserMessage(transcribedText);

    // Add voice segment (legacy - text-only segment)
    final segment = VoiceSegment(
      id: _uuid.v4(),
      audioFilePath: '', // Empty for text-only legacy segments
      transcribedText: transcribedText,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      state: ConversationState.processing,
      voiceSegments: [...state.voiceSegments, segment],
    );

    // Process with backend
    await _processVoiceSegment(segment);
  }

  Future<void> _processVoiceSegment(VoiceSegment segment) async {
    // Offline-First: Check network connectivity
    final connectivity = Connectivity();
    final connectivityResults = await connectivity.checkConnectivity();
    final isOnline = connectivityResults.any(
      (result) => result != ConnectivityResult.none,
    );

    // If segment has audio file, upload and transcribe first
    if (segment.audioFilePath.isNotEmpty) {
      if (!isOnline) {
        // Offline: Queue for later, show message
        _addAssistantMessage(
          "Saved. Will process when online.",
          type: MessageType.text,
        );

        // Mark segment as queued (not uploaded)
        final updatedSegments = state.voiceSegments.map((s) {
          if (s.id == segment.id) {
            return s.copyWith(isUploaded: false);
          }
          return s;
        }).toList();

        state = state.copyWith(
          state: ConversationState.gathering,
          voiceSegments: updatedSegments,
          isOffline: true,
        );

        // Set up listener to auto-resume when network returns
        _setupNetworkListener();
        return;
      }

      // Online: Upload and transcribe
      try {
        final transcribedText = await _service.uploadAudioAndTranscribe(
          audioFilePath: segment.audioFilePath,
          sessionId: state.sessionId,
        );

        // Update segment with transcription
        final updatedSegments = state.voiceSegments.map((s) {
          if (s.id == segment.id) {
            return s.copyWith(
              transcribedText: transcribedText,
              isUploaded: true,
            );
          }
          return s;
        }).toList();

        state = state.copyWith(voiceSegments: updatedSegments);

        // Clean up audio file after successful upload and transcription
        await _cleanupAudioFile(segment.audioFilePath);

        // Now process the transcribed text
        await _processTranscribedText(transcribedText, segment.id);
      } catch (e) {
        final errorMessage = e.toString();

        // Handle authentication errors using centralized handler
        if (AuthErrorHandler.isAuthError(e)) {
          _addAssistantMessage(
            "Your session has expired. Please sign in again to continue.",
            type: MessageType.error,
          );
          // Queue the segment for later (user will need to sign in)
          final updatedSegments = state.voiceSegments.map((s) {
            if (s.id == segment.id) {
              return s.copyWith(isUploaded: false);
            }
            return s;
          }).toList();
          state = state.copyWith(
            state: ConversationState.gathering,
            voiceSegments: updatedSegments,
          );
          return;
        }

        // Handle network errors - queue for offline processing
        if (errorMessage.contains('Network error') ||
            errorMessage.contains('connection')) {
          _addAssistantMessage(
            "Network error. Saved for later processing.",
            type: MessageType.text,
          );
          // Mark as queued for later
          final updatedSegments = state.voiceSegments.map((s) {
            if (s.id == segment.id) {
              return s.copyWith(isUploaded: false);
            }
            return s;
          }).toList();
          state = state.copyWith(
            state: ConversationState.gathering,
            voiceSegments: updatedSegments,
            isOffline: true,
          );
          _setupNetworkListener();
          return;
        }

        // Generic error
        _addAssistantMessage(
          "Sorry, I had trouble uploading your recording. Please try again.",
          type: MessageType.error,
        );
        state = state.copyWith(state: ConversationState.gathering);
        return;
      }
    } else if (segment.transcribedText != null &&
        segment.transcribedText!.isNotEmpty) {
      // Text-only segment (legacy)
      await _processTranscribedText(segment.transcribedText!, segment.id);
    }
  }

  /// Process transcribed text with backend
  Future<void> _processTranscribedText(
    String transcribedText,
    String segmentId,
  ) async {
    try {
      final response = await _service.parseVoiceInput(
        text: transcribedText,
        sessionId: state.sessionId,
        existingData: _convertToExistingData(state.expenseData),
        previousSegments: state.voiceSegments
            .where((s) => s.transcribedText != null)
            .map((s) => s.transcribedText!)
            .toList(),
      );

      // Merge extracted data with existing
      final mergedData = _mergeExtractedData(response);

      // Add assistant response
      _addAssistantMessage(
        response.chatResponse,
        type: response.isComplete ? MessageType.summary : MessageType.text,
      );

      // Update state
      state = state.copyWith(
        state: response.isComplete
            ? ConversationState.confirming
            : ConversationState.gathering,
        expenseData: mergedData,
        isOffline: false,
      );

      // Mark segment as processed
      final updatedSegments = state.voiceSegments.map((s) {
        if (s.id == segmentId) {
          return s.copyWith(isProcessed: true);
        }
        return s;
      }).toList();

      state = state.copyWith(voiceSegments: updatedSegments);
    } catch (e) {
      _addAssistantMessage(
        "Sorry, I had trouble understanding that. Could you say it again?",
        type: MessageType.error,
      );
      state = state.copyWith(state: ConversationState.gathering);
    }
  }

  /// Set up network connectivity listener to auto-resume uploads
  void _setupNetworkListener() {
    if (_networkSubscription != null) return; // Already listening

    final connectivity = Connectivity();
    _networkSubscription = connectivity.onConnectivityChanged.listen((results) {
      // Check if any connection type is available
      final hasConnection = results.any(
        (result) => result != ConnectivityResult.none,
      );
      if (hasConnection) {
        // Network is back - process queued segments
        _processQueuedSegments();
      }
    });
  }

  /// Process all queued (offline) segments when network returns
  Future<void> _processQueuedSegments() async {
    final queuedSegments = state.voiceSegments
        .where(
          (s) => s.audioFilePath.isNotEmpty && !s.isUploaded && !s.isProcessed,
        )
        .toList();

    if (queuedSegments.isEmpty) {
      _networkSubscription?.cancel();
      _networkSubscription = null;
      return;
    }

    // Show processing message
    _addAssistantMessage(
      "Processing your saved recordings...",
      type: MessageType.text,
    );

    // Process each queued segment
    for (final segment in queuedSegments) {
      await _processVoiceSegment(segment);
    }

    // Cancel listener if all processed
    if (state.voiceSegments.every((s) => s.isUploaded || s.isProcessed)) {
      _networkSubscription?.cancel();
      _networkSubscription = null;
    }
  }

  AccumulatedExpenseData _mergeExtractedData(VoiceParseResponse response) {
    return AccumulatedExpenseData(
      amount: _mergeEntity(state.expenseData.amount, response.amount),
      currency: _mergeEntity(state.expenseData.currency, response.currency),
      merchant: _mergeEntity(state.expenseData.merchant, response.merchant),
      date: _mergeEntity(state.expenseData.date, response.date),
      category: _mergeEntity(state.expenseData.category, response.category),
      description: _mergeEntity(
        state.expenseData.description,
        response.description,
      ),
    );
  }

  ExtractedEntity<T> _mergeEntity<T>(
    ExtractedEntity<T> existing,
    ExtractedEntity<T> newEntity,
  ) {
    // New value with higher confidence wins
    if (newEntity.value != null &&
        newEntity.confidence >= existing.confidence) {
      return newEntity;
    }
    return existing;
  }

  /// Handle save confirmation
  Future<bool> confirmAndSave() async {
    if (!state.expenseData.isComplete) return false;

    state = state.copyWith(state: ConversationState.processing);

    try {
      // Create expense via API
      final success = await _service.createExpense(
        amount: state.expenseData.amount.value!,
        currency: state.expenseData.currency.value ?? 'NGN',
        merchant: state.expenseData.merchant.value!,
        date: state.expenseData.date.value!,
        category: state.expenseData.category.value!,
        description: state.expenseData.description.value,
        entryMode: 'voice',
      );

      if (success) {
        _addAssistantMessage(
          "✅ Saved! Your expense has been recorded.",
          type: MessageType.success,
        );
        state = state.copyWith(
          state: ConversationState.saved,
          savedAt: DateTime.now(),
        );
        return true;
      }

      throw Exception('Failed to save');
    } catch (e) {
      _addAssistantMessage(
        "Sorry, I couldn't save that. Please try again.",
        type: MessageType.error,
      );
      state = state.copyWith(state: ConversationState.confirming);
      return false;
    }
  }

  /// Cancel the session
  void cancel() {
    _addAssistantMessage("No problem, I've cancelled this expense.");
    state = state.copyWith(state: ConversationState.cancelled);
  }

  void _addUserMessage(String content) {
    final message = ChatMessage(
      id: _uuid.v4(),
      isUser: true,
      content: content,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, message]);
  }

  void _addAssistantMessage(
    String content, {
    MessageType type = MessageType.text,
  }) {
    final message = ChatMessage(
      id: _uuid.v4(),
      isUser: false,
      content: content,
      timestamp: DateTime.now(),
      type: type,
    );
    state = state.copyWith(messages: [...state.messages, message]);
  }

  Map<String, dynamic>? _convertToExistingData(AccumulatedExpenseData data) {
    if (!data.amount.isPresent &&
        !data.merchant.isPresent &&
        !data.date.isPresent &&
        !data.category.isPresent) {
      return null;
    }

    return {
      if (data.amount.value != null) 'amount': data.amount.value,
      if (data.currency.value != null) 'currency': data.currency.value,
      if (data.merchant.value != null) 'merchant': data.merchant.value,
      if (data.date.value != null) 'date': data.date.value!.toIso8601String(),
      if (data.category.value != null) 'category': data.category.value,
      if (data.description.value != null) 'description': data.description.value,
    };
  }
}

/// Provider for the voice expense session
final voiceExpenseProvider =
    StateNotifierProvider<VoiceExpenseNotifier, VoiceExpenseSession>((ref) {
      final service = ref.watch(voiceConversationServiceProvider);
      return VoiceExpenseNotifier(service);
    });
