import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../../data/parsers/file_parser.dart';
import '../../data/parsers/excel_parser.dart';
import '../../data/parsers/csv_parser.dart';
import '../../domain/entities/import_file.dart';
import '../../data/parsers/models/raw_sheet_data.dart';

/// Use case: Parse an import file and return raw sheet data
class ParseImportFile {
  final FileParserFactory _parserFactory;

  ParseImportFile({
    FileParserFactory? parserFactory,
  }) : _parserFactory = parserFactory ?? FileParserFactory(
          excelParser: ExcelParser(),
          csvParser: CsvParser(),
        );

  /// Parse file from file picker result
  /// Handles files with bytes or path (Android cloud storage)
  Future<List<RawSheetData>> execute(PlatformFile file) async {
    Uint8List bytes;
    
    // If bytes is null but path exists, read from file system
    if (file.bytes == null && file.path != null) {
      try {
        final fileObj = File(file.path!);
        if (await fileObj.exists()) {
          bytes = await fileObj.readAsBytes();
        } else {
          throw Exception('File does not exist at path: ${file.path}');
        }
      } catch (e) {
        throw Exception('Failed to read file from path: $e');
      }
    } else if (file.bytes != null) {
      bytes = Uint8List.fromList(file.bytes!);
    } else {
      throw Exception('File has no bytes or path');
    }
    
    final importFile = ImportFile(
      name: file.name,
      extension: file.extension ?? '',
      bytes: bytes,
      sizeBytes: file.size,
      pickedAt: DateTime.now(),
    );

    // Get appropriate parser
    final parser = _parserFactory.getParser(importFile);

    // Parse file
    return await parser.parse(importFile);
  }
}
