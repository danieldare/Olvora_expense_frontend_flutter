import 'dart:io';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../../features/expenses/domain/entities/expense_entity.dart';
import 'package:string_similarity/string_similarity.dart';

/// Service for importing expenses from XLS and CSV formats
class ImportService {
  /// Parse expenses from an Excel file
  Future<List<ImportExpense>> parseExcelFile(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    
    // Try to find the Expenses sheet, or use the first sheet
    Sheet? sheet = excel.tables['Expenses'];
    if (sheet == null && excel.tables.isNotEmpty) {
      sheet = excel.tables.values.first;
    }
    
    if (sheet == null) {
      throw Exception('No sheets found in Excel file');
    }
    
    final expenses = <ImportExpense>[];
    
    // Find header row (usually row 0)
    int headerRow = 0;
    final headers = <String, int>{};
    
    // Read header row from first row
    if (sheet.rows.isNotEmpty && sheet.rows[headerRow].isNotEmpty) {
      int col = 0;
      for (final cell in sheet.rows[headerRow]) {
        if (cell != null) {
          final headerText = _getCellValue(cell.value).toString().trim().toLowerCase();
          if (headerText.isNotEmpty) {
            headers[headerText] = col;
          }
        }
        col++;
      }
    }
    
    // Read data rows (skip header row)
    for (int row = headerRow + 1; row < sheet.rows.length; row++) {
      try {
        final expense = _parseRow(headers, sheet, row);
        if (expense != null) {
          expenses.add(expense);
        }
      } catch (e) {
        // Skip invalid rows but continue processing
        continue;
      }
    }
    
    return expenses;
  }
  
  /// Parse expenses from a CSV file
  Future<List<ImportExpense>> parseCsvFile(File file) async {
    final content = await file.readAsString();
    const converter = CsvToListConverter();
    final rows = converter.convert(content);
    
    if (rows.isEmpty) {
      throw Exception('CSV file is empty');
    }
    
    // Find header row
    int headerRow = 0;
    final headers = <String, int>{};
    
    // Read header row
    if (rows.isNotEmpty) {
      for (int col = 0; col < rows[headerRow].length; col++) {
        final headerText = rows[headerRow][col].toString().trim().toLowerCase();
        headers[headerText] = col;
      }
    }
    
    final expenses = <ImportExpense>[];
    
    // Read data rows (skip header row)
    for (int row = headerRow + 1; row < rows.length; row++) {
      try {
        final expense = _parseCsvRow(headers, rows[row], row);
        if (expense != null) {
          expenses.add(expense);
        }
      } catch (e) {
        // Skip invalid rows but continue processing
        continue;
      }
    }
    
    return expenses;
  }
  
  /// Parse a row from Excel sheet
  ImportExpense? _parseRow(Map<String, int> headers, Sheet sheet, int row) {
    if (row >= sheet.rows.length || sheet.rows[row].isEmpty) {
      return null;
    }
    
    final rowData = sheet.rows[row];
    
    // Helper to get column index for a header
    int? getCol(String header) {
      // Try exact match first
      if (headers.containsKey(header)) {
        return headers[header];
      }
      // Try partial matches
      for (final key in headers.keys) {
        if (key.contains(header) || header.contains(key)) {
          return headers[key];
        }
      }
      return null;
    }
    
    // Extract values
    final dateCol = getCol('date');
    final titleCol = getCol('title');
    final amountCol = getCol('amount');
    final currencyCol = getCol('currency');
    final categoryCol = getCol('category');
    final merchantCol = getCol('merchant');
    final descriptionCol = getCol('description');
    final entryModeCol = getCol('entry mode');
    
    // Required fields
    if (dateCol == null || titleCol == null || amountCol == null) {
      return null;
    }
    
    // Parse date
    final dateCell = dateCol < rowData.length ? rowData[dateCol] : null;
    final dateValue = dateCell != null ? _getCellValue(dateCell.value) : null;
    final date = _parseDate(dateValue);
    if (date == null) {
      return null;
    }
    
    // Parse title
    final titleCell = titleCol < rowData.length ? rowData[titleCol] : null;
    final title = titleCell != null ? _getCellValue(titleCell.value).toString().trim() : '';
    if (title.isEmpty) {
      return null;
    }
    
    // Parse amount
    final amountCell = amountCol < rowData.length ? rowData[amountCol] : null;
    final amountValue = amountCell != null ? _getCellValue(amountCell.value) : null;
    final amount = _parseAmount(amountValue);
    if (amount == null || amount <= 0) {
      return null;
    }
    
    // Parse optional fields
    String? currency;
    if (currencyCol != null && currencyCol < rowData.length) {
      final currencyCell = rowData[currencyCol];
      if (currencyCell != null) {
        final currencyValue = _getCellValue(currencyCell.value).toString().trim().toUpperCase();
        if (currencyValue.length == 3) {
          currency = currencyValue;
        }
      }
    }
    
    String? merchant;
    if (merchantCol != null && merchantCol < rowData.length) {
      final merchantCell = rowData[merchantCol];
      if (merchantCell != null) {
        merchant = _getCellValue(merchantCell.value).toString().trim();
        if (merchant.isEmpty) merchant = null;
      }
    }
    
    String? description;
    if (descriptionCol != null && descriptionCol < rowData.length) {
      final descCell = rowData[descriptionCol];
      if (descCell != null) {
        description = _getCellValue(descCell.value).toString().trim();
        if (description.isEmpty) description = null;
      }
    }
    
    ExpenseCategory? category;
    if (categoryCol != null && categoryCol < rowData.length) {
      final categoryCell = rowData[categoryCol];
      if (categoryCell != null) {
        final categoryValue = _getCellValue(categoryCell.value).toString().trim();
        category = _parseCategory(categoryValue);
      }
    }
    category ??= ExpenseCategory.other;
    
    EntryMode entryMode = EntryMode.manual;
    if (entryModeCol != null && entryModeCol < rowData.length) {
      final entryModeCell = rowData[entryModeCol];
      if (entryModeCell != null) {
        final entryModeValue = _getCellValue(entryModeCell.value).toString().trim().toLowerCase();
        entryMode = _parseEntryMode(entryModeValue);
      }
    }
    
    return ImportExpense(
      title: title,
      amount: amount,
      date: date,
      category: category,
      currency: currency,
      merchant: merchant,
      description: description,
      entryMode: entryMode,
      rowIndex: row,
    );
  }
  
