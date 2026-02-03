import 'dart:io';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../features/expenses/domain/entities/expense_entity.dart';
import '../models/currency.dart';

/// Service for exporting expenses and report data to XLS and CSV formats
class ExportService {
  /// Export expenses to XLS format
  Future<File> exportExpensesToXLS({
    required List<ExpenseEntity> expenses,
    required DateTime startDate,
    required DateTime endDate,
    required Currency currency,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1'); // Delete default sheet
    
    final sheet = excel['Expenses'];
    
    // Add header row
    final headers = [
      'Date',
      'Title',
      'Amount',
      'Currency',
      'Category',
      'Merchant',
      'Description',
      'Entry Mode',
      'Created At',
      'Updated At',
      'Trip ID',
    ];
    
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      // Style header
      cell.cellStyle = CellStyle(
        bold: true,
      );
    }
    
    // Add data rows (sorted by date, newest first)
    final sortedExpenses = List<ExpenseEntity>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    for (int row = 0; row < sortedExpenses.length; row++) {
      final expense = sortedExpenses[row];
      final rowIndex = row + 1;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(expense.date));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(expense.title);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = DoubleCellValue(expense.amount);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(expense.currency ?? currency.code);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(_formatCategory(expense.category));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(expense.merchant ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(expense.description ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(_formatEntryMode(expense.entryMode));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(expense.createdAt));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(expense.updatedAt));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = TextCellValue(''); // Trip ID - would need to be added to entity if available
    }
    
    // Auto-size columns
    for (int col = 0; col < headers.length; col++) {
      sheet.setColumnWidth(col, 15);
    }
    
