import '../../data/transformers/transformer_interface.dart';
import '../../data/transformers/transactional_transformer.dart';
import '../../data/transformers/pivot_transformer.dart';
import '../../data/parsers/models/raw_sheet_data.dart';
import '../../domain/entities/detected_structure.dart';
import '../../domain/entities/parsed_expense.dart';

/// Use case: Transform raw sheet data to ParsedExpense list
class TransformToExpenses {
  ExpenseTransformer _getTransformer(FileStructureType type) {
    switch (type) {
      case FileStructureType.transactional:
        return TransactionalTransformer();
      case FileStructureType.pivotMonthColumns:
      case FileStructureType.pivotMonthRows:
        return PivotTransformer();
      case FileStructureType.unknown:
        throw Exception('Cannot transform unknown structure');
    }
  }

  /// Transform sheet data to expenses
  List<ParsedExpense> execute({
    required RawSheetData sheet,
    required DetectedStructure structure,
    required int year,
  }) {
    final transformer = _getTransformer(structure.type);
    return transformer.transform(
      sheet: sheet,
      structure: structure,
      year: year,
    );
  }
}
