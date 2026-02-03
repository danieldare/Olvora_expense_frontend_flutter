import '../../domain/entities/expense_entity.dart';
import '../../../../core/utils/date_parser.dart';
import 'column_mapper.dart';

/// Production-grade expense validator with detailed error messages.
/// 
/// Validation Rules:
/// - Title: Required, non-empty
/// - Amount: Required, positive number, handles commas/currency symbols
/// - Date: Required, valid format (never guesses)
/// - Category: Required, matches enum or aliases
/// - Merchant: Optional
/// - Description: Optional
/// 
/// Never mutates data - only validates and reports errors.
class ExpenseValidator {
  /// Validates a single row of expense data.
  /// 
  /// Returns ValidatedExpense with:
  /// - Parsed and validated data (if valid)
  /// - Detailed error messages (if invalid)
  /// - Row number for reference
  static ValidatedExpense validateRow({
    required Map<String, dynamic> row,
    required ColumnMapping mapping,
    required int rowNumber,
  }) {
    final errors = <String>[];

    // Extract values using column mapping
    final title = _getValue(row, mapping.titleColumn);
    final amountStr = _getValue(row, mapping.amountColumn);
    final dateStr = _getValue(row, mapping.dateColumn);
    final categoryStr = _getValue(row, mapping.categoryColumn);
    final merchant = _getValue(row, mapping.merchantColumn);
    final description = _getValue(row, mapping.descriptionColumn);

    // Validate title
    String? validatedTitle;
    if (title == null || title.trim().isEmpty) {
      errors.add('Title is required');
    } else {
      validatedTitle = title.trim();
      if (validatedTitle.length > 200) {
        errors.add('Title exceeds 200 characters');
      }
    }

    // Validate amount
    double? validatedAmount;
    if (amountStr == null || amountStr.trim().isEmpty) {
      errors.add('Amount is required');
    } else {
      // Remove currency symbols and commas
      final cleaned = amountStr
          .replaceAll(RegExp(r'[^\d.-]'), '')
          .replaceAll(',', '');
      
      validatedAmount = double.tryParse(cleaned);
      if (validatedAmount == null) {
        errors.add('Invalid amount format: "$amountStr"');
      } else if (validatedAmount <= 0) {
        errors.add('Amount must be greater than 0');
      } else if (validatedAmount > 999999.99) {
        errors.add('Amount exceeds maximum value (999,999.99)');
      }
    }

    // Validate date
    DateTime? validatedDate;
    if (dateStr == null || dateStr.trim().isEmpty) {
      errors.add('Date is required');
    } else {
      validatedDate = DateParser.parse(dateStr);
      if (validatedDate == null) {
        errors.add('Invalid date format: "$dateStr". Expected formats: YYYY-MM-DD, MM/DD/YYYY, DD/MM/YYYY');
      } else {
        // Check date is not too far in future (reasonable limit: 1 year)
        final now = DateTime.now();
        final oneYearFromNow = DateTime(now.year + 1, now.month, now.day);
        if (validatedDate.isAfter(oneYearFromNow)) {
          errors.add('Date cannot be more than 1 year in the future');
        }
        // Check date is not too far in past (reasonable limit: 10 years)
        final tenYearsAgo = DateTime(now.year - 10, now.month, now.day);
        if (validatedDate.isBefore(tenYearsAgo)) {
          errors.add('Date cannot be more than 10 years in the past');
        }
      }
    }

    // Validate category
    ExpenseCategory? validatedCategory;
    if (categoryStr == null || categoryStr.trim().isEmpty) {
      errors.add('Category is required');
    } else {
      validatedCategory = _parseCategory(categoryStr);
      if (validatedCategory == null) {
        errors.add(
          'Invalid category: "$categoryStr". Valid categories: ${ExpenseCategory.values.map((e) => e.name).join(", ")}',
        );
      }
    }

    // Validate merchant (optional, but if provided must be valid)
    String? validatedMerchant;
    if (merchant != null && merchant.trim().isNotEmpty) {
      validatedMerchant = merchant.trim();
      if (validatedMerchant.length > 100) {
        errors.add('Merchant name exceeds 100 characters');
      }
    }

    // Validate description (optional, but if provided must be valid)
    String? validatedDescription;
    if (description != null && description.trim().isNotEmpty) {
      validatedDescription = description.trim();
      if (validatedDescription.length > 1000) {
        errors.add('Description exceeds 1000 characters');
      }
    }

    return ValidatedExpense(
      rowNumber: rowNumber,
      title: validatedTitle ?? '',
      amount: validatedAmount,
      date: validatedDate,
      category: validatedCategory,
      merchant: validatedMerchant,
      description: validatedDescription,
      errors: errors,
      rawData: row,
    );
  }

