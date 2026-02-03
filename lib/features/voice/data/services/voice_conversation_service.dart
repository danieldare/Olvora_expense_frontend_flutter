import 'package:dio/dio.dart';
import '../../../../core/services/api_service_v2.dart';
import '../../../../core/utils/auth_error_handler.dart';
import '../../domain/models/voice_expense_session.dart';

/// Response from voice parse API
class VoiceParseResponse {
  final ExtractedEntity<double> amount;
  final ExtractedEntity<String> currency;
  final ExtractedEntity<String> merchant;
  final ExtractedEntity<DateTime> date;
  final ExtractedEntity<String> category;
  final ExtractedEntity<String> description;
  final String chatResponse;
  final String? suggestedNextPrompt;
  final bool isComplete;
  final List<String> missingFields;
  final List<String> ambiguousFields;
  final String detectedIntent;
  final double intentConfidence;

  VoiceParseResponse({
    required this.amount,
    required this.currency,
    required this.merchant,
    required this.date,
    required this.category,
    required this.description,
    required this.chatResponse,
    this.suggestedNextPrompt,
    required this.isComplete,
    required this.missingFields,
    required this.ambiguousFields,
    required this.detectedIntent,
    required this.intentConfidence,
  });

  factory VoiceParseResponse.fromJson(Map<String, dynamic> json) {
    return VoiceParseResponse(
      amount: ExtractedEntity<double>(
        value: json['amount']?['value'] != null
            ? (json['amount']['value'] is num
                  ? json['amount']['value'].toDouble()
                  : double.tryParse(json['amount']['value'].toString()))
            : null,
        confidence: (json['amount']?['confidence'] ?? 0.0).toDouble(),
        alternatives: json['amount']?['alternatives'] != null
            ? (json['amount']['alternatives'] as List)
                  .map(
                    (e) =>
                        e is num ? e.toDouble() : double.tryParse(e.toString()),
                  )
                  .whereType<double>()
                  .toList()
            : null,
      ),
      currency: ExtractedEntity<String>(
        value: json['currency']?['value']?.toString(),
        confidence: (json['currency']?['confidence'] ?? 0.0).toDouble(),
      ),
      merchant: ExtractedEntity<String>(
        value: json['merchant']?['value']?.toString(),
        confidence: (json['merchant']?['confidence'] ?? 0.0).toDouble(),
      ),
      date: ExtractedEntity<DateTime>(
        value: json['date']?['value'] != null
            ? DateTime.tryParse(json['date']['value'])
            : null,
        confidence: (json['date']?['confidence'] ?? 0.0).toDouble(),
      ),
      category: ExtractedEntity<String>(
        value: json['category']?['value']?.toString(),
        confidence: (json['category']?['confidence'] ?? 0.0).toDouble(),
      ),
      description: ExtractedEntity<String>(
        value: json['description']?['value']?.toString(),
        confidence: (json['description']?['confidence'] ?? 0.0).toDouble(),
      ),
      chatResponse: json['chatResponse'] ?? '',
      suggestedNextPrompt: json['suggestedNextPrompt']?.toString(),
      isComplete: json['isComplete'] ?? false,
      missingFields:
          (json['missingFields'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      ambiguousFields:
          (json['ambiguousFields'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      detectedIntent: json['detectedIntent'] ?? 'expense',
      intentConfidence: (json['intentConfidence'] ?? 0.8).toDouble(),
    );
  }
}

/// Service for voice conversation API calls
class VoiceConversationService {
  final ApiServiceV2 _apiService;

  VoiceConversationService(this._apiService);

  /// Parse voice input text and merge with existing data
  Future<VoiceParseResponse> parseVoiceInput({
    required String text,
    String? sessionId,
    Map<String, dynamic>? existingData,
    List<String>? previousSegments,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/voice/conversation/parse',
        data: {
          'text': text,
          if (sessionId != null) 'sessionId': sessionId,
          if (existingData != null) 'existingData': existingData,
          if (previousSegments != null) 'previousSegments': previousSegments,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      // Handle TransformInterceptor response wrapper
      dynamic actualData = response.data;
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap.containsKey('data') && responseMap['data'] != null) {
          actualData = responseMap['data'];
        }
      }

      return VoiceParseResponse.fromJson(actualData as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Request timed out. Please try again.');
      }
      throw Exception('Failed to parse voice input: ${e.message}');
    } catch (e) {
      throw Exception('Failed to parse voice input: $e');
    }
  }

  /// Upload audio file and get transcription (World-Class STT)
  Future<String> uploadAudioAndTranscribe({
    required String audioFilePath,
    required String sessionId,
  }) async {
    try {
      final file = await MultipartFile.fromFile(
        audioFilePath,
        filename: audioFilePath.split('/').last,
      );

      final formData = FormData.fromMap({
        'audio': file,
        'sessionId': sessionId,
      });

      final response = await _apiService.dio.post(
        '/voice/conversation/upload-audio',
        data: formData,
        options: Options(
          receiveTimeout: const Duration(
            seconds: 60,
          ), // Longer timeout for audio processing
          sendTimeout: const Duration(seconds: 60),
          // Don't set Content-Type manually - Dio handles it automatically with boundary
        ),
      );

      // Handle TransformInterceptor response wrapper
      dynamic actualData = response.data;
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap.containsKey('data') && responseMap['data'] != null) {
          actualData = responseMap['data'];
        }
      }

      final transcription = actualData['transcription'] as String?;
      if (transcription == null || transcription.isEmpty) {
        throw Exception('No transcription received from server');
      }

      return transcription;
    } on DioException catch (e) {
      // Handle authentication errors using centralized handler
      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(
          'Your session has expired. Please sign in again to continue.',
        );
      }

      // Handle timeout errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Audio upload timed out. Please try again.');
      }

      // Handle network errors
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception(
          'Network error. Please check your connection and try again.',
        );
      }

      // Generic error
      throw Exception('Failed to upload and transcribe audio: ${e.message}');
    } catch (e) {
      // Re-throw if already a formatted exception
      if (e is Exception && e.toString().contains('session has expired')) {
        rethrow;
      }
      throw Exception('Failed to upload and transcribe audio: $e');
    }
  }

  /// Create expense from accumulated data
  Future<bool> createExpense({
    required double amount,
    required String currency,
    required String merchant,
    required DateTime date,
    required String category,
    String? description,
    String entryMode = 'voice',
  }) async {
    try {
      // Map category name to enum value
      final categoryEnum = _mapCategoryToEnum(category);

      final response = await _apiService.dio.post(
        '/expenses',
        data: {
          'title': merchant,
          'description': description,
          'merchant': merchant,
          'amount': amount,
          'category': categoryEnum,
          'date': date.toIso8601String(),
          'entryMode': entryMode,
        },
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  String _mapCategoryToEnum(String categoryName) {
    // Map category names to enum values
    final categoryMap = {
      'Food & Dining': 'food',
      'Transportation': 'transport',
      'Shopping': 'shopping',
      'Bills & Utilities': 'bills',
      'Entertainment': 'entertainment',
      'Education': 'education',
      'Healthcare': 'health',
      'Hospital Bill': 'health',
      'Rent': 'bills',
      'Internet & Phone': 'bills',
      'Insurance': 'bills',
      'Personal Care': 'other',
      'Gifts & Donations': 'other',
      'Travel': 'transport',
      'Debit': 'debit',
    };

    return categoryMap[categoryName] ?? 'other';
  }
}
