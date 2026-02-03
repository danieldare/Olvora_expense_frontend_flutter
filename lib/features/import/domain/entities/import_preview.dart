import 'import_file.dart';
import 'detected_structure.dart';
import 'parsed_expense.dart';
import 'category_mapping.dart';

/// Complete preview of what will be imported
class ImportPreview {
  final ImportFile file;
  final DetectedStructure structure;
  final List<ParsedExpense> expenses;
  final List<CategoryMapping> categoryMappings;
  final int? selectedYear;
  final String? selectedSheetName;
  
  const ImportPreview({
    required this.file,
    required this.structure,
    required this.expenses,
    required this.categoryMappings,
    this.selectedYear,
    this.selectedSheetName,
  });

  // Computed properties
  int get totalExpenses => expenses.length;
  
  double get totalAmount => expenses.fold(0.0, (sum, e) => sum + e.amount);
  
  DateTime? get earliestDate => expenses.isEmpty ? null : 
    expenses.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
    
  DateTime? get latestDate => expenses.isEmpty ? null :
    expenses.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b);

  int get mappedCategoryCount => 
    categoryMappings.where((m) => m.isMapped).length;
    
  int get unmappedCategoryCount => 
    categoryMappings.where((m) => !m.isMapped).length;
    
  bool get isReadyToImport => unmappedCategoryCount == 0;
  
  List<CategoryMapping> get unmappedCategories =>
    categoryMappings.where((m) => !m.isMapped).toList();
    
  List<CategoryMapping> get autoMappedCategories =>
    categoryMappings.where((m) => m.isAutoMapped).toList();

  List<SkippedRow> get skippedRows => structure.skippedRows;
  
  /// Group expenses by date for preview display
  Map<DateTime, List<ParsedExpense>> get expensesByDate {
    final map = <DateTime, List<ParsedExpense>>{};
    for (final expense in expenses) {
      final dateOnly = DateTime(expense.date.year, expense.date.month, expense.date.day);
      map.putIfAbsent(dateOnly, () => []).add(expense);
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.key.compareTo(a.key))
    );
  }
}