    // Save file
    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to encode Excel file');
    }
    
    final directory = await getTemporaryDirectory();
    final fileName = _generateFileName('xlsx', startDate, endDate);
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    
    return file;
  }

  /// Export expenses to CSV format
  Future<File> exportExpensesToCSV({
    required List<ExpenseEntity> expenses,
    required DateTime startDate,
    required DateTime endDate,
    required Currency currency,
  }) async {
    final csvData = <List<dynamic>>[];
    
    // Add header row
    csvData.add([
      'Date',
      'Title',
      'Amount',
      'Currency',
      'Category',
      'Merchant',
      'Description',
      'Entry Mode',
      'Created At',
      'Updated At',
      'Trip ID',
    ]);
    
    // Add data rows (sorted by date, newest first)
    final sortedExpenses = List<ExpenseEntity>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    for (final expense in sortedExpenses) {
      csvData.add([
        _formatDate(expense.date),
        expense.title,
        expense.amount,
        expense.currency ?? currency.code,
        _formatCategory(expense.category),
        expense.merchant ?? '',
        expense.description ?? '',
        _formatEntryMode(expense.entryMode),
        _formatDateTime(expense.createdAt),
        _formatDateTime(expense.updatedAt),
        '', // Trip ID
      ]);
    }
    
    // Convert to CSV string
    const converter = ListToCsvConverter();
    final csvString = converter.convert(csvData);
    
    // Save file
    final directory = await getTemporaryDirectory();
    final fileName = _generateFileName('csv', startDate, endDate);
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvString);
    
    return file;
  }

  /// Export report data to XLS format (with multiple sheets)
  Future<File> exportReportToXLS({
    required List<ExpenseEntity> expenses,
    required Map<String, dynamic> reportSummary,
    required Map<ExpenseCategory, double> categoryBreakdown,
    required DateTime startDate,
    required DateTime endDate,
    required Currency currency,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1'); // Delete default sheet
    
    // Sheet 1: Expenses
    final expensesSheet = excel['Expenses'];
    _addExpensesToSheet(expensesSheet, expenses, currency);
    
    // Sheet 2: Report Summary
    final summarySheet = excel['Report Summary'];
    _addReportSummaryToSheet(
      summarySheet,
      reportSummary,
      categoryBreakdown,
      startDate,
      endDate,
      currency,
    );
    
    // Save file
    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to encode Excel file');
    }
    
    final directory = await getTemporaryDirectory();
    final fileName = _generateFileName('xlsx', startDate, endDate, prefix: 'report');
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    
    return file;
  }

  /// Export report data to CSV format (single file with sections)
  Future<File> exportReportToCSV({
    required List<ExpenseEntity> expenses,
    required Map<String, dynamic> reportSummary,
    required Map<ExpenseCategory, double> categoryBreakdown,
    required DateTime startDate,
    required DateTime endDate,
    required Currency currency,
  }) async {
    final csvData = <List<dynamic>>[];
    
    // Section 1: Expenses
    csvData.add(['EXPENSES']);
    csvData.add([
      'Date',
      'Title',
      'Amount',
      'Currency',
      'Category',
      'Merchant',
      'Description',
      'Entry Mode',
      'Created At',
      'Updated At',
      'Trip ID',
    ]);
    
    final sortedExpenses = List<ExpenseEntity>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    for (final expense in sortedExpenses) {
      csvData.add([
        _formatDate(expense.date),
        expense.title,
        expense.amount,
        expense.currency ?? currency.code,
        _formatCategory(expense.category),
        expense.merchant ?? '',
        expense.description ?? '',
        _formatEntryMode(expense.entryMode),
        _formatDateTime(expense.createdAt),
        _formatDateTime(expense.updatedAt),
        '', // Trip ID
      ]);
    }
    
    // Empty row separator
    csvData.add([]);
    
    // Section 2: Report Summary
    csvData.add(['REPORT SUMMARY']);
    csvData.add(['Metric', 'Value']);
    csvData.add(['Total Spending', reportSummary['total'] ?? 0.0]);
    csvData.add(['Average Spending', reportSummary['average'] ?? 0.0]);
    csvData.add(['Transaction Count', reportSummary['count'] ?? 0]);
    csvData.add(['Highest Expense', reportSummary['highest'] ?? 0.0]);
    csvData.add(['Lowest Expense', reportSummary['lowest'] ?? 0.0]);
    csvData.add(['Start Date', _formatDate(startDate)]);
    csvData.add(['End Date', _formatDate(endDate)]);
    
    // Empty row separator
    csvData.add([]);
    
    // Section 3: Category Breakdown
    csvData.add(['CATEGORY BREAKDOWN']);
    csvData.add(['Category', 'Amount', 'Percentage']);
    
    final total = reportSummary['total'] as double? ?? 0.0;
    final sortedCategories = categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in sortedCategories) {
      if (entry.value > 0) {
        final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
        csvData.add([
          _formatCategory(entry.key),
          entry.value,
          '${percentage.toStringAsFixed(2)}%',
        ]);
      }
    }
    
    // Convert to CSV string
    const converter = ListToCsvConverter();
    final csvString = converter.convert(csvData);
    
    // Save file
    final directory = await getTemporaryDirectory();
    final fileName = _generateFileName('csv', startDate, endDate, prefix: 'report');
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvString);
    
    return file;
  }

  /// Add expenses data to an Excel sheet
  void _addExpensesToSheet(
    Sheet sheet,
    List<ExpenseEntity> expenses,
    Currency currency,
  ) {
    // Add header row
    final headers = [
      'Date',
      'Title',
      'Amount',
      'Currency',
      'Category',
      'Merchant',
      'Description',
      'Entry Mode',
      'Created At',
      'Updated At',
      'Trip ID',
    ];
    
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = CellStyle(
        bold: true,
      );
    }
    
    // Add data rows (sorted by date, newest first)
    final sortedExpenses = List<ExpenseEntity>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    for (int row = 0; row < sortedExpenses.length; row++) {
      final expense = sortedExpenses[row];
      final rowIndex = row + 1;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(expense.date));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(expense.title);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = DoubleCellValue(expense.amount);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(expense.currency ?? currency.code);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(_formatCategory(expense.category));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(expense.merchant ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(expense.description ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(_formatEntryMode(expense.entryMode));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(expense.createdAt));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(expense.updatedAt));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = TextCellValue(''); // Trip ID
    }
    
    // Auto-size columns
    for (int col = 0; col < headers.length; col++) {
      sheet.setColumnWidth(col, 15);
    }
  }

  /// Add report summary data to an Excel sheet
  void _addReportSummaryToSheet(
    Sheet sheet,
    Map<String, dynamic> reportSummary,
    Map<ExpenseCategory, double> categoryBreakdown,
    DateTime startDate,
    DateTime endDate,
    Currency currency,
  ) {
    int rowIndex = 0;
    
    // Overview Section
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .value = TextCellValue('OVERVIEW');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .cellStyle = CellStyle(bold: true);
    rowIndex++;
    
    final overviewData = [
      ['Total Spending', reportSummary['total'] ?? 0.0],
      ['Average Spending', reportSummary['average'] ?? 0.0],
      ['Transaction Count', reportSummary['count'] ?? 0],
      ['Highest Expense', reportSummary['highest'] ?? 0.0],
      ['Lowest Expense', reportSummary['lowest'] ?? 0.0],
    ];
    
    for (final row in overviewData) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(row[0] as String);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = row[1] is num
              ? DoubleCellValue((row[1] as num).toDouble())
              : IntCellValue(row[1] as int);
      rowIndex++;
    }
    
    // Date Range Section
    rowIndex++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .value = TextCellValue('DATE RANGE');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .cellStyle = CellStyle(bold: true);
    rowIndex++;
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .value = TextCellValue('Start Date');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        .value = TextCellValue(_formatDate(startDate));
    rowIndex++;
    
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .value = TextCellValue('End Date');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        .value = TextCellValue(_formatDate(endDate));
    rowIndex++;
    
    // Category Breakdown Section
    rowIndex++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .value = TextCellValue('CATEGORY BREAKDOWN');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .cellStyle = CellStyle(bold: true);
    rowIndex++;
    
    // Header row
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .value = TextCellValue('Category');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        .value = TextCellValue('Amount');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
        .value = TextCellValue('Percentage');
    for (int col = 0; col < 3; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex))
          .cellStyle = CellStyle(
        bold: true,
      );
    }
    rowIndex++;
    
    final total = reportSummary['total'] as double? ?? 0.0;
    final sortedCategories = categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in sortedCategories) {
      if (entry.value > 0) {
        final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = TextCellValue(_formatCategory(entry.key));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = DoubleCellValue(entry.value);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            .value = TextCellValue('${percentage.toStringAsFixed(2)}%');
        rowIndex++;
      }
    }
    
    // Auto-size columns
    sheet.setColumnWidth(0, 20);
    sheet.setColumnWidth(1, 15);
    sheet.setColumnWidth(2, 15);
  }

  /// Generate filename with auto-naming
  String _generateFileName(
    String format,
    DateTime startDate,
    DateTime endDate, {
    String prefix = 'expenses',
  }) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final startStr = dateFormat.format(startDate);
    final endStr = dateFormat.format(endDate);
    return '${prefix}_${startStr}_to_$endStr.$format';
  }

  /// Format date for export
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Format datetime for export
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  /// Format category enum to readable string
  String _formatCategory(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.bills:
        return 'Bills';
      case ExpenseCategory.health:
        return 'Health';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.debit:
        return 'Debit';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  /// Format entry mode enum to readable string
  String _formatEntryMode(EntryMode mode) {
    switch (mode) {
      case EntryMode.manual:
        return 'Manual';
      case EntryMode.notification:
        return 'Notification';
      case EntryMode.scan:
        return 'Scan';
      case EntryMode.voice:
        return 'Voice';
      case EntryMode.clipboard:
        return 'Clipboard';
    }
  }
}
