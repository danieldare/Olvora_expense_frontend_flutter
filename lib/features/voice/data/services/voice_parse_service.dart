import 'package:dio/dio.dart';
import '../../../../core/services/api_service_v2.dart';
import '../../../../core/services/expense_parsing/expense_parsing.dart';
import '../../../receipts/domain/models/parsed_receipt.dart';

/// Service for parsing voice input using backend AI parsing
///
/// Features:
/// - Sends voice text to backend for OpenAI processing
/// - Returns both ParsedReceipt (legacy) and ParsedExpenseResult (new)
/// - Handles timeout and error cases gracefully
class VoiceParseService {
  final ApiServiceV2 _apiService;

  VoiceParseService(this._apiService);

  /// Parse voice input text using backend OpenAI parsing
  ///
  /// Returns ParsedReceipt for backward compatibility with existing code.
  Future<ParsedReceipt> parseFromVoiceText(String text) async {
    try {
      // Split text into words and create simple blocks
      // Since voice input doesn't have spatial coordinates, we create
      // approximate positions based on word order
      final words = text.split(RegExp(r'\s+'));
      final blocks = words.asMap().entries.map((entry) {
        final index = entry.key;
        final word = entry.value;
        // Create approximate positions (left to right, top to bottom)
        return {
          'text': word,
          'x': (index % 20) * 50.0,
          'y': (index ~/ 20) * 20.0,
          'right': ((index % 20) * 50.0) + 50.0,
          'bottom': ((index ~/ 20) * 20.0) + 20.0,
        };
      }).toList();

      final response = await _apiService.dio.post(
        '/receipts/parse-raw',
        data: {'raw_text': text, 'blocks': blocks},
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

      return ParsedReceipt.fromJson(actualData as Map<String, dynamic>);
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          throw Exception('Request timed out. Please try again.');
        }
        throw Exception('Failed to parse voice input: ${e.message}');
      }
      rethrow;
    }
  }

  /// Parse voice input and return ParsedExpenseResult
  ///
  /// This is the preferred method for new code as it returns a unified result type.
  Future<ParsedExpenseResult> parseToExpenseResult(String text) async {
    try {
      // Use the dedicated text parsing endpoint
      final response = await _apiService.dio.post(
        '/expenses/parse-text',
        data: {
          'text': text,
          'source': 'voice',
          'options': {
            'extractDate': true,
            'extractMerchant': true,
            'extractCategory': true,
          },
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      // Handle response wrapper
      dynamic actualData = response.data;
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap.containsKey('data') && responseMap['data'] != null) {
          actualData = responseMap['data'];
        }
      }

      return _parseResponse(actualData as Map<String, dynamic>, text);
    } catch (e) {
      if (e is DioException) {
        // If the dedicated endpoint doesn't exist, fall back to receipt parsing
        if (e.response?.statusCode == 404) {
          return _fallbackToReceiptParsing(text);
        }
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          throw Exception('Request timed out. Please try again.');
        }
        throw Exception('Failed to parse voice input: ${e.message}');
      }
      rethrow;
    }
  }

  /// Fallback to receipt parsing endpoint and convert result
  Future<ParsedExpenseResult> _fallbackToReceiptParsing(String text) async {
    final receipt = await parseFromVoiceText(text);
    return _receiptToExpenseResult(receipt, text);
  }

  /// Convert ParsedReceipt to ParsedExpenseResult
  ParsedExpenseResult _receiptToExpenseResult(ParsedReceipt receipt, String rawText) {
    final extractedFields = <String>[];
    final missingFields = <String>[];

    if (receipt.totalAmount != null) {
      extractedFields.add('amount');
    } else {
      missingFields.add('amount');
    }

    if (receipt.merchant != null && receipt.merchant!.isNotEmpty) {
      extractedFields.add('merchant');
    } else {
      missingFields.add('merchant');
    }

    if (receipt.date != null) {
      extractedFields.add('date');
    }

    if (receipt.suggestedCategory != null && receipt.suggestedCategory!.isNotEmpty) {
      extractedFields.add('category');
    }

    // Calculate confidence based on extracted fields
    double confidence = 0.0;
    if (receipt.totalAmount != null) confidence += 0.4;
    if (receipt.merchant != null) confidence += 0.25;
    if (receipt.date != null) confidence += 0.15;
    if (receipt.suggestedCategory != null) confidence += 0.1;

    return ParsedExpenseResult(
      amount: receipt.totalAmount,
      currency: receipt.currency,
      merchant: receipt.merchant,
      category: receipt.suggestedCategory,
      date: receipt.date,
      description: receipt.description,
      rawText: rawText,
      confidence: confidence.clamp(0.0, 1.0),
      extractedFields: extractedFields,
      missingFields: missingFields,
      source: ParsingSource.voice,
      suggestedTitle: receipt.merchant ?? receipt.description,
      metadata: {
        'parsedViaReceipt': true,
        'lineItems': receipt.lineItems?.map((i) => i.toJson()).toList(),
      },
    );
  }

  /// Parse API response to ParsedExpenseResult
  ParsedExpenseResult _parseResponse(Map<String, dynamic> data, String rawText) {
    final extractedFields = <String>[];
    final missingFields = <String>[];

    // Extract amount
    double? amount;
    if (data['amount'] != null) {
      amount = (data['amount'] as num).toDouble();
      extractedFields.add('amount');
    } else {
      missingFields.add('amount');
    }

    // Extract currency
    String? currency = data['currency'] as String?;
    String? currencySymbol = data['currencySymbol'] as String?;

    // Extract merchant
    String? merchant = data['merchant'] as String?;
    if (merchant != null && merchant.isNotEmpty) {
      extractedFields.add('merchant');
    } else {
      missingFields.add('merchant');
    }

    // Extract category
    String? category = data['category'] as String?;
    if (category != null && category.isNotEmpty) {
      extractedFields.add('category');
    }

    // Extract date
    DateTime? date;
    if (data['date'] != null) {
      if (data['date'] is String) {
        date = DateTime.tryParse(data['date'] as String);
      } else if (data['date'] is int) {
        date = DateTime.fromMillisecondsSinceEpoch(data['date'] as int);
      }
      if (date != null) {
        extractedFields.add('date');
      }
    }

    // Extract description
    String? description = data['description'] as String?;

    // Get confidence from backend or calculate
    double confidence = 0.5;
    if (data['confidence'] != null) {
      confidence = (data['confidence'] as num).toDouble();
    } else {
      // Calculate based on extracted fields
      if (amount != null) confidence += 0.3;
      if (merchant != null) confidence += 0.2;
      if (date != null) confidence += 0.1;
      if (category != null) confidence += 0.1;
    }

    return ParsedExpenseResult(
      amount: amount,
      currency: currency,
      currencySymbol: currencySymbol,
      merchant: merchant,
      category: category,
      date: date,
      description: description,
      rawText: rawText,
      confidence: confidence.clamp(0.0, 1.0),
      extractedFields: extractedFields,
      missingFields: missingFields,
      source: ParsingSource.voice,
      suggestedTitle: merchant ?? description,
      metadata: {
        'parsedViaAPI': true,
        'originalResponse': data,
      },
    );
  }
}
