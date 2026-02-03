import 'dart:io';
import '../../domain/models/parsed_receipt.dart';
import 'mlkit_ocr_service.dart';
import 'receipt_parse_service.dart';
import '../../../../core/services/api_service_v2.dart';
import '../../../../core/utils/app_logger.dart';

enum ScanMethod {
  clientSide, // ML Kit OCR
  serverSide, // Backend OCR
}

class ReceiptScanResult {
  final ParsedReceipt? receipt;
  final ScanMethod? method;
  final String? error;

  ReceiptScanResult({this.receipt, this.method, this.error});

  bool get hasError => error != null;
  bool get hasReceipt => receipt != null && error == null;
}

class ReceiptScanService {
  MLKitOCRService? _mlKitOCR;
  final ReceiptParseService _parseService;
  bool _isDisposed = false;

  /// Get the parse service (for sensor-style flow)
  ReceiptParseService get parseService => _parseService;

  ReceiptScanService(ApiServiceV2 apiService)
    : _parseService = ReceiptParseService(apiService);

  /// Lazy initialization of ML Kit OCR service
  /// Only creates it when actually needed to avoid early native initialization
  MLKitOCRService? getMLKitOCR() {
    if (_isDisposed) {
      return null;
    }

    if (_mlKitOCR == null) {
      try {
        _mlKitOCR = MLKitOCRService();
      } catch (e) {
        AppLogger.e(
          'Failed to initialize ML Kit OCR',
          tag: 'ReceiptScan',
          error: e,
        );
        _mlKitOCR = null;
        return null;
      }
    }
    return _mlKitOCR;
  }

  /// Hybrid scan: Try client-side first, fallback to server-side
  Future<ReceiptScanResult> scanReceipt(File imageFile) async {
    bool clientSideAttempted = false;

    // Step 1: Try client-side OCR (only if ML Kit is available)
    if (!_isDisposed) {
      try {
        final mlKitOCR = getMLKitOCR();
        if (mlKitOCR != null) {
          clientSideAttempted = true;
          AppLogger.d(
            'Attempting client-side OCR (ML Kit)...',
            tag: 'ReceiptScan',
          );

          final extractedText = await mlKitOCR.extractText(imageFile);

          if (extractedText != null &&
              mlKitOCR.isTextQualityGood(extractedText)) {
            // Client-side OCR succeeded and quality is good
            try {
              AppLogger.d(
                'Client-side OCR succeeded, parsing text...',
                tag: 'ReceiptScan',
              );
              final parsedReceipt = await _parseService.parseFromText(
                extractedText,
              );
              AppLogger.i(
                'SUCCESS: Client-side only (ML Kit OCR + text parsing)',
                tag: 'ReceiptScan',
              );
              return ReceiptScanResult(
                receipt: parsedReceipt,
                method: ScanMethod.clientSide,
              );
            } catch (e) {
              // Parsing failed, fallback to server-side
              AppLogger.w(
                'Client-side parsing failed, falling back to server',
                tag: 'ReceiptScan',
              );
            }
          } else {
            // Quality not good enough, use server-side
            AppLogger.w(
              'Client-side OCR quality insufficient, using server-side',
              tag: 'ReceiptScan',
            );
          }
        } else {
          AppLogger.d(
            'ML Kit OCR not available, skipping client-side',
            tag: 'ReceiptScan',
          );
        }
      } catch (e) {
        // Client-side OCR failed or not available, fallback to server-side
        AppLogger.w(
          'Client-side OCR failed, falling back to server',
          tag: 'ReceiptScan',
        );
      }
    }

    // Step 2: Fallback to server-side OCR
    AppLogger.d('Attempting server-side OCR (backend)...', tag: 'ReceiptScan');
    try {
      final parsedReceipt = await _parseService.parseFromImage(imageFile);

      if (clientSideAttempted) {
        AppLogger.i(
          'SUCCESS: Hybrid (client-side attempted, server-side succeeded)',
          tag: 'ReceiptScan',
        );
      } else {
        AppLogger.i(
          'SUCCESS: Server-side only (backend OCR)',
          tag: 'ReceiptScan',
        );
      }

      return ReceiptScanResult(
        receipt: parsedReceipt,
        method: ScanMethod.serverSide,
      );
    } catch (e) {
      if (clientSideAttempted) {
        AppLogger.e(
          'FAILED: Both client-side and server-side failed',
          tag: 'ReceiptScan',
          error: e,
        );
      } else {
        AppLogger.e('FAILED: Server-side failed', tag: 'ReceiptScan', error: e);
      }
      return ReceiptScanResult(
        error: 'Failed to scan receipt: ${e.toString()}',
      );
    }
  }

  /// Force server-side scanning (for manual retry)
  Future<ReceiptScanResult> scanReceiptServerSide(File imageFile) async {
    AppLogger.d('Force server-side scan requested...', tag: 'ReceiptScan');
    try {
      if (!await imageFile.exists()) {
        AppLogger.w('Image file does not exist', tag: 'ReceiptScan');
        return ReceiptScanResult(error: 'Image file does not exist');
      }

      final parsedReceipt = await _parseService.parseFromImage(imageFile);
      AppLogger.i('SUCCESS: Server-side only (forced)', tag: 'ReceiptScan');
      return ReceiptScanResult(
        receipt: parsedReceipt,
        method: ScanMethod.serverSide,
      );
    } catch (e) {
      AppLogger.e(
        'FAILED: Server-side scan error',
        tag: 'ReceiptScan',
        error: e,
      );
      return ReceiptScanResult(
        error: 'Failed to scan receipt: ${e.toString()}',
      );
    }
  }

  void dispose() {
    if (!_isDisposed) {
      try {
        _mlKitOCR?.dispose();
        _mlKitOCR = null;
        _isDisposed = true;
      } catch (e) {
        AppLogger.e(
          'Error disposing ReceiptScanService',
          tag: 'ReceiptScan',
          error: e,
        );
      }
    }
  }
}
