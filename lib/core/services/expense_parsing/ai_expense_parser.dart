import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'parsed_expense_result.dart';
import '../api_service_v2.dart';

/// AI-powered expense parser that uses backend OpenAI integration
///
/// This parser sends text to the backend for intelligent parsing using
/// OpenAI's language models. It's more accurate than generic pattern
/// matching but requires network connectivity.
class AIExpenseParser {
  final ApiServiceV2 _apiService;

  AIExpenseParser(this._apiService);

  /// Parse text using backend OpenAI integration
  ///
  /// Sends the text to the backend `/expenses/parse-text` endpoint
  /// which uses OpenAI to intelligently extract expense information.
  Future<ParsedExpenseResult> parse(String text, ParsingSource source) async {
    if (text.trim().isEmpty) {
      return ParsedExpenseResult(
        rawText: text,
        confidence: 0.0,
        source: source,
      );
    }

    try {
      if (kDebugMode) {
        debugPrint('🤖 AIParser: Sending text to backend for parsing...');
      }

      final response = await _apiService.dio.post(
        '/expenses/parse-text',
        data: {
          'text': text,
          'source': source.name,
          'extract_fields': [
            'amount',
            'currency',
            'merchant',
            'date',
            'category',
            'description',
          ],
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 15),
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

      if (actualData is! Map<String, dynamic>) {
        throw Exception('Invalid response format from AI parser');
      }

      final result = _parseResponse(actualData, text, source);

      if (kDebugMode) {
        debugPrint('🤖 AIParser result:');
        debugPrint('   Amount: ${result.amount} ${result.currency ?? ""}');
        debugPrint('   Merchant: ${result.merchant ?? "not found"}');
        debugPrint('   Confidence: ${(result.confidence * 100).round()}%');
      }

      return result;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('🤖 AIParser error: ${e.message}');
      }

      // Return empty result on network/API error
      return ParsedExpenseResult(
        rawText: text,
        confidence: 0.0,
        source: source,
        metadata: {'error': e.message, 'errorType': 'network'},
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🤖 AIParser error: $e');
      }

      return ParsedExpenseResult(
        rawText: text,
        confidence: 0.0,
        source: source,
        metadata: {'error': e.toString(), 'errorType': 'parse'},
      );
    }
  }

  /// Parse response from backend
  ParsedExpenseResult _parseResponse(
    Map<String, dynamic> data,
    String rawText,
    ParsingSource source,
  ) {
    // Parse amount
    double? amount;
    if (data['amount'] != null) {
      if (data['amount'] is num) {
        amount = (data['amount'] as num).toDouble();
      } else if (data['amount'] is String) {
        amount = double.tryParse(data['amount'] as String);
      }
    }

    // Parse date
    DateTime? date;
    if (data['date'] != null) {
      if (data['date'] is String) {
        date = DateTime.tryParse(data['date'] as String);
      }
    }

    // Parse confidence
    double confidence = 0.0;
    if (data['confidence'] != null) {
      if (data['confidence'] is num) {
        confidence = (data['confidence'] as num).toDouble();
      }
    }

    // Parse balance
    double? balance;
    if (data['balance'] != null) {
      if (data['balance'] is num) {
        balance = (data['balance'] as num).toDouble();
      }
    }

    return ParsedExpenseResult(
      amount: amount,
      currency: data['currency'] as String?,
      currencySymbol: data['currencySymbol'] as String?,
      merchant: data['merchant'] as String?,
      category: data['category'] as String?,
      date: date,
      description: data['description'] as String?,
      accountIdentifier: data['accountIdentifier'] as String?,
      balance: balance,
      transactionType: data['transactionType'] as String?,
      rawText: rawText,
      confidence: confidence,
      source: source,
      suggestedTitle: data['suggestedTitle'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Check if the parser is available (has valid API connection)
  Future<bool> isAvailable() async {
    try {
      // Simple health check
      await _apiService.dio.get(
        '/health',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
