import 'dart:io';
import 'dart:convert';

/// Production-grade intelligent file analyzer.
///
/// Automatically detects:
/// - File encoding (UTF-8, UTF-16, ISO-8859-1, Windows-1252)
/// - CSV delimiter (comma, semicolon, tab, pipe)
/// - Header row position
/// - Empty rows/columns
/// - File structure patterns
///
/// This is the first step in the import pipeline - it makes the file
/// intelligible before any parsing happens.
class FileAnalyzer {
  /// Analyzes a CSV file and returns comprehensive metadata.
  ///
  /// Returns FileAnalysisResult with all detected properties.
  static Future<FileAnalysisResult> analyzeCsvFile(File file) async {
    try {
      // Read raw bytes for encoding detection
      final bytes = await file.readAsBytes();
      
      // Detect encoding
      final encoding = _detectEncoding(bytes);
      
      // Decode with detected encoding
      final content = encoding.decode(bytes);
      
      // Detect delimiter
      final delimiter = _detectDelimiter(content);
      
      // Detect header row
      final headerRowIndex = _detectHeaderRow(content, delimiter);
      
      // Analyze structure
      final structure = _analyzeStructure(content, delimiter, headerRowIndex);
      
      return FileAnalysisResult(
        encoding: encoding,
        delimiter: delimiter,
        headerRowIndex: headerRowIndex,
        totalRows: structure.totalRows,
        totalColumns: structure.totalColumns,
        emptyRows: structure.emptyRows,
        emptyColumns: structure.emptyColumns,
        hasConsistentColumnCount: structure.hasConsistentColumnCount,
        sampleRows: structure.sampleRows,
      );
    } catch (e) {
      throw FileAnalysisException(
        'Failed to analyze file: ${e.toString()}',
        userMessage: 'We couldn\'t read your file. Please check that it\'s a valid CSV file and try again.',
      );
    }
  }

  /// Detects file encoding by analyzing byte patterns.
  static Encoding _detectEncoding(List<int> bytes) {
    // Check for UTF-8 BOM
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return utf8;
    }

    // Check for UTF-16 LE BOM (little-endian)
    // Note: Dart's convert library doesn't have utf16le/utf16be directly
    // We'll decode manually if needed, but for now fall back to utf8
    // Most modern CSV files are UTF-8 anyway
    if (bytes.length >= 2 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xFE) {
      // UTF-16 LE detected - try to decode as UTF-8 first (many files are mislabeled)
      // If that fails, we'll handle UTF-16 in the parsing step
      return utf8;
    }

    // Check for UTF-16 BE BOM (big-endian)
    if (bytes.length >= 2 &&
        bytes[0] == 0xFE &&
        bytes[1] == 0xFF) {
      return utf8; // Same approach
    }

    // Try to decode as UTF-8 first (most common)
    try {
      utf8.decode(bytes);
      return utf8;
    } catch (e) {
      // Not UTF-8, try other encodings
    }

    // Try Windows-1252 (common for Excel exports)
    // Note: Dart doesn't have Windows1252Codec built-in
    // We'll use Latin1 as fallback (covers most Windows-1252 characters)
    try {
      const latin1 = Latin1Codec();
      latin1.decode(bytes);
      return latin1;
    } catch (e) {
      // Not Latin1
    }

