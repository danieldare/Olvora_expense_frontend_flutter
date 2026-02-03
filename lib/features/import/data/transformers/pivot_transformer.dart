import 'package:uuid/uuid.dart';
import '../detectors/month_detector.dart';
import '../parsers/models/raw_sheet_data.dart';
import 'transformer_interface.dart';
import '../../domain/entities/detected_structure.dart';
import '../../domain/entities/parsed_expense.dart';

/// Transforms pivot table structure (months as columns) to ParsedExpense list
class PivotTransformer implements ExpenseTransformer {
  final _monthDetector = MonthDetector();
  final _uuid = const Uuid();

  @override
  List<ParsedExpense> transform({
    required RawSheetData sheet,
    required DetectedStructure structure,
    required int year,
  }) {
    final mapping = structure.pivotMapping;
    if (mapping == null) return [];

    final expenses = <ParsedExpense>[];
    final skippedRows = structure.skippedRows.map((s) => s.rowIndex).toSet();

    // Track current category context (for nested categories)
    String? currentMainCategory;

    for (int row = mapping.dataStartRow; row < sheet.rowCount; row++) {
      if (skippedRows.contains(row)) continue;
      if (sheet.isRowEmpty(row)) continue;

      // Get category from category column
      final categoryCell = sheet.getCell(row, mapping.categoryColumn);
      String? category = categoryCell?.toString().trim();
      
      // Skip if it looks like a header row
      if (category != null && _isLikelyHeader(category)) continue;

      // Handle category hierarchy
      if (category != null && category.isNotEmpty && !_isNumeric(category)) {
        currentMainCategory = category;
      }

      // Process each month column
      for (final entry in mapping.monthColumns.entries) {
        final monthName = entry.key;
        final monthCol = entry.value;
        
        // Get amount from month column
        final amountCell = sheet.getCell(row, monthCol);
        final amount = _parseAmount(amountCell);
        
        if (amount == null || amount == 0) continue;

        // Determine the expense category/title
        String expenseCategory = currentMainCategory ?? 'Other';
        String title = expenseCategory;

        // If current row has a sub-category in a different column
        final possibleSubCat = _findSubCategory(sheet, row, mapping.categoryColumn, monthCol);
        if (possibleSubCat != null) {
          title = '$expenseCategory ($possibleSubCat)';
        }

        // Calculate date (last day of month)
        final monthNum = _monthDetector.monthToNumber(monthName);
        if (monthNum == null) continue;
        
        final date = _monthDetector.lastDayOfMonth(year, monthNum);

        expenses.add(ParsedExpense(
          id: _uuid.v4(),
          title: title,
          amount: amount.abs(),
          originalCategory: expenseCategory,
          date: date,
          sourceRow: row,
          sourceMonth: monthName,
          notes: 'Imported monthly total',
        ));
      }
    }

    return expenses;
  }

  String? _findSubCategory(RawSheetData sheet, int row, int catCol, int monthCol) {
    // Look for sub-category indicator in adjacent columns
    // This handles cases like: "Petrol" | "Gen" | amount | "Car" | amount
    
    for (int col = catCol + 1; col < monthCol; col++) {
      final cell = sheet.getCell(row, col);
      if (cell == null) continue;
      
      final value = cell.toString().trim();
      if (value.isNotEmpty && !_isNumeric(value) && value.length < 20) {
        return value;
      }
    }
    
    return null;
  }

  bool _isLikelyHeader(String value) {
    final lower = value.toLowerCase();
    return lower == 'category' || 
           lower == 'item' || 
           lower == 'description' ||
           _monthDetector.detectMonth(lower) != null;
  }

  bool _isNumeric(String value) {
    return double.tryParse(value.replaceAll(RegExp(r'[\$€£¥₹₦₱฿₩R\s,]'), '')) != null;
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
