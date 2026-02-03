import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/models/raw_receipt_data.dart';

/// ML Kit OCR Service for text recognition from images.
/// 
/// **Optimization Note:**
/// This service uses lazy initialization - the native TextRecognizer
/// is only created when first needed, not at app startup.
/// 
/// **Future Enhancement - Deferred Loading:**
/// For further size reduction, ML Kit could be moved to a dynamic
/// feature module (Android Play Feature Delivery / iOS On-Demand Resources).
/// This would reduce initial download by ~8-12 MB.
/// 
/// See: https://docs.flutter.dev/perf/deferred-components
class MLKitOCRService {
  TextRecognizer? _textRecognizer;
  bool _isDisposed = false;
  bool _isInitialized = false;

  MLKitOCRService();

  /// Lazy initialization of TextRecognizer
  /// Only loads native ML Kit when actually needed
  Future<bool> _ensureInitialized() async {
    if (_isDisposed) return false;
    if (_isInitialized) return _textRecognizer != null;
    
    try {
      AppLogger.d('Initializing ML Kit TextRecognizer...', tag: 'OCR');
      _textRecognizer = TextRecognizer();
      _isInitialized = true;
      AppLogger.d('ML Kit TextRecognizer initialized successfully', tag: 'OCR');
      return true;
    } catch (e) {
      AppLogger.e('Failed to initialize TextRecognizer', tag: 'OCR', error: e);
      _textRecognizer = null;
      _isInitialized = true; // Mark as attempted
      return false;
    }
  }

  /// Extract text from image using Google ML Kit
  /// Returns the extracted text or null if failed
  Future<String?> extractText(File imageFile) async {
    // Lazy initialize on first use
    if (!await _ensureInitialized()) {
      AppLogger.w('OCR not available - TextRecognizer failed to initialize', tag: 'OCR');
      return null;
    }

    try {
      if (!await imageFile.exists()) {
        AppLogger.w('Image file does not exist: ${imageFile.path}', tag: 'OCR');
        return null;
      }

      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer!.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        AppLogger.d('OCR returned empty text', tag: 'OCR');
        return null;
      }

      AppLogger.d('OCR extracted ${recognizedText.text.length} characters', tag: 'OCR');
      return recognizedText.text;
    } catch (e) {
      AppLogger.e('ML Kit OCR Error', tag: 'OCR', error: e);
      return null;
    }
  }

  /// Extract raw text with bounding boxes from image using Google ML Kit
  /// Returns RawReceiptData containing full text and text blocks with coordinates
  Future<RawReceiptData?> extractRawTextWithBoundingBoxes(
    File imageFile,
  ) async {
    // Lazy initialize on first use
    if (!await _ensureInitialized()) {
      AppLogger.w('OCR not available - TextRecognizer failed to initialize', tag: 'OCR');
      return null;
    }

    try {
      if (!await imageFile.exists()) {
        AppLogger.w('Image file does not exist: ${imageFile.path}', tag: 'OCR');
        return null;
      }

      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer!.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        AppLogger.d('OCR returned empty text', tag: 'OCR');
        return null;
      }

      // Extract text blocks with bounding boxes
      final blocks = <RawTextBlock>[];

      // Process each block
      for (final block in recognizedText.blocks) {
        // Process each line in the block
        for (final line in block.lines) {
          // Process each element in the line
          for (final element in line.elements) {
            final boundingBox = element.boundingBox;
            blocks.add(
              RawTextBlock(
                text: element.text,
                left: boundingBox.left.toDouble(),
                top: boundingBox.top.toDouble(),
                right: boundingBox.right.toDouble(),
                bottom: boundingBox.bottom.toDouble(),
              ),
            );
          }
        }
      }

      AppLogger.d('OCR extracted ${blocks.length} text blocks', tag: 'OCR');
      return RawReceiptData(fullText: recognizedText.text, blocks: blocks);
    } catch (e) {
      AppLogger.e('ML Kit OCR Error (with bounding boxes)', tag: 'OCR', error: e);
      return null;
    }
  }

  /// Check if extracted text quality is good enough
  /// Returns true if text seems valid for receipt parsing
  bool isTextQualityGood(String text) {
    if (text.isEmpty) return false;

    // Check minimum length (receipts should have some text)
    if (text.length < 20) return false;

    // Check for common receipt indicators
    final receiptIndicators = [
      'total',
      'subtotal',
      'tax',
      'amount',
      'date',
      'receipt',
      '\$',
      '€',
      '£',
      '¥',
      '₦',
    ];

    final lowerText = text.toLowerCase();
    final hasIndicators = receiptIndicators.any(
      (indicator) => lowerText.contains(indicator),
    );

    // Check for numbers (receipts should have amounts)
    final hasNumbers = RegExp(r'\d').hasMatch(text);

    return hasIndicators && hasNumbers;
  }

  void dispose() {
    try {
      if (_textRecognizer != null && !_isDisposed) {
        AppLogger.d('Disposing ML Kit TextRecognizer', tag: 'OCR');
        _textRecognizer!.close();
        _textRecognizer = null;
        _isDisposed = true;
      }
    } catch (e) {
      AppLogger.e('Error disposing MLKitOCRService', tag: 'OCR', error: e);
    }
  }
}
