import 'dart:convert';
import 'package:csv/csv.dart';
import 'file_parser.dart';
import 'models/raw_sheet_data.dart';
import '../../domain/entities/import_file.dart';
import 'excel_parser.dart'; // Import ParseException

class CsvParser implements FileParser {
  @override
  bool canParse(ImportFile file) => file.isCsv;

  @override
  Future<List<RawSheetData>> parse(ImportFile file) async {
    // Try different encodings
    String content;
    var bytes = file.bytes;

    // Check for and remove BOM (Byte Order Mark)
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      // UTF-8 BOM detected, remove it
      bytes = bytes.sublist(3);
    }

    try {
      // Try UTF-8 first (most common)
      content = utf8.decode(bytes);
    } catch (_) {
      // Try UTF-8 with allowMalformed for Windows-1252 compatibility
      // Windows-1252 bytes in 0x80-0x9F range cause UTF-8 to fail
      try {
        content = utf8.decode(bytes, allowMalformed: true);
        // Check if decoding produced replacement characters (indicates wrong encoding)
        if (content.contains('\uFFFD')) {
          // Fall back to Latin1 which handles all single-byte values
          content = latin1.decode(bytes);
        }
      } catch (_) {
        // Final fallback to Latin1
        try {
          content = latin1.decode(bytes);
        } catch (e) {
          throw ParseException('Could not decode CSV file: ${e.toString()}');
        }
      }
    }

    // Detect delimiter
    final delimiter = _detectDelimiter(content);

    // Parse CSV with detected delimiter
    final converter = CsvToListConverter(
      fieldDelimiter: delimiter,
      shouldParseNumbers: false, // Keep as strings for now
      eol: '\n',
    );
    
    List<List<dynamic>> rows;
    try {
      rows = converter.convert(content);
    } catch (e) {
      throw ParseException('Failed to parse CSV: ${e.toString()}');
    }

    if (rows.isEmpty) {
      throw ParseException('CSV file is empty');
    }

    // Normalize row lengths
    final maxCols = rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    for (var i = 0; i < rows.length; i++) {
      while (rows[i].length < maxCols) {
        rows[i].add(null);
      }
    }

    return [
      RawSheetData(
        sheetName: 'Sheet1',
        rows: rows,
        rowCount: rows.length,
        columnCount: maxCols,
      )
    ];
  }

  String _detectDelimiter(String content) {
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

    return detectedDelimiter ?? ',';
  }
}
