import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

/// Service for checking image quality and blur detection
class ImageQualityService {
  /// Check if image is blurry using Laplacian variance
  /// Returns true if image quality is acceptable (not blurry)
  /// Threshold: < 100 = blurry, >= 100 = acceptable
  static Future<bool> checkImageQuality(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        return false;
      }

      // Decode image
      final bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Convert to grayscale and calculate Laplacian variance
      final variance = await _calculateLaplacianVariance(image);

      // Dispose image
      image.dispose();
      codec.dispose();

      // Threshold: >= 100 is acceptable quality
      final isAcceptable = variance >= 100.0;

      if (kDebugMode) {
        debugPrint(
          '📸 Image quality check: variance=$variance, acceptable=$isAcceptable',
        );
      }

      return isAcceptable;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking image quality: $e');
      }
      // On error, assume quality is acceptable to avoid blocking user
      return true;
    }
  }

  /// Calculate Laplacian variance for blur detection
  /// Higher variance = sharper image, lower variance = blurrier image
  static Future<double> _calculateLaplacianVariance(ui.Image image) async {
    // Sample a smaller region for performance (center 50% of image)
    final sampleWidth = (image.width * 0.5).round();
    final sampleHeight = (image.height * 0.5).round();
    final startX = (image.width * 0.25).round();
    final startY = (image.height * 0.25).round();

    // Read pixels from the sampled region
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (byteData == null) {
      return 0.0;
    }

    // Convert to grayscale and calculate Laplacian
    final laplacianValues = <double>[];

    for (int y = startY + 1; y < startY + sampleHeight - 1; y++) {
      for (int x = startX + 1; x < startX + sampleWidth - 1; x++) {
        final index = (y * image.width + x) * 4;

        // Get grayscale values for Laplacian kernel
        final center = _getGrayscale(byteData, index);
        final top = _getGrayscale(byteData, ((y - 1) * image.width + x) * 4);
        final bottom = _getGrayscale(byteData, ((y + 1) * image.width + x) * 4);
        final left = _getGrayscale(byteData, (y * image.width + (x - 1)) * 4);
        final right = _getGrayscale(byteData, (y * image.width + (x + 1)) * 4);

        // Laplacian operator: center * 4 - (top + bottom + left + right)
        final laplacian = (center * 4) - (top + bottom + left + right);
        laplacianValues.add(laplacian.abs());
      }
    }

    if (laplacianValues.isEmpty) {
      return 0.0;
    }

    // Calculate variance
    final mean =
        laplacianValues.reduce((a, b) => a + b) / laplacianValues.length;
    final variance =
        laplacianValues
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        laplacianValues.length;

    return variance;
  }

  /// Get grayscale value from RGBA byte data
  static double _getGrayscale(ByteData byteData, int index) {
    final r = byteData.getUint8(index);
    final g = byteData.getUint8(index + 1);
    final b = byteData.getUint8(index + 2);
    // Convert to grayscale using standard weights
    return (0.299 * r + 0.587 * g + 0.114 * b);
  }
}
