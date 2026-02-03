import 'package:excel/excel.dart';
import 'file_parser.dart';
import 'models/raw_sheet_data.dart';
import '../../domain/entities/import_file.dart';

class ExcelParser implements FileParser {
  @override
  bool canParse(ImportFile file) => file.isExcel;

  @override
  Future<List<RawSheetData>> parse(ImportFile file) async {
    try {
      final excel = Excel.decodeBytes(file.bytes);
      final sheets = <RawSheetData>[];

      for (final sheetName in excel.tables.keys) {
        final sheet = excel.tables[sheetName];
        if (sheet == null) continue;

        final rows = <List<dynamic>>[];
        int maxCols = 0;

        for (final row in sheet.rows) {
          final rowData = <dynamic>[];
          for (final cell in row) {
            rowData.add(_extractCellValue(cell));
          }
          rows.add(rowData);
          if (rowData.length > maxCols) maxCols = rowData.length;
        }

        // Normalize row lengths
        for (var i = 0; i < rows.length; i++) {
          while (rows[i].length < maxCols) {
            rows[i].add(null);
          }
        }

        sheets.add(RawSheetData(
          sheetName: sheetName,
          rows: rows,
          rowCount: rows.length,
          columnCount: maxCols,
        ));
      }

      if (sheets.isEmpty) {
        throw ParseException('No sheets found in Excel file');
      }

      return sheets;
    } catch (e) {
      throw ParseException('Failed to parse Excel file: ${e.toString()}');
    }
  }

  dynamic _extractCellValue(Data? cell) {
    if (cell == null) return null;
    
    final value = cell.value;
    if (value == null) return null;

    // Handle different cell types
    if (value is TextCellValue) return value.value;
    if (value is IntCellValue) return value.value;
    if (value is DoubleCellValue) return value.value;
    if (value is DateCellValue) {
      try {
        return value.asDateTimeLocal();
      } catch (_) {
        // Fallback to string representation
        return '${value.year}-${value.month}-${value.day}';
      }
    }
    if (value is BoolCellValue) return value.value;
    if (value is FormulaCellValue) {
      // For formulas, return the formula string
      // The actual calculated value would need to be evaluated separately
      return value.formula;
    }

    return value.toString();
  }
}

class ParseException implements Exception {
  final String message;
  ParseException(this.message);
  
  @override
  String toString() => message;
}
