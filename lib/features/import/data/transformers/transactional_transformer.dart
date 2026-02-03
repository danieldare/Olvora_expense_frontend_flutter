import 'package:uuid/uuid.dart';
import '../detectors/date_detector.dart';
import '../parsers/models/raw_sheet_data.dart';
import 'transformer_interface.dart';
import '../../domain/entities/detected_structure.dart';
import '../../domain/entities/parsed_expense.dart';

/// Transforms transactional structure (row-per-expense) to ParsedExpense list
class TransactionalTransformer implements ExpenseTransformer {
  final _dateDetector = DateDetector();
  final _uuid = const Uuid();

  @override
  List<ParsedExpense> transform({
    required RawSheetData sheet,
    required DetectedStructure structure,
    required int year,
  }) {
    final mapping = structure.columnMapping;
    if (mapping == null) return [];

    final expenses = <ParsedExpense>[];
    final skippedRows = structure.skippedRows.map((s) => s.rowIndex).toSet();

    for (int row = mapping.dataStartRow; row < sheet.rowCount; row++) {
      if (skippedRows.contains(row)) continue;
      if (sheet.isRowEmpty(row)) continue;

      // Extract amount
      final amountCell = sheet.getCell(row, mapping.amountColumn);
      final amount = _parseAmount(amountCell);
      if (amount == null || amount == 0) continue;

      // Extract date
      DateTime date;
      if (mapping.dateColumn != null) {
        final dateCell = sheet.getCell(row, mapping.dateColumn!);
        date = _dateDetector.parse(dateCell) ?? DateTime(year, 1, 1);
      } else {
        date = DateTime(year, 1, 1);
      }

      // Ensure year is correct
      if (date.year != year) {
        date = DateTime(year, date.month, date.day);
      }

      // Extract category
      String category = 'Other';
      if (mapping.categoryColumn != null) {
        final catCell = sheet.getCell(row, mapping.categoryColumn!);
        if (catCell != null && catCell.toString().trim().isNotEmpty) {
          category = catCell.toString().trim();
        }
      }

      // Extract description/title
      String title = category;
      if (mapping.descriptionColumn != null) {
        final descCell = sheet.getCell(row, mapping.descriptionColumn!);
        if (descCell != null && descCell.toString().trim().isNotEmpty) {
          title = descCell.toString().trim();
        }
      }

      // Extract merchant
      String? merchant;
      if (mapping.merchantColumn != null) {
        final merchCell = sheet.getCell(row, mapping.merchantColumn!);
        if (merchCell != null && merchCell.toString().trim().isNotEmpty) {
          merchant = merchCell.toString().trim();
        }
      }

      expenses.add(ParsedExpense(
        id: _uuid.v4(),
        title: title,
        amount: amount.abs(), // Always positive
        originalCategory: category,
        date: date,
        merchant: merchant,
        sourceRow: row,
      ));
    }

    return expenses;
  }

  double? _parseAmount(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    
    final str = value.toString()
      .replaceAll(RegExp(r'[\$€£¥₹₦₱฿₩R\s,]'), '')
      .replaceAll('(', '-')
      .replaceAll(')', '');
    
    return double.tryParse(str);
  }
}
