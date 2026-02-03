import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import '../../domain/models/ora_message.dart';
import '../../domain/models/ora_conversation_state.dart';
import '../../../../core/services/api_service_v2.dart';

/// Repository interface for Ora operations
abstract class OraRepository {
  /// Send a text message to Ora
  Future<OraResponse> sendMessage({
    required String text,
    String? conversationId,
    Map<String, dynamic>? context,
    bool stream = false,
    Function(String chunk, String accumulated)? onChunk,
  });

  /// Send a voice message to Ora
  Future<OraResponse> sendVoice({
    required File audioFile,
    String? conversationId,
    String? languageHint,
  });

  /// Send an image (receipt) to Ora
  Future<OraResponse> sendImage({
    required File imageFile,
    String? conversationId,
    String? caption,
    String? ocrText,
  });

  /// Execute an action (confirm, edit, undo, cancel)
  Future<OraResponse> executeAction({
    required String conversationId,
    required String messageId,
    required String actionId,
    required OraActionType actionType,
    Map<String, dynamic>? payload,
  });

  /// Get conversation history
  Future<OraHistoryResponse> getHistory({
    required String conversationId,
    int? limit,
    int? offset,
  });

  /// Start a new conversation
  Future<String> startNewConversation();

  /// Get the most recent conversation ID
  Future<String?> getMostRecentConversationId();

  /// Get list of conversations
  Future<OraConversationsResponse> getConversations({
    int? limit,
    int? offset,
  });
}

/// Response from Ora API
class OraResponse {
  final String conversationId;
  final OraMessage message;
  final PendingConfirmation? pendingConfirmation;
  final String? transcription; // For voice messages

  OraResponse({
    required this.conversationId,
    required this.message,
    this.pendingConfirmation,
    this.transcription,
  });
}

/// History response
class OraHistoryResponse {
  final List<OraMessage> messages;
  final int total;

  OraHistoryResponse({required this.messages, required this.total});
}

/// Conversations list response
class OraConversationsResponse {
  final List<OraConversationSummary> conversations;
  final int total;

  OraConversationsResponse({
    required this.conversations,
    required this.total,
  });
}

/// Conversation summary
class OraConversationSummary {
  final String id;
  final int messageCount;
  final DateTime lastMessageAt;
  final DateTime createdAt;

  OraConversationSummary({
    required this.id,
    required this.messageCount,
    required this.lastMessageAt,
    required this.createdAt,
  });
}

/// Implementation of OraRepository
class OraRepositoryImpl implements OraRepository {
  final ApiServiceV2 _apiService;

  OraRepositoryImpl(this._apiService);

