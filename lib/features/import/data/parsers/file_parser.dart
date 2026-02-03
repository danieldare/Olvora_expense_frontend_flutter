import 'models/raw_sheet_data.dart';
import '../../domain/entities/import_file.dart';
import 'excel_parser.dart';
import 'csv_parser.dart';

/// Abstract interface for file parsers
abstract class FileParser {
  /// Parse file and return raw sheet data
  Future<List<RawSheetData>> parse(ImportFile file);
  
  /// Check if this parser can handle the file
  bool canParse(ImportFile file);
}

/// Factory for creating appropriate parser
class FileParserFactory {
  final ExcelParser? _excelParser;
  final CsvParser? _csvParser;

  FileParserFactory({
    ExcelParser? excelParser,
    CsvParser? csvParser,
  })  : _excelParser = excelParser,
        _csvParser = csvParser;

  FileParser getParser(ImportFile file) {
    if (_excelParser?.canParse(file) ?? false) return _excelParser!;
    if (_csvParser?.canParse(file) ?? false) return _csvParser!;
    throw UnsupportedFileException('Unsupported file type: ${file.extension}');
  }
}

class UnsupportedFileException implements Exception {
  final String message;
  UnsupportedFileException(this.message);
  
  @override
  String toString() => message;
}

