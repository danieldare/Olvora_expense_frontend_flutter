import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/services/api_service_v2.dart';
import '../../domain/models/parsed_receipt.dart';
import '../../domain/models/raw_receipt_data.dart';

class ReceiptParseService {
  final ApiServiceV2 _apiService;

  ReceiptParseService(this._apiService);

  /// Parse receipt from OCR text (client-side OCR)
  Future<ParsedReceipt> parseFromText(String rawText) async {
    try {
      final response = await _apiService.dio.post(
        '/receipts/parse-text',
        data: {'rawText': rawText},
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
        throw Exception('Failed to parse receipt: ${e.message}');
      }
      rethrow;
    }
  }

  /// Parse receipt from image file (server-side OCR)
  Future<ParsedReceipt> parseFromImage(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _apiService.dio.post(
        '/receipts/parse',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
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
        throw Exception('Failed to parse receipt: ${e.message}');
      }
      rethrow;
    }
  }

  /// Parse receipt from raw data with bounding boxes (sensor-style)
  /// Sends raw text and coordinates to backend for parsing
  Future<ParsedReceipt> parseFromRawData(RawReceiptData rawData) async {
    try {
      final response = await _apiService.dio.post(
        '/receipts/parse-raw',
        data: rawData.toJson(),
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
        throw Exception('Failed to parse receipt: ${e.message}');
      }
      rethrow;
    }
  }
}