  /// Parse a row from CSV
  ImportExpense? _parseCsvRow(Map<String, int> headers, List<dynamic> row, int rowIndex) {
    // Helper to get column index for a header
    int? getCol(String header) {
      // Try exact match first
      if (headers.containsKey(header)) {
        return headers[header];
      }
      // Try partial matches
      for (final key in headers.keys) {
        if (key.contains(header) || header.contains(key)) {
          return headers[key];
        }
      }
      return null;
    }
    
    // Extract values
    final dateCol = getCol('date');
    final titleCol = getCol('title');
    final amountCol = getCol('amount');
    final currencyCol = getCol('currency');
    final categoryCol = getCol('category');
    final merchantCol = getCol('merchant');
    final descriptionCol = getCol('description');
    final entryModeCol = getCol('entry mode');
    
    // Required fields
    if (dateCol == null || titleCol == null || amountCol == null) {
      return null;
    }
    
    // Parse date
    final dateValue = row[dateCol];
    final date = _parseDate(dateValue);
    if (date == null) {
      return null;
    }
    
    // Parse title
    final title = row[titleCol].toString().trim();
    if (title.isEmpty) {
      return null;
    }
    
    // Parse amount
    final amountValue = row[amountCol];
    final amount = _parseAmount(amountValue);
    if (amount == null || amount <= 0) {
      return null;
    }
    
    // Parse optional fields
    String? currency;
    if (currencyCol != null && currencyCol < row.length) {
      final currencyValue = row[currencyCol].toString().trim().toUpperCase();
      if (currencyValue.length == 3) {
        currency = currencyValue;
      }
    }
    
    String? merchant;
    if (merchantCol != null && merchantCol < row.length) {
      merchant = row[merchantCol].toString().trim();
      if (merchant.isEmpty) merchant = null;
    }
    
    String? description;
    if (descriptionCol != null && descriptionCol < row.length) {
      description = row[descriptionCol].toString().trim();
      if (description.isEmpty) description = null;
    }
    
    ExpenseCategory? category;
    if (categoryCol != null && categoryCol < row.length) {
      final categoryValue = row[categoryCol].toString().trim();
      category = _parseCategory(categoryValue);
    }
    category ??= ExpenseCategory.other;
    
    EntryMode entryMode = EntryMode.manual;
    if (entryModeCol != null && entryModeCol < row.length) {
      final entryModeValue = row[entryModeCol].toString().trim().toLowerCase();
      entryMode = _parseEntryMode(entryModeValue);
    }
    
    return ImportExpense(
      title: title,
      amount: amount,
      date: date,
      category: category,
      currency: currency,
      merchant: merchant,
      description: description,
      entryMode: entryMode,
      rowIndex: rowIndex,
    );
  }
  
  /// Get cell value as string
  dynamic _getCellValue(dynamic value) {
    if (value == null) return '';
    if (value is TextCellValue) return value.value;
    if (value is IntCellValue) return value.value;
    if (value is DoubleCellValue) return value.value;
    if (value is DateCellValue) {
      try {
        return value.asDateTimeLocal();
      } catch (e) {
        return '${value.year}-${value.month}-${value.day}';
      }
    }
    if (value is BoolCellValue) return value.value;
    if (value is FormulaCellValue) {
      // For formulas, return the formula string
      return value.formula;
    }
    return value.toString();
  }
  
  /// Parse date from various formats
  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    
    // If it's already a DateTime
    if (value is DateTime) {
      return value;
    }
    
    // If it's a DateCellValue
    if (value is DateCellValue) {
      try {
        return value.asDateTimeLocal();
      } catch (e) {
        return DateTime(value.year, value.month, value.day);
      }
    }
    
