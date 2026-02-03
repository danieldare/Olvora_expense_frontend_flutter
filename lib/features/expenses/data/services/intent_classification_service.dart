import 'package:dio/dio.dart';
import '../../../../core/services/api_service_v2.dart';

enum ExpenseIntentType {
  expense,
  recurring,
  future,
}

class IntentClassificationResult {
  final ExpenseIntentType intentType;
  final double confidence;
  final Map<String, dynamic> extractedData;
  final String reasoning;

  IntentClassificationResult({
    required this.intentType,
    required this.confidence,
    required this.extractedData,
    required this.reasoning,
  });

  factory IntentClassificationResult.fromJson(Map<String, dynamic> json) {
    return IntentClassificationResult(
      intentType: ExpenseIntentType.values.firstWhere(
        (e) => e.name == json['intentType'],
        orElse: () => ExpenseIntentType.expense,
      ),
      confidence: (json['confidence'] as num).toDouble(),
      extractedData: json['extractedData'] as Map<String, dynamic>,
      reasoning: json['reasoning'] as String,
    );
  }
}

class IntentClassificationService {
  final ApiServiceV2 _apiService;

  IntentClassificationService(this._apiService);

  /// Classify intent from text input (voice or receipt)
  Future<IntentClassificationResult> classifyIntent(
    String text,
    String source, // 'voice' or 'receipt'
  ) async {
    try {
      final response = await _apiService.dio.post(
        '/intent-classification/classify',
        data: {
          'text': text,
          'source': source,
        },
      );

      // Handle TransformInterceptor response wrapper
      dynamic actualData = response.data;
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap.containsKey('data') && responseMap['data'] != null) {
          actualData = responseMap['data'];
        }
      }

      return IntentClassificationResult.fromJson(
        actualData as Map<String, dynamic>,
      );
    } catch (e) {
      if (e is DioException) {
        throw Exception('Failed to classify intent: ${e.message}');
      }
      rethrow;
    }
  }
}

