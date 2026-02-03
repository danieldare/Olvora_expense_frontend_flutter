/// Model for raw receipt data extracted from ML Kit OCR
/// Contains text with bounding box coordinates for improved parsing
class RawReceiptData {
  final String fullText;
  final List<RawTextBlock> blocks;

  RawReceiptData({
    required this.fullText,
    required this.blocks,
  });

  Map<String, dynamic> toJson() {
    return {
      'raw_text': fullText,
      'blocks': blocks.map((b) => b.toJson()).toList(),
    };
  }

  factory RawReceiptData.fromJson(Map<String, dynamic> json) {
    return RawReceiptData(
      fullText: json['raw_text'] as String,
      blocks: (json['blocks'] as List<dynamic>?)
              ?.map((b) => RawTextBlock.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Represents a text block with bounding box coordinates
class RawTextBlock {
  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  RawTextBlock({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'x': left,
      'y': top,
      'right': right,
      'bottom': bottom,
    };
  }

  factory RawTextBlock.fromJson(Map<String, dynamic> json) {
    return RawTextBlock(
      text: json['text'] as String,
      left: (json['x'] as num).toDouble(),
      top: (json['y'] as num).toDouble(),
      right: (json['right'] as num?)?.toDouble() ?? (json['x'] as num).toDouble(),
      bottom: (json['bottom'] as num?)?.toDouble() ?? (json['y'] as num).toDouble(),
    );
  }

  /// Get width of the text block
  double get width => right - left;

  /// Get height of the text block
  double get height => bottom - top;

  /// Get center X coordinate
  double get centerX => (left + right) / 2;

  /// Get center Y coordinate
  double get centerY => (top + bottom) / 2;
}

