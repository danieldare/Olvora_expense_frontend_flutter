import '../parsers/models/raw_sheet_data.dart';
import '../../domain/entities/detected_structure.dart';
import '../../domain/entities/parsed_expense.dart';

/// Abstract interface for transforming raw sheet data to expenses
abstract class ExpenseTransformer {
  List<ParsedExpense> transform({
    required RawSheetData sheet,
    required DetectedStructure structure,
    required int year,
  });
}