  /// Unwrap response from TransformInterceptor
  /// The backend wraps all responses in { data: T, statusCode: number }
  /// This method extracts the actual data or returns the original if not wrapped
  dynamic _unwrapResponse(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('data') && responseData['data'] != null) {
        return responseData['data'];
      }
    }
    return responseData;
  }

  @override
  Future<OraResponse> sendMessage({
    required String text,
    String? conversationId,
    Map<String, dynamic>? context,
    bool stream = false,
    Function(String chunk, String accumulated)? onChunk,
  }) async {
    if (stream) {
      return _sendMessageStream(
        text: text,
        conversationId: conversationId,
        context: context,
        onChunk: onChunk,
      );
    }

    final response = await _apiService.dio.post(
      '/ora/message',
      data: {
        'text': text,
        if (conversationId != null) 'conversationId': conversationId,
        if (context != null) 'context': context,
        'stream': false,
      },
    );

    final responseData = _unwrapResponse(response.data) as Map<String, dynamic>;
    return _parseResponse(responseData);
  }

  Future<OraResponse> _sendMessageStream({
    required String text,
    String? conversationId,
    Map<String, dynamic>? context,
    Function(String chunk, String accumulated)? onChunk,
  }) async {
    // Create a request with streaming
    final response = await _apiService.dio.post(
      '/ora/message',
      data: {
        'text': text,
        if (conversationId != null) 'conversationId': conversationId,
        if (context != null) 'context': context,
        'stream': true,
      },
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
      ),
    );

    String conversationIdResult = '';
    String messageId = '';
    String accumulatedText = '';
    OraMessage? finalMessage;
    PendingConfirmation? pendingConfirmation;

    // Parse SSE stream
    // response.data is a ResponseBody when ResponseType.stream is used
    final responseBody = response.data as ResponseBody;
    final stream = responseBody.stream;
    String buffer = '';

    // Decode UTF-8 stream properly handling multi-byte characters
    // Decode each chunk manually
    await for (final bytes in stream) {
      // Convert bytes to string chunk by chunk
      final chunk = utf8.decode(bytes);
      buffer += chunk;
      final lines = buffer.split('\n');
      buffer = lines.removeLast(); // Keep incomplete line in buffer

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        if (line.startsWith('data: ')) {
          try {
            final jsonStr = line.substring(6).trim(); // Remove 'data: ' prefix
            if (jsonStr.isEmpty) continue;

            final data = json.decode(jsonStr) as Map<String, dynamic>;

            switch (data['type'] as String) {
              case 'start':
                conversationIdResult = data['conversationId'] as String? ?? '';
                messageId = data['messageId'] as String? ?? '';
                break;

              case 'chunk':
                final chunkText = data['text'] as String? ?? '';
                accumulatedText =
                    data['accumulated'] as String? ??
                    accumulatedText + chunkText;
                onChunk?.call(chunkText, accumulatedText);
                break;

              case 'complete':
                if (data['message'] != null) {
                  final messageData = data['message'] as Map<String, dynamic>;
                  finalMessage = _parseMessage(messageData);
                }
                if (data['pendingConfirmation'] != null) {
                  pendingConfirmation = _parsePendingConfirmation(
                    data['pendingConfirmation'] as Map<String, dynamic>,
                  );
                }
                break;

              case 'error':
                throw Exception(
                  data['message'] as String? ?? 'Streaming error',
                );
            }
          } catch (e) {
            // Skip invalid JSON lines
            continue;
          }
        }
      }
    }

    finalMessage ??= AssistantMessage(
        id: messageId.isNotEmpty
            ? messageId
            : DateTime.now().millisecondsSinceEpoch.toString(),
        text: accumulatedText,
        timestamp: DateTime.now(),
      );

    return OraResponse(
      conversationId: conversationIdResult,
      message: finalMessage,
      pendingConfirmation: pendingConfirmation,
    );
  }

  @override
  Future<OraResponse> sendVoice({
    required File audioFile,
    String? conversationId,
    String? languageHint,
  }) async {
    // Determine content type based on file extension
    final extension = audioFile.path.split('.').last.toLowerCase();
    String contentType;
    switch (extension) {
      case 'm4a':
        contentType = 'audio/mp4';
        break;
      case 'aac':
        contentType = 'audio/aac';
        break;
      case 'mp3':
        contentType = 'audio/mpeg';
        break;
      case 'wav':
        contentType = 'audio/wav';
        break;
      case 'ogg':
        contentType = 'audio/ogg';
        break;
      case 'webm':
        contentType = 'audio/webm';
        break;
      default:
        contentType = 'audio/mp4'; // Default for m4a/aac
    }

    final formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(
        audioFile.path,
        contentType: DioMediaType.parse(contentType),
      ),
      if (conversationId != null) 'conversationId': conversationId,
      if (languageHint != null) 'languageHint': languageHint,
    });

    final response = await _apiService.dio.post('/ora/voice', data: formData);

    final responseData = _unwrapResponse(response.data) as Map<String, dynamic>;
    return _parseResponse(responseData);
  }

  @override
  Future<OraResponse> sendImage({
    required File imageFile,
    String? conversationId,
    String? caption,
    String? ocrText,
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path),
      if (conversationId != null) 'conversationId': conversationId,
      if (caption != null) 'caption': caption,
      if (ocrText != null && ocrText.isNotEmpty) 'ocrText': ocrText,
    });

    final response = await _apiService.dio.post('/ora/image', data: formData);

    final responseData = _unwrapResponse(response.data) as Map<String, dynamic>;
    return _parseResponse(responseData);
  }

  @override
  Future<OraResponse> executeAction({
    required String conversationId,
    required String messageId,
    required String actionId,
    required OraActionType actionType,
    Map<String, dynamic>? payload,
  }) async {
    // Map Flutter camelCase enum names to backend snake_case
    final actionTypeToBackend = {
      'confirm': 'confirm',
      'confirmAll': 'confirm_all',
      'edit': 'edit',
      'editIndividual': 'edit_individual',
      'undo': 'undo',
      'cancel': 'cancel',
      'viewDetails': 'view_details',
      'retry': 'retry',
    };

    final backendActionType =
        actionTypeToBackend[actionType.name] ?? actionType.name;

    final response = await _apiService.dio.post(
      '/ora/action',
      data: {
        'conversationId': conversationId,
        'messageId': messageId,
        'actionId': actionId,
        'actionType': backendActionType,
        if (payload != null) 'payload': payload,
      },
    );

    final responseData = _unwrapResponse(response.data) as Map<String, dynamic>;
    return _parseResponse(responseData);
  }

  @override
  Future<OraHistoryResponse> getHistory({
    required String conversationId,
    int? limit,
    int? offset,
  }) async {
    final response = await _apiService.dio.get(
      '/ora/history/$conversationId',
      queryParameters: {
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      },
    );

    final responseData = _unwrapResponse(response.data) as Map<String, dynamic>;
    final messages = (responseData['messages'] as List)
        .map((m) => _parseMessage(m as Map<String, dynamic>))
        .toList();

    return OraHistoryResponse(
      messages: messages,
      total: responseData['total'] as int? ?? messages.length,
    );
  }

  @override
  Future<String> startNewConversation() async {
    final response = await _apiService.dio.post('/ora/new');
    final responseData = _unwrapResponse(response.data) as Map<String, dynamic>;
    final conversationId = responseData['conversationId'];
    if (conversationId == null || conversationId is! String) {
      throw Exception(
        'Invalid response: conversationId is missing or not a string. '
        'Response: ${response.data}',
      );
    }
    return conversationId;
  }

  @override
  Future<String?> getMostRecentConversationId() async {
    try {
      final response = await _apiService.dio.get('/ora/conversations/recent');
      final responseData = _unwrapResponse(response.data) as Map<String, dynamic>;
      return responseData['conversationId'] as String?;
    } catch (e) {
      // If no conversation exists, return null
      return null;
    }
  }

  @override
  Future<OraConversationsResponse> getConversations({
    int? limit,
    int? offset,
  }) async {
    final queryParams = <String, dynamic>{};
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;

    final response = await _apiService.dio.get(
      '/ora/conversations',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final responseData = _unwrapResponse(response.data) as Map<String, dynamic>;

    final conversationsList = (responseData['conversations'] as List<dynamic>?)
            ?.map((c) {
              final conv = c as Map<String, dynamic>;
              return OraConversationSummary(
                id: conv['id'] as String,
                messageCount: conv['messageCount'] as int,
                lastMessageAt: DateTime.parse(conv['lastMessageAt'] as String),
                createdAt: DateTime.parse(conv['createdAt'] as String),
              );
            })
            .toList() ??
        [];

    return OraConversationsResponse(
      conversations: conversationsList,
      total: responseData['total'] as int? ?? conversationsList.length,
    );
  }

  OraResponse _parseResponse(Map<String, dynamic> data) {
    final conversationId = data['conversationId'];
    if (conversationId == null || conversationId is! String) {
      throw Exception(
        'Invalid response: conversationId is missing or not a string',
      );
    }
    return OraResponse(
      conversationId: conversationId,
      message: _parseMessage(data['message']),
      pendingConfirmation: data['pendingConfirmation'] != null
          ? _parsePendingConfirmation(data['pendingConfirmation'])
          : null,
      transcription: data['transcription'] as String?, // Extract transcription for voice messages
    );
  }

  OraMessage _parseMessage(Map<String, dynamic> data) {
    final role = data['role'] as String? ?? '';
    final id = data['id'] as String? ?? '';
    final text = data['text'] as String? ?? '';
    final timestampStr = data['timestamp'] as String?;
    if (timestampStr == null) {
      throw Exception('Invalid message: timestamp is missing');
    }
    final timestamp = DateTime.parse(timestampStr);

    if (role == 'user') {
      return UserMessage(
        id: id,
        text: text,
        attachments: data['attachments'] != null
            ? (data['attachments'] as List)
                  .map((a) => _parseAttachment(a))
                  .toList()
            : null,
        metadata: data['metadata'] as Map<String, dynamic>?,
        timestamp: timestamp,
      );
    } else if (role == 'assistant') {
      return AssistantMessage(
        id: id,
        text: text,
        structuredContent: data['structuredContent'] != null
            ? _parseStructuredContent(data['structuredContent'])
            : null,
        actions: data['actions'] != null
            ? (data['actions'] as List)
                  .map((a) => _parseActionButton(a))
                  .toList()
            : null,
        timestamp: timestamp,
        isStreaming: data['isStreaming'] ?? false,
      );
    } else {
      return SystemMessage(
        id: id,
        text: text,
        type: OraSystemMessageType.info,
        timestamp: timestamp,
      );
    }
  }

  OraAttachment _parseAttachment(Map<String, dynamic> data) {
    return OraAttachment(
      type: AttachmentType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => AttachmentType.image,
      ),
      url: data['url'] as String?,
      localPath: data['localPath'] as String?,
      mimeType: data['mimeType'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  OraStructuredContent _parseStructuredContent(Map<String, dynamic> data) {
    // Convert snake_case to camelCase for enum matching
    String typeStr = data['type'] as String? ?? 'error';

    // Map snake_case backend types to camelCase Flutter enum names
    const typeMapping = {
      'receipt_summary': 'receiptSummary',
      'expense_created': 'expenseCreated',
      'expenses_pending': 'expensesPending',
      'expense_list': 'expenseList',
      'budget_status': 'budgetStatus',
      'spending_summary': 'spendingSummary',
      'trip_created': 'tripCreated',
      'confirmation_required': 'confirmationRequired',
      'capabilities': 'capabilities',
      'expense_preview':
          'expensesPending', // Map preview to pending for confirmation flow
    };

    typeStr = typeMapping[typeStr] ?? typeStr;

    return OraStructuredContent(
      type: StructuredContentType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => StructuredContentType.error,
      ),
      data: data['data'] as Map<String, dynamic>,
    );
  }

  OraActionButton _parseActionButton(Map<String, dynamic> data) {
    // Map backend snake_case action types to Flutter camelCase enum names
    final actionTypeMapping = {
      'confirm': 'confirm',
      'confirm_all': 'confirmAll',
      'edit': 'edit',
      'edit_individual': 'editIndividual',
      'undo': 'undo',
      'cancel': 'cancel',
      'view_details': 'viewDetails',
      'retry': 'retry',
    };

    final backendType = data['actionType'] as String?;
    final mappedType = actionTypeMapping[backendType] ?? backendType;

    return OraActionButton(
      id: data['id'] as String,
      label: data['label'] as String,
      actionType: OraActionType.values.firstWhere(
        (e) => e.name == mappedType,
        orElse: () => OraActionType.confirm,
      ),
      payload: data['payload'] as Map<String, dynamic>?,
      isPrimary: data['isPrimary'] ?? false,
    );
  }

  PendingConfirmation _parsePendingConfirmation(Map<String, dynamic> data) {
    return PendingConfirmation(
      expenses: data['expenses'] != null
          ? (data['expenses'] as List).cast<Map<String, dynamic>>()
          : null,
      actions: (data['actions'] as List).cast<String>(),
    );
  }
}