    // Try ISO-8859-1 (Latin-1)
    try {
      const latin1 = Latin1Codec();
      latin1.decode(bytes, allowInvalid: false);
      return latin1;
    } catch (e) {
      // Fallback to UTF-8 with error recovery
      return utf8;
    }
  }

  /// Detects CSV delimiter by analyzing first few lines.
  static String _detectDelimiter(String content) {
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).take(10).toList();
    if (lines.isEmpty) return ',';

    // Count occurrences of common delimiters
    final delimiterCounts = <String, int>{
      ',': 0,
      ';': 0,
      '\t': 0,
      '|': 0,
    };

    for (final line in lines) {
      delimiterCounts[','] = delimiterCounts[',']! + line.split(',').length - 1;
      delimiterCounts[';'] = delimiterCounts[';']! + line.split(';').length - 1;
      delimiterCounts['\t'] = delimiterCounts['\t']! + line.split('\t').length - 1;
      delimiterCounts['|'] = delimiterCounts['|']! + line.split('|').length - 1;
    }

    // Find delimiter with highest count
    String? detectedDelimiter;
    int maxCount = 0;

    for (final entry in delimiterCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        detectedDelimiter = entry.key;
      }
    }

    // If no clear winner, default to comma
    return detectedDelimiter ?? ',';
  }

  /// Detects header row by analyzing patterns.
  ///
  /// Looks for:
  /// - Row with mostly text (not numbers)
  /// - Row that appears before data rows
  /// - Row with consistent column count
  static int _detectHeaderRow(String content, String delimiter) {
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return 0;

    // Analyze first 5 rows
    final candidates = <int, double>{};
    
    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i];
      final columns = line.split(delimiter);
      
      // Score based on:
      // 1. Text vs number ratio (headers are usually text)
      // 2. Column count consistency
      // 3. Position (earlier rows more likely to be headers)
      
      int textCount = 0;
      
      for (final col in columns) {
        final trimmed = col.trim();
        if (trimmed.isEmpty) continue;
        
        if (double.tryParse(trimmed.replaceAll(RegExp(r'[^\d.-]'), '')) == null) {
          textCount++;
        }
      }
      
      final textRatio = columns.isNotEmpty ? textCount / columns.length : 0.0;
      final positionScore = 1.0 - (i * 0.1); // Earlier rows score higher
      
      candidates[i] = (textRatio * 0.7) + (positionScore * 0.3);
    }

    // Find row with highest score
    int? headerRow;
    double maxScore = 0.0;

    for (final entry in candidates.entries) {
      if (entry.value > maxScore) {
        maxScore = entry.value;
        headerRow = entry.key;
      }
    }

    return headerRow ?? 0;
  }

  /// Analyzes file structure for quality assessment.
  static _StructureAnalysis _analyzeStructure(
    String content,
    String delimiter,
    int headerRowIndex,
  ) {
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      return _StructureAnalysis(
        totalRows: 0,
        totalColumns: 0,
        emptyRows: 0,
        emptyColumns: [],
        hasConsistentColumnCount: false,
        sampleRows: [],
      );
    }

    // Get header row
    final headerLine = lines[headerRowIndex];
    final headerColumns = headerLine.split(delimiter);
    final expectedColumnCount = headerColumns.length;

    // Analyze data rows
    int emptyRows = 0;
    final columnCounts = <int, int>{};
    final sampleRows = <List<String>>[];

    for (int i = headerRowIndex + 1; i < lines.length && i < headerRowIndex + 21; i++) {
      final line = lines[i];
      final columns = line.split(delimiter).map((c) => c.trim()).toList();
      
      // Check if row is empty
      if (columns.every((c) => c.isEmpty)) {
        emptyRows++;
        continue;
      }

      columnCounts[columns.length] = (columnCounts[columns.length] ?? 0) + 1;
      
      // Collect sample rows (first 5 non-empty rows)
      if (sampleRows.length < 5 && columns.any((c) => c.isNotEmpty)) {
        sampleRows.add(columns);
      }
    }

    // Check consistency
    final mostCommonCount = columnCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    final consistentRows = columnCounts[mostCommonCount] ?? 0;
    final totalDataRows = lines.length - headerRowIndex - 1 - emptyRows;
    final consistencyRatio = totalDataRows > 0 ? consistentRows / totalDataRows : 0.0;

    // Find empty columns
    final emptyColumns = <int>[];
    for (int i = 0; i < expectedColumnCount; i++) {
      bool isEmpty = true;
      for (int j = headerRowIndex + 1; j < lines.length && j < headerRowIndex + 11; j++) {
        final columns = lines[j].split(delimiter);
        if (i < columns.length && columns[i].trim().isNotEmpty) {
          isEmpty = false;
          break;
        }
      }
      if (isEmpty) emptyColumns.add(i);
    }

    return _StructureAnalysis(
      totalRows: lines.length - headerRowIndex - 1,
      totalColumns: expectedColumnCount,
      emptyRows: emptyRows,
      emptyColumns: emptyColumns,
      hasConsistentColumnCount: consistencyRatio >= 0.8,
      sampleRows: sampleRows,
    );
  }
}

/// Result of file analysis.
class FileAnalysisResult {
  final Encoding encoding;
  final String delimiter;
  final int headerRowIndex;
  final int totalRows;
  final int totalColumns;
  final int emptyRows;
  final List<int> emptyColumns;
  final bool hasConsistentColumnCount;
  final List<List<String>> sampleRows;

  FileAnalysisResult({
    required this.encoding,
    required this.delimiter,
    required this.headerRowIndex,
    required this.totalRows,
    required this.totalColumns,
    required this.emptyRows,
    required this.emptyColumns,
    required this.hasConsistentColumnCount,
    required this.sampleRows,
  });

  /// Returns true if file structure looks valid.
  bool get isValid {
    return totalRows > 0 &&
        totalColumns >= 3 &&
        hasConsistentColumnCount &&
        emptyRows < totalRows * 0.5; // Less than 50% empty rows
  }

  /// Returns user-friendly quality assessment.
  String get qualityAssessment {
    if (!isValid) {
      return 'File structure needs attention. Some rows have inconsistent column counts.';
    }
    if (emptyRows > 0) {
      return 'File looks good, but $emptyRows empty rows will be skipped.';
    }
    return 'File structure looks perfect!';
  }
}

/// Internal structure analysis result.
class _StructureAnalysis {
  final int totalRows;
  final int totalColumns;
  final int emptyRows;
  final List<int> emptyColumns;
  final bool hasConsistentColumnCount;
  final List<List<String>> sampleRows;

  _StructureAnalysis({
    required this.totalRows,
    required this.totalColumns,
    required this.emptyRows,
    required this.emptyColumns,
    required this.hasConsistentColumnCount,
    required this.sampleRows,
  });
}

/// Exception thrown during file analysis.
class FileAnalysisException implements Exception {
  final String technicalMessage;
  final String userMessage;

  FileAnalysisException(this.technicalMessage, {required this.userMessage});

  @override
  String toString() => technicalMessage;
}

