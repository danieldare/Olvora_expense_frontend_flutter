import 'dart:typed_data';

/// Represents a file selected for import
class ImportFile {
  final String name;
  final String extension;
  final Uint8List bytes;
  final int sizeBytes;
  final DateTime pickedAt;

  const ImportFile({
    required this.name,
    required this.extension,
    required this.bytes,
    required this.sizeBytes,
    required this.pickedAt,
  });

  bool get isExcel => extension == 'xlsx' || extension == 'xls';
  bool get isCsv => extension == 'csv';
  
  String get displaySize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