    // Try parsing as string
    final dateStr = value.toString().trim();
    if (dateStr.isEmpty) return null;
    
    // Try various date formats
    final formats = [
      'yyyy-MM-dd',
      'MM/dd/yyyy',
      'dd/MM/yyyy',
      'yyyy/MM/dd',
      'dd-MM-yyyy',
      'MM-dd-yyyy',
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-ddTHH:mm:ss',
      'dd MMM yyyy',
      'MMM dd, yyyy',
    ];
    
    for (final format in formats) {
      try {
        final formatter = DateFormat(format);
        return formatter.parse(dateStr);
      } catch (e) {
        continue;
      }
    }
    
    // Try ISO 8601
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      // Ignore
    }
    
    // Try parsing as timestamp (milliseconds or seconds)
    final timestamp = double.tryParse(dateStr);
    if (timestamp != null) {
      // Excel dates are often stored as days since 1900-01-01
      if (timestamp > 25569) { // Excel epoch
        final excelEpoch = DateTime(1899, 12, 30);
        return excelEpoch.add(Duration(days: timestamp.toInt()));
      }
      // Or as Unix timestamp
      if (timestamp > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
      }
    }
    
    return null;
  }
  
  /// Parse amount from various formats
  double? _parseAmount(dynamic value) {
    if (value == null) return null;
    
    if (value is num) {
      return value.toDouble();
    }
    
    final str = value.toString().trim();
    if (str.isEmpty) return null;
    
    // Remove currency symbols and commas
    final cleaned = str.replaceAll(RegExp(r'[^\d.-]'), '');
    return double.tryParse(cleaned);
  }
  
  /// Parse category from string
  ExpenseCategory? _parseCategory(String value) {
    final normalized = value.trim().toLowerCase();
    
    // Direct enum match
    for (final category in ExpenseCategory.values) {
      if (category.name.toLowerCase() == normalized) {
        return category;
      }
    }
    
    // Common mappings
    final mappings = {
      'food': ExpenseCategory.food,
      'dining': ExpenseCategory.food,
      'groceries': ExpenseCategory.food,
      'restaurant': ExpenseCategory.food,
      'transport': ExpenseCategory.transport,
      'transportation': ExpenseCategory.transport,
      'travel': ExpenseCategory.transport,
      'entertainment': ExpenseCategory.entertainment,
      'shopping': ExpenseCategory.shopping,
      'bills': ExpenseCategory.bills,
      'utilities': ExpenseCategory.bills,
      'health': ExpenseCategory.health,
      'healthcare': ExpenseCategory.health,
      'medical': ExpenseCategory.health,
      'education': ExpenseCategory.education,
      'debit': ExpenseCategory.debit,
      'other': ExpenseCategory.other,
    };
    
    for (final entry in mappings.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }
    
    return null;
  }
  
  /// Parse entry mode from string
  EntryMode _parseEntryMode(String value) {
    final normalized = value.trim().toLowerCase();
    
    for (final mode in EntryMode.values) {
      if (mode.name.toLowerCase() == normalized) {
        return mode;
      }
    }
    
    return EntryMode.manual;
  }
  
  /// Detect duplicates by comparing expenses
  List<ImportExpense> detectDuplicates(
    List<ImportExpense> expenses,
    List<ExpenseEntity> existingExpenses,
  ) {
    final duplicates = <ImportExpense>[];
    
    for (final expense in expenses) {
      for (final existing in existingExpenses) {
        // Check if same date, similar amount, and similar title
        final sameDate = expense.date.year == existing.date.year &&
            expense.date.month == existing.date.month &&
            expense.date.day == existing.date.day;
        
        if (!sameDate) continue;
        
        // Check amount similarity (within 1% or exact match)
        final amountDiff = (expense.amount - existing.amount).abs();
        final amountSimilar = amountDiff < 0.01 || amountDiff / expense.amount < 0.01;
        
        if (!amountSimilar) continue;
        
        // Check title similarity using string similarity
        final titleSimilarity = StringSimilarity.compareTwoStrings(
          expense.title.toLowerCase(),
          existing.title.toLowerCase(),
        );
        
        // If title similarity is high (>0.8) or titles are very similar
        if (titleSimilarity > 0.8) {
          duplicates.add(expense);
          break;
        }
      }
    }
    
    return duplicates;
  }
}

/// Represents an expense parsed from import file
class ImportExpense {
  final String title;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String? currency;
  final String? merchant;
  final String? description;
  final EntryMode entryMode;
  final int rowIndex;
  final bool isDuplicate;
  
  ImportExpense({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.currency,
    this.merchant,
    this.description,
    this.entryMode = EntryMode.manual,
    required this.rowIndex,
    this.isDuplicate = false,
  });
  
  /// Convert to DTO format for API
  Map<String, dynamic> toDto() {
    return {
      'title': title,
      'amount': amount,
      'date': date.toIso8601String().split('T')[0],
      'category': category.name,
      if (currency != null) 'currency': currency,
      if (merchant != null) 'merchant': merchant,
      if (description != null) 'description': description,
      'entryMode': entryMode.name,
    };
  }
}