  /// Extracts value from row using column name.
  static String? _getValue(Map<String, dynamic> row, String? column) {
    if (column == null) return null;
    final value = row[column];
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  /// Parses category string to enum, with alias support.
  static ExpenseCategory? _parseCategory(String categoryStr) {
    final normalized = categoryStr.toLowerCase().trim();

    // Direct enum match
    for (final cat in ExpenseCategory.values) {
      if (cat.name == normalized) {
        return cat;
      }
    }

    // Common aliases (user-friendly mappings)
    final aliases = {
      // Food
      'food': ExpenseCategory.food,
      'groceries': ExpenseCategory.food,
      'restaurant': ExpenseCategory.food,
      'dining': ExpenseCategory.food,
      'cafe': ExpenseCategory.food,
      'coffee': ExpenseCategory.food,
      'lunch': ExpenseCategory.food,
      'dinner': ExpenseCategory.food,
      'breakfast': ExpenseCategory.food,
      
      // Transport
      'transport': ExpenseCategory.transport,
      'transportation': ExpenseCategory.transport,
      'travel': ExpenseCategory.transport,
      'uber': ExpenseCategory.transport,
      'taxi': ExpenseCategory.transport,
      'gas': ExpenseCategory.transport,
      'fuel': ExpenseCategory.transport,
      'parking': ExpenseCategory.transport,
      'public transport': ExpenseCategory.transport,
      
      // Entertainment
      'entertainment': ExpenseCategory.entertainment,
      'fun': ExpenseCategory.entertainment,
      'movies': ExpenseCategory.entertainment,
      'cinema': ExpenseCategory.entertainment,
      'games': ExpenseCategory.entertainment,
      'hobbies': ExpenseCategory.entertainment,
      
      // Shopping
      'shopping': ExpenseCategory.shopping,
      'retail': ExpenseCategory.shopping,
      'purchase': ExpenseCategory.shopping,
      
      // Bills
      'bills': ExpenseCategory.bills,
      'bill': ExpenseCategory.bills,
      'utilities': ExpenseCategory.bills,
      'electricity': ExpenseCategory.bills,
      'water': ExpenseCategory.bills,
      'internet': ExpenseCategory.bills,
      'phone': ExpenseCategory.bills,
      
      // Health
      'health': ExpenseCategory.health,
      'healthcare': ExpenseCategory.health,
      'medical': ExpenseCategory.health,
      'pharmacy': ExpenseCategory.health,
      'doctor': ExpenseCategory.health,
      'hospital': ExpenseCategory.health,
      
      // Education
      'education': ExpenseCategory.education,
      'school': ExpenseCategory.education,
      'tuition': ExpenseCategory.education,
      'course': ExpenseCategory.education,
      
      // Debit
      'debit': ExpenseCategory.debit,
      'withdrawal': ExpenseCategory.debit,
      'cash': ExpenseCategory.debit,
      
      // Other
      'other': ExpenseCategory.other,
      'misc': ExpenseCategory.other,
      'miscellaneous': ExpenseCategory.other,
      'general': ExpenseCategory.other,
    };

    return aliases[normalized];
  }
}

/// Validated expense with detailed error information.
class ValidatedExpense {
  final int rowNumber;
  final String title;
  final double? amount;
  final DateTime? date;
  final ExpenseCategory? category;
  final String? merchant;
  final String? description;
  final List<String> errors;
  final Map<String, dynamic> rawData; // Original row data for reference

  ValidatedExpense({
    required this.rowNumber,
    required this.title,
    this.amount,
    this.date,
    this.category,
    this.merchant,
    this.description,
    required this.errors,
    required this.rawData,
  });

  /// Returns true if expense is valid (no errors and all required fields present).
  bool get isValid {
    return errors.isEmpty &&
        amount != null &&
        date != null &&
        category != null &&
        title.isNotEmpty;
  }

  /// Converts to API format for import.
  Map<String, dynamic> toExpenseData() {
    if (!isValid) {
      throw StateError('Cannot convert invalid expense to API format');
    }

    return {
      'title': title,
      'amount': amount!,
      'date': date!.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'category': category!.name.toLowerCase(),
      'entryMode': 'manual',
      if (merchant != null && merchant!.isNotEmpty) 'merchant': merchant,
      if (description != null && description!.isNotEmpty)
        'description': description,
    };
  }
}

