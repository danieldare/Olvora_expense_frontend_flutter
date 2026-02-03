import 'package:flutter/material.dart';
import '../../../../core/widgets/app_back_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../../../core/models/currency.dart';
import '../../domain/entities/expense_entity.dart';
import '../providers/expenses_providers.dart';
import '../../../categories/presentation/providers/category_providers.dart';
// TODO: Re-implement user profile providers
// import '../../../auth/presentation/providers/user_profile_providers.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/amount_input_field.dart';
import '../../../../core/widgets/category_selection_widget.dart';
import '../../../../core/widgets/category_modal.dart';
import '../../../../core/widgets/bottom_sheet_modal.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../budget/presentation/providers/budget_providers.dart';
import '../../../budget/domain/entities/budget_entity.dart';
import '../../../receipts/domain/models/parsed_receipt.dart';
import '../../../../core/services/notification_detection_service.dart';
import '../../../home/presentation/screens/home_screen.dart';
import 'expense_type_selection_screen.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../trips/presentation/providers/trip_expenses_providers.dart';
import '../../../trips/domain/entities/trip_entity.dart';
import '../../../report/presentation/providers/report_providers.dart';
import 'package:confetti/confetti.dart';

// Custom formatter for amount input with thousand separators
class _AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Get the cursor position in the original text
    final originalCursorPosition = newValue.selection.baseOffset;
    
    // Remove all non-digit characters except decimal point
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');

    // Allow only one decimal point
    if (digitsOnly.split('.').length > 2) {
      return oldValue;
    }

    // Limit to 2 decimal places
    if (digitsOnly.contains('.')) {
      final parts = digitsOnly.split('.');
      if (parts.length == 2 && parts[1].length > 2) {
        digitsOnly = '${parts[0]}.${parts[1].substring(0, 2)}';
      }
    }

    // Parse the number
    final number = double.tryParse(digitsOnly);
    if (number == null && digitsOnly.isNotEmpty) {
      return oldValue;
    }

    // Format with thousand separators
    String formatted;
    if (digitsOnly.isEmpty) {
      formatted = '';
    } else if (digitsOnly.contains('.')) {
      final parts = digitsOnly.split('.');
      final integerPart = int.tryParse(parts[0]) ?? 0;
      formatted = '${NumberFormat('#,##0').format(integerPart)}.${parts[1]}';
    } else {
      final integerPart = int.tryParse(digitsOnly) ?? 0;
      formatted = NumberFormat('#,##0').format(integerPart);
    }

    // Calculate correct cursor position
    // Count how many digits/decimal points are before the cursor in the original text
    int digitsBeforeCursor = 0;
    for (int i = 0; i < originalCursorPosition && i < newValue.text.length; i++) {
      final char = newValue.text[i];
      if (RegExp(r'[\d.]').hasMatch(char)) {
        digitsBeforeCursor++;
      }
    }

    // Find the position in the formatted text that corresponds to the same number of digits
    int formattedCursorPosition = 0;
    int digitsCounted = 0;
    for (int i = 0; i < formatted.length && digitsCounted < digitsBeforeCursor; i++) {
      final char = formatted[i];
      if (RegExp(r'[\d.]').hasMatch(char)) {
        digitsCounted++;
      }
      formattedCursorPosition = i + 1;
    }

    // If we're at the end, place cursor at the end
    if (digitsCounted < digitsBeforeCursor || formattedCursorPosition > formatted.length) {
      formattedCursorPosition = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formattedCursorPosition.clamp(0, formatted.length),
      ),
    );
  }

  String _formatAmount(String text) {
    if (text.isEmpty) return '';
    final digitsOnly = text.replaceAll(RegExp(r'[^\d.]'), '');
    if (digitsOnly.isEmpty) return '';

    final number = double.tryParse(digitsOnly);
    if (number == null) return text;

    if (digitsOnly.contains('.')) {
      final parts = digitsOnly.split('.');
      final integerPart = int.tryParse(parts[0]) ?? 0;
      return '${NumberFormat('#,##0').format(integerPart)}.${parts[1]}';
    } else {
      final integerPart = int.tryParse(digitsOnly) ?? 0;
      return NumberFormat('#,##0').format(integerPart);
    }
  }
}

class AddExpenseScreen extends ConsumerStatefulWidget {
  final ParsedReceipt? preFilledData;
  final EntryMode? entryMode;
  final DetectedExpense? detectedExpense;
  final String? rawNotificationText; // For immediate navigation with raw text
  final Map<String, dynamic>? extractedData; // Data from intent classification
  final ExpenseEntity? existingExpense; // For editing existing expenses
  final bool isFirstExpense; // If true, navigate to home after saving
  final String? tripId; // Pre-select a trip when adding expense

  const AddExpenseScreen({
    super.key,
    this.preFilledData,
    this.entryMode,
    this.detectedExpense,
    this.rawNotificationText,
    this.extractedData,
    this.existingExpense,
    this.isFirstExpense = false,
    this.tripId,
  });

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _merchantNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _receiptNumberController =
      TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();

  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  TripEntity? _selectedTrip;
  String? _paymentMethod;
  bool _isSubmitting = false;
  bool _showExtraInfo = false;
  List<LineItem> _lineItems = [];
  Currency? _cachedCurrency; // Cache currency to avoid repeated provider reads
  String? _detectedCurrency; // Currency detected from receipt/import (overrides preference)

  // Wizard state
  int _currentStep = 0;
  final int _totalSteps = 3;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // Defer all non-critical operations to post-frame to ensure instant navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Pre-select trip if tripId is provided
      if (widget.tripId != null) {
        _initializeTripFromId(widget.tripId!);
      } else {
        // Auto-select active trip if available (only if not editing existing expense)
        if (widget.existingExpense == null) {
          _initializeActiveTrip();
        }
      }

      // Pre-fill from existing expense if editing
      if (widget.existingExpense != null) {
        _preFillFromExistingExpense(widget.existingExpense!);
      }
      // Pre-fill data from scanned receipt if available
      else if (widget.preFilledData != null) {
        _preFillFromReceipt(widget.preFilledData!);
      }
      // Pre-fill data from detected expense (notification) if available
      if (widget.detectedExpense != null) {
        _preFillFromDetectedExpense(widget.detectedExpense!);
      }
      // Process raw notification text asynchronously (for immediate navigation)
      if (widget.rawNotificationText != null &&
          widget.detectedExpense == null) {
        _processRawNotificationText(widget.rawNotificationText!);
      }
      // Pre-fill from extracted data if available
      if (widget.extractedData != null) {
        _preFillFromExtractedData(widget.extractedData!);
      }
    });
  }

  void _preFillFromExistingExpense(ExpenseEntity expense) {
    setState(() {
      _amountController.text = expense.amount.toStringAsFixed(2);
      _noteController.text = expense.description ?? expense.title;
      _merchantNameController.text = expense.merchant ?? '';
      _selectedDate = expense.date;
      _lineItems = expense.lineItems ?? [];

      // Try to set category - will be properly set after categories load
      _matchCategoryByName(expense.category.name);
    });
  }

  void _matchCategoryByName(String categoryName) {
    // This will be called after categories are loaded
    final categoriesAsync = ref.read(categoriesProvider);
    categoriesAsync.whenData((categories) {
      final normalizedName = categoryName.toLowerCase();
      for (final category in categories) {
        if (category.name.toLowerCase() == normalizedName ||
            category.name.toLowerCase().contains(normalizedName) ||
            normalizedName.contains(category.name.toLowerCase())) {
          if (mounted) {
            setState(() {
              _selectedCategory = category;
            });
          }
          break;
        }
      }
    });
  }

  void _preFillFromExtractedData(Map<String, dynamic> data) {
    if (data['amount'] != null) {
      _amountController.text = data['amount'].toString();
    }
    if (data['description'] != null || data['note'] != null) {
      _noteController.text = (data['description'] ?? data['note']).toString();
    }
    if (data['date'] != null) {
      try {
        _selectedDate = DateTime.parse(data['date'].toString());
      } catch (e) {
        // Ignore parse errors
      }
    }
    if (data['merchant'] != null) {
      _merchantNameController.text = data['merchant'].toString();
    }
  }

  /// Process raw notification text asynchronously in the background
  /// This allows immediate navigation while processing happens in parallel
  Future<void> _processRawNotificationText(String rawText) async {
    if (!mounted) return;

    // Process in background (non-blocking)
    try {
      final detectionService = NotificationDetectionService();

      // Parse the notification text
      final detected = detectionService.parseNotification(
        'Clipboard',
        rawText,
        packageName: 'clipboard',
      );

      if (detected != null && mounted) {
        // Pre-fill with detected data
        _preFillFromDetectedExpense(detected);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error processing raw notification text: $e');
      }
    } finally {}
  }

  void _preFillFromReceipt(ParsedReceipt receipt) {
    // Pre-fill amount
    if (receipt.totalAmount != null) {
      _amountController.text = receipt.totalAmount!.toStringAsFixed(2);
    }

    // Pre-fill date
    if (receipt.date != null) {
      _selectedDate = receipt.date!;
    }

    // Pre-fill merchant name
    if (receipt.merchant != null) {
      _merchantNameController.text = receipt.merchant!;
    }

    // Pre-fill line items
    if (receipt.lineItems != null && receipt.lineItems!.isNotEmpty) {
      _lineItems = receipt.lineItems!;
    }

    // Pre-fill note (which may contain narration and remark from backend)
    if (receipt.description != null && receipt.description!.isNotEmpty) {
      _noteController.text = receipt.description!;
    }

    // Store detected currency from receipt (if available)
    if (receipt.currency != null && receipt.currency!.isNotEmpty) {
      setState(() {
        _detectedCurrency = receipt.currency;
      });
    }

    // Note: We don't pre-fill notes with rawText because it contains all receipt content.
    // The notes field should only contain user-entered notes, not structured data.
    // All important information (merchant, amount, line items, address, description with narration/remark, etc.) is already
    // captured in their respective fields.

    // Pre-fill extra information
    if (receipt.address != null) {
      _addressController.text = receipt.address!;
      _showExtraInfo = true; // Show extra info if any field is pre-filled
    }
    if (receipt.receiptNumber != null) {
      _receiptNumberController.text = receipt.receiptNumber!;
      _showExtraInfo = true;
    }
    if (receipt.telephone != null) {
      _telephoneController.text = receipt.telephone!;
      _showExtraInfo = true;
    }

    // Try to match suggested category (will be done after first build)
    if (receipt.suggestedCategory != null) {
      // Use microtask to ensure it runs after the current frame
      Future.microtask(() {
        if (mounted) {
          _matchCategoryFromReceipt(receipt.suggestedCategory!);
        }
      });
    }
  }

  void _preFillFromDetectedExpense(DetectedExpense detectedExpense) {
    // Pre-fill amount
    final amount = detectedExpense.amount;
    _amountController.text = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);

    // Pre-fill date
    _selectedDate = detectedExpense.timestamp;

    // Pre-fill merchant name
    if (detectedExpense.merchant != null &&
        detectedExpense.merchant!.isNotEmpty) {
      _merchantNameController.text = detectedExpense.merchant!;
    }

    // Pre-fill note (if available)
    if (detectedExpense.description != null &&
        detectedExpense.description!.isNotEmpty) {
      _noteController.text = detectedExpense.description!;
    }

    // Auto-select debit category if available
    _tryAutoSelectDebitCategory();
  }

  Future<void> _tryAutoSelectDebitCategory() async {
    try {
      final categoriesAsync = ref.read(categoriesProvider);
      final categories = categoriesAsync.when(
        data: (data) => data,
        loading: () => <CategoryModel>[],
        error: (_, __) => <CategoryModel>[],
      );

      if (categories.isEmpty || !mounted) return;

      // Try to find a debit category
      CategoryModel? selectedCategory;

      try {
        selectedCategory = categories.firstWhere(
          (cat) => cat.name.toLowerCase().contains('debit'),
        );
      } catch (e) {
        // No debit category found, try "other"
        try {
          selectedCategory = categories.firstWhere(
            (cat) => cat.name.toLowerCase() == 'other',
          );
        } catch (e2) {
          // No "other" category, use first available
          selectedCategory = categories.first;
        }
      }

      if (mounted) {
        setState(() {
          _selectedCategory = selectedCategory;
        });
      }
    } catch (e) {
      // Silently fail - user can select manually
    }
  }

  Future<void> _matchCategoryFromReceipt(String suggestedCategory) async {
    if (!mounted) return;

    // Defer to next frame to avoid blocking
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    try {
      final categoriesAsync = ref.read(categoriesProvider);
      final categories = await categoriesAsync.when(
        data: (data) => Future.value(data),
        loading: () => Future.value(<CategoryModel>[]),
        error: (_, __) => Future.value(<CategoryModel>[]),
      );

      if (categories.isEmpty || !mounted) return;

      final lowerSuggested = suggestedCategory.toLowerCase();

      // Try to find matching category
      CategoryModel? matchedCategory;

      for (final category in categories) {
        final categoryName = category.name.toLowerCase();
        if (categoryName.contains(lowerSuggested) ||
            lowerSuggested.contains(categoryName)) {
          matchedCategory = category;
          break;
        }
      }

      // If no exact match, try common mappings
      if (matchedCategory == null) {
        final categoryMappings = {
          'food': ['food', 'restaurant', 'grocery', 'dining'],
          'transport': ['transport', 'car', 'travel', 'taxi', 'uber'],
          'shopping': ['shopping', 'store', 'retail'],
          'bills': ['bill', 'utility', 'electricity', 'water'],
          'health': ['health', 'medical', 'pharmacy', 'hospital'],
          'entertainment': ['entertainment', 'movie', 'game', 'cinema'],
          'education': ['education', 'school', 'book', 'course'],
        };

        for (final entry in categoryMappings.entries) {
          if (entry.value.any((keyword) => lowerSuggested.contains(keyword))) {
            try {
              matchedCategory = categories.firstWhere(
                (cat) => cat.name.toLowerCase().contains(entry.key),
              );
            } catch (e) {
              matchedCategory = categories.isNotEmpty ? categories.first : null;
            }
            break;
          }
        }
      }

      if (matchedCategory != null && mounted) {
        setState(() {
          _selectedCategory = matchedCategory;
        });
      }
    } catch (e) {
      // Silently fail - user can select manually
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _merchantNameController.dispose();
    _addressController.dispose();
    _receiptNumberController.dispose();
    _telephoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < _totalSteps - 1) {
        setState(() {
          _currentStep++;
          _animationController.reset();
          _animationController.forward();
        });
      } else {
        _submitExpense();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Amount & Category
        final amount = _parseAmount(_amountController.text);
        if (amount == null || amount <= 0) {
          _showError('Please enter a valid amount');
          return false;
        }
        if (_selectedCategory == null) {
          _showError('Please select a category');
          return false;
        }
        return true;
      case 1: // Date & Payment
        return true; // Date is always set
      case 2: // Additional Details
        return true; // Optional step
      case 3: // Line Items
        return true; // Optional step
      case 4: // Review
        return true;
      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  ExpenseCategory _mapCategoryToExpenseCategory(CategoryModel category) {
    // Map category name to ExpenseCategory enum
    final name = category.name.toLowerCase();
    if (name.contains('food') ||
        name.contains('restaurant') ||
        name.contains('grocery')) {
      return ExpenseCategory.food;
    } else if (name.contains('transport') ||
        name.contains('car') ||
        name.contains('travel')) {
      return ExpenseCategory.transport;
    } else if (name.contains('entertainment') ||
        name.contains('movie') ||
        name.contains('game')) {
      return ExpenseCategory.entertainment;
    } else if (name.contains('shopping') || name.contains('store')) {
      return ExpenseCategory.shopping;
    } else if (name.contains('bill') ||
        name.contains('utility') ||
        name.contains('electricity')) {
      return ExpenseCategory.bills;
    } else if (name.contains('health') ||
        name.contains('medical') ||
        name.contains('hospital')) {
      return ExpenseCategory.health;
    } else if (name.contains('education') ||
        name.contains('school') ||
        name.contains('book')) {
      return ExpenseCategory.education;
    } else if (name.contains('debit')) {
      return ExpenseCategory.debit;
    }
    return ExpenseCategory.other;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.warningColor,
              onPrimary: Colors.black,
              surface: const Color(0xFF111827),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _initializeTripFromId(String tripId) async {
    final activeTripAsync = ref.read(activeTripProvider);
    await activeTripAsync.when(
      data: (activeTrip) {
        if (activeTrip != null && activeTrip.id == tripId && mounted) {
          setState(() {
            _selectedTrip = activeTrip;
          });
        }
      },
      loading: () {},
      error: (error, stack) {},
    );
  }

  /// Initialize with the active trip if available
  Future<void> _initializeActiveTrip() async {
    final activeTripAsync = ref.read(activeTripProvider);
    await activeTripAsync.when(
      data: (activeTrip) {
        // Auto-select the active trip if available
        if (activeTrip != null && mounted) {
          setState(() {
            _selectedTrip = activeTrip;
          });
        }
      },
      loading: () {},
      error: (error, stack) {},
    );
  }

  Future<void> _selectTrip(BuildContext context) async {
    // Get all trips (not just active) for selection
    final tripsAsync = ref.read(tripsProvider(null));

    await tripsAsync.when(
      data: (trips) async {
        final tripOptions = ['None', ...trips.map((t) => t.name)];
        final selected = await BottomSheetModal.show<String>(
          context: context,
          title: 'Select Trip / Group',
          subtitle: 'Link this expense to a trip (optional)',
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tripOptions.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppTheme.borderColor.withValues(alpha: 0.3),
            ),
            itemBuilder: (context, index) {
              final option = tripOptions[index];
              final isSelected =
                  (option == 'None' && _selectedTrip == null) ||
                  (option != 'None' && _selectedTrip?.name == option);

              return InkWell(
                onTap: () {
                  Navigator.pop(context, option);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.primaryColor.withValues(alpha: 0.15)
                              : AppTheme.primaryColor.withValues(alpha: 0.08))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        option == 'None'
                            ? Icons.close_rounded
                            : Icons.luggage_rounded,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppTheme.textPrimary,
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          option,
                          style: AppFonts.textStyle(
                            fontSize: 14.scaledText(context),
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );

        if (selected != null && mounted) {
          setState(() {
            if (selected == 'None') {
              _selectedTrip = null;
            } else {
              _selectedTrip = trips.firstWhere((t) => t.name == selected);
            }
          });
        }
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Loading trips...'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      },
      error: (error, stack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load trips: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      },
    );
  }

  Future<void> _selectPaymentMethod(BuildContext context) async {
    final methods = ['Card', 'Cash', 'Bank Transfer', 'Digital Wallet'];
    final selected = await BottomSheetModal.show<String>(
      context: context,
      showHandle: false,
      showCloseButton: false,
      borderRadius: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: methods.map((method) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return ListTile(
            dense: true,
            title: Text(
              method,
              style: AppFonts.textStyle(
                fontSize: 14.scaledText(context),
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            onTap: () => Navigator.pop(context, method),
          );
        }).toList(),
      ),
    );
    if (selected != null) {
      setState(() {
        _paymentMethod = selected;
      });
    }
  }

  double? _parseAmount(String value) {
    if (value.isEmpty) return null;
    // Remove currency symbols and spaces
    final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned);
  }

  Future<void> _submitExpense() async {
    final amount = _parseAmount(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid amount'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a category'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiService = ref.read(apiServiceV2Provider);

      final expenseCategory = _mapCategoryToExpenseCategory(_selectedCategory!);

      // Prepare line items for backend
      List<Map<String, dynamic>>? lineItemsData;
      if (_lineItems.isNotEmpty) {
        lineItemsData = _lineItems
            .map(
              (item) => {
                'description': item.description,
                'amount': item.amount,
                if (item.quantity != null) 'quantity': item.quantity,
              },
            )
            .toList();
      }

      // Calculate total amount (use line items total if available, otherwise use main amount)
      double totalAmount = amount;
      if (_lineItems.isNotEmpty) {
        totalAmount = _lineItems.fold<double>(
          0.0,
          (sum, item) => sum + (item.amount * (item.quantity ?? 1)),
        );
      }

      // Determine entry mode - use provided entryMode, or default based on data source
      final entryMode =
          widget.entryMode ??
          (widget.detectedExpense != null
              ? EntryMode.notification
              : EntryMode.manual);

      // Build description with note and extra information if available
      String? description;

      // Start with note if available
      if (_noteController.text.isNotEmpty) {
        description = _noteController.text.trim();
      }

      // Append extra information to description if available
      final extraInfoParts = <String>[];
      if (_addressController.text.isNotEmpty) {
        extraInfoParts.add('Address: ${_addressController.text}');
      }
      if (_receiptNumberController.text.isNotEmpty) {
        extraInfoParts.add('Receipt #: ${_receiptNumberController.text}');
      }
      if (_telephoneController.text.isNotEmpty) {
        extraInfoParts.add('Tel: ${_telephoneController.text}');
      }

      if (extraInfoParts.isNotEmpty) {
        final extraInfo = extraInfoParts.join(' • ');
        description = description != null
            ? '$description\n\n$extraInfo'
            : extraInfo;
      }

      // Determine currency: use detected currency if available (from receipt/import),
      // otherwise use user preference currency
      final preferenceCurrency = _getCachedCurrency(ref);
      final currencyCode = _detectedCurrency ?? preferenceCurrency.code;

      final expenseData = {
        'title': _selectedCategory!.name,
        'amount': totalAmount,
        'category': expenseCategory.name.toLowerCase(),
        'date': _selectedDate.toIso8601String().split('T')[0],
        'entryMode': entryMode.name,
        'currency': currencyCode, // Use detected currency or user preference
        if (description != null && description.isNotEmpty)
          'description': description,
        if (_merchantNameController.text.isNotEmpty)
          'merchant': _merchantNameController.text.trim(),
        if (lineItemsData != null && lineItemsData.isNotEmpty)
          'lineItems': lineItemsData,
        if (_selectedTrip != null) 'tripId': _selectedTrip!.id,
      };

      // Check if this is the first expense (before create) for celebration
      final isEditing = widget.existingExpense != null;
      bool wasFirstExpense = false;
      if (!isEditing) {
        try {
          final previousList = await ref.read(expensesProvider.future);
          wasFirstExpense = previousList.isEmpty;
        } catch (_) {
          wasFirstExpense = false;
        }
      }

      // Update or create expense
      if (isEditing) {
        await apiService.dio.patch(
          '/expenses/${widget.existingExpense!.id}',
          data: expenseData,
        );
      } else {
        await apiService.dio.post('/expenses', data: expenseData);
      }

      // Invalidate expenses providers to refresh the lists
      ref.invalidate(expensesProvider);
      ref.invalidate(recentTransactionsProvider);

      // Invalidate report providers so report screen shows new data
      ref.invalidate(
        spendingOverviewProvider(
          const ReportDateRangeParams(period: ReportPeriod.allTime),
        ),
      );
      ref.invalidate(
        spendingOverviewProvider(
          const ReportDateRangeParams(period: ReportPeriod.month),
        ),
      );
      ref.invalidate(
        categoryBreakdownProvider(
          const ReportDateRangeParams(period: ReportPeriod.allTime),
        ),
      );
      ref.invalidate(
        categoryBreakdownProvider(
          const ReportDateRangeParams(period: ReportPeriod.month),
        ),
      );
      ref.invalidate(monthlyComparisonProvider);

      // Invalidate trip-related providers if expense is linked to a trip
      if (_selectedTrip != null) {
        ref.invalidate(tripExpensesProvider(_selectedTrip!.id));
        ref.invalidate(tripProvider(_selectedTrip!.id));
        // Also invalidate active trip provider if this is the active trip
        ref.invalidate(activeTripProvider);
      }

      if (mounted) {
        if (wasFirstExpense) {
          // Show congratulations + confetti, then navigate
          await _showFirstExpenseCelebration(context);
          if (!context.mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Expense added successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          // If came from a scanned receipt, navigate to home screen
          if (widget.isFirstExpense || entryMode == EntryMode.scan) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          } else {
            Navigator.pop(context);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? 'Expense updated successfully'
                    : 'Expense added successfully',
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to add expense';
        try {
          // Try to extract error message from response
          if (e.toString().contains('response')) {
            errorMessage = 'Failed to add expense. Please try again.';
          } else {
            errorMessage = 'Failed to add expense: ${e.toString()}';
          }
        } catch (_) {
          errorMessage = 'Failed to add expense. Please try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _showFirstExpenseCelebration(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FirstExpenseCelebrationDialog(),
    );
  }

  Currency _getCachedCurrency(WidgetRef ref) {
    if (_cachedCurrency != null) return _cachedCurrency!;
    try {
      final selectedCurrencyAsync = ref.read(selectedCurrencyProvider);
      _cachedCurrency =
          selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;
      return _cachedCurrency!;
    } catch (e) {
      return Currency.defaultCurrency;
    }
  }

  /// Check if there's unsaved data in the form
  bool _hasUnsavedData() {
    // Check if any field has been filled
    return _amountController.text.trim().isNotEmpty ||
        _noteController.text.trim().isNotEmpty ||
        _merchantNameController.text.trim().isNotEmpty ||
        _addressController.text.trim().isNotEmpty ||
        _receiptNumberController.text.trim().isNotEmpty ||
        _telephoneController.text.trim().isNotEmpty ||
        _selectedCategory != null ||
        _lineItems.isNotEmpty;
  }

  /// Show exit confirmation modal
  void _showExitConfirmation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20.scaled(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: AppTheme.warningColor,
                      size: 22.scaled(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Discard expense?',
                        style: AppFonts.textStyle(
                          fontSize: 16.scaledText(context),
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.scaledVertical(context)),
                Text(
                  'You have an expense in progress. Are you sure you want to leave?',
                  style: AppFonts.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 16.scaledVertical(context)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Keep editing',
                        style: AppFonts.textStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate back to expense type selector
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ExpenseTypeSelectionScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Discard',
                        style: AppFonts.textStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_hasUnsavedData(),
      onPopInvoked: (didPop) {
        if (!didPop && _hasUnsavedData()) {
          _showExitConfirmation();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: AppBackButton(
            onPressed: () {
              if (_hasUnsavedData()) {
                _showExitConfirmation();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            'Add Expense',
            style: AppFonts.textStyle(
              fontSize: 17.scaledText(context),
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Progress Indicator
              _buildProgressIndicator(isDark),

              // Step Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(AppSpacing.screenHorizontal),
                    child: _buildStepContent(isDark),
                  ),
                ),
              ),

              // Navigation Buttons
              _buildNavigationButtons(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: 10.scaledVertical(context),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              final isActive = index <= _currentStep;
              final isCurrent = index == _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primaryColor
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : AppTheme.borderColor),
                          borderRadius: BorderRadius.circular(2.scaled(context)),
                        ),
                      ),
                    ),
                    if (index < _totalSteps - 1)
                      Container(
                        width: 6,
                        height: 6,
                        margin: EdgeInsets.symmetric(horizontal: 3.scaled(context)),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? AppTheme.primaryColor
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : AppTheme.borderColor),
                          border: isCurrent
                              ? Border.all(
                                  color: AppTheme.primaryColor,
                                  width: 2,
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          SizedBox(height: 8.scaledVertical(context)),
          Text(
            _getStepTitle(_currentStep),
            style: AppFonts.textStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 2),
          Text(
            _getStepSubtitle(_currentStep),
            style: AppFonts.textStyle(
              fontSize: 13.scaledText(context),
              fontWeight: FontWeight.w400,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Amount & Category';
      case 1:
        return 'Details';
      case 2:
        return 'Review & Confirm';
      default:
        return '';
    }
  }

  String _getStepSubtitle(int step) {
    switch (step) {
      case 0:
        return 'Enter the amount and categorize your expense';
      case 1:
        return 'Date, payment method, and additional info (optional)';
      case 2:
        return 'Review your expense details';
      default:
        return '';
    }
  }

  Widget _buildStepContent(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildStep1AmountAndCategory(isDark);
      case 1:
        return _buildStep2Details(isDark);
      case 2:
        return _buildStep3Review(isDark);
      default:
        return SizedBox();
    }
  }

  Widget _buildStep1AmountAndCategory(bool isDark) {
    final currency = _getCachedCurrency(ref);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Amount Section
        AmountInputField(
          controller: _amountController,
          placeholder: '0.00',
          label: 'Amount',
          fontSize: 30.scaledText(context),
          // textColor will default to proper contrast based on theme
          onChanged: (_) => setState(() {}),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        SizedBox(height: 16),
        // Monthly Budget Section
        _buildMonthlyBudgetInfoLazy(ref, currency, isDark),
        SizedBox(height: 20.scaledVertical(context)),
        // Category Selection
        Text(
          'Category',
          style: AppFonts.textStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : AppTheme.textSecondary,
          ),
        ),
        SizedBox(height: 8.scaledVertical(context)),
        _buildCategorySelectionLazy(),
      ],
    );
  }

  Widget _buildStep2Details(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date and Payment Method
        _buildInputField(
          icon: Icons.calendar_today_rounded,
          label: 'Date',
          value: DateFormat('MMM d, y').format(_selectedDate),
          onTap: () => _selectDate(context),
        ),
        SizedBox(height: 10.scaledVertical(context)),
        _buildInputField(
          icon: Icons.credit_card_rounded,
          label: 'Payment Method',
          value: _paymentMethod ?? 'Card',
          onTap: () => _selectPaymentMethod(context),
        ),
        SizedBox(height: 10.scaledVertical(context)),
        _buildInputField(
          icon: Icons.luggage_rounded,
          label: 'Trip / Group',
          value: _selectedTrip?.name ?? 'None',
          onTap: () => _selectTrip(context),
        ),
        SizedBox(height: 16),
        // Optional fields section
        Text(
          'Additional Information (Optional)',
          style: AppFonts.textStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : AppTheme.textSecondary,
          ),
        ),
        SizedBox(height: 10.scaledVertical(context)),
        // Merchant Name
        AppTextField(
          controller: _merchantNameController,
          label: 'Merchant Name',
          hintText: 'e.g., Amazon, Starbucks',
          prefixIcon: Icon(
            Icons.store_rounded,
            size: 18,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : AppTheme.textSecondary,
          ),
        ),
        SizedBox(height: 10.scaledVertical(context)),
        // Note
        AppTextField(
          controller: _noteController,
          label: 'Note',
          hintText: 'Add a note (optional)',
          maxLines: 3,
          prefixIcon: Icon(
            Icons.note_rounded,
            size: 18,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : AppTheme.textSecondary,
          ),
        ),
        SizedBox(height: 10.scaledVertical(context)),
        // Add More Information Button
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showExtraInfo = !_showExtraInfo;
              });
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12.scaled(context),
                vertical: 8.scaledVertical(context),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppTheme.textSecondary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Other Information',
                    style: AppFonts.textStyle(
                      fontSize: 13.scaledText(context),
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    _showExtraInfo
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Extra Information Fields
        if (_showExtraInfo) ...[
          SizedBox(height: 10.scaledVertical(context)),
          _buildExtraInfoFields(isDark),
        ],
      ],
    );
  }

  Widget _buildStep3Review(bool isDark) {
    final currency = _getCachedCurrency(ref);
    final amount = _parseAmount(_amountController.text) ?? 0.0;
    final totalAmount = _lineItems.isNotEmpty
        ? _lineItems.fold<double>(
            0.0,
            (sum, item) => sum + (item.amount * (item.quantity ?? 1)),
          )
        : amount;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final secondaryColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppTheme.textSecondary;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF111827), const Color(0xFF1E293B)]
                : [Colors.white, const Color(0xFFF9FAFB)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Receipt rows with dashed dividers
            _buildReceiptRow('Category', _selectedCategory?.name ?? '—', isDark),
            _buildReceiptDivider(isDark),
            _buildReceiptRow('Date', DateFormat('MMM d, y').format(_selectedDate), isDark),
            _buildReceiptDivider(isDark),
            _buildReceiptRow('Payment', _paymentMethod ?? 'Card', isDark),
            if (_merchantNameController.text.isNotEmpty) ...[
              _buildReceiptDivider(isDark),
              _buildReceiptRow('Merchant', _merchantNameController.text.trim(), isDark),
            ],
            if (_noteController.text.isNotEmpty) ...[
              _buildReceiptDivider(isDark),
              _buildReceiptRow('Note', _noteController.text.trim(), isDark),
            ],
            if (_lineItems.isNotEmpty) ...[
              _buildReceiptDivider(isDark),
              SizedBox(height: 12),
              Text(
                'ITEMS',
                style: AppFonts.textStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: 8),
              ..._lineItems.asMap().entries.map((entry) {
                final item = entry.value;
                final lineTotal = item.amount * (item.quantity ?? 1);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.description,
                          style: AppFonts.textStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (item.quantity != null && item.quantity! > 1)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${item.quantity}x',
                            style: AppFonts.textStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: secondaryColor,
                            ),
                          ),
                        ),
                      Text(
                        CurrencyFormatter.format(lineTotal, currency),
                        style: AppFonts.textStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              SizedBox(height: 12),
            ],
            // Total line (receipt style)
            _buildReceiptDivider(isDark),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL',
                  style: AppFonts.textStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: secondaryColor,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(totalAmount, currency),
                  style: AppFonts.textStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, bool isDark) {
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final secondaryColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppTheme.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: AppFonts.textStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: secondaryColor,
              letterSpacing: 0.6,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptDivider(bool isDark) {
    final color = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : AppTheme.borderColor.withValues(alpha: 0.9);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: CustomPaint(
        size: const Size(double.infinity, 1),
        painter: _DashedLinePainter(color: color),
      ),
    );
  }

  Widget _buildNavigationButtons(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            IconButton(
              onPressed: _isSubmitting ? null : _previousStep,
              icon: Icon(
                Icons.chevron_left,
                color: isDark ? Colors.white : AppTheme.textPrimary,
                size: 18.scaled(context),
              ),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppTheme.borderColor,
                ),
              ),
            ),
            SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                disabledBackgroundColor: AppTheme.primaryColor.withValues(
                  alpha: 0.5,
                ),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentStep == _totalSteps - 1
                          ? 'Add Expense'
                          : 'Continue',
                      style: AppFonts.textStyle(
                        fontSize: 15.scaledText(context),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBudgetInfoLazy(
    WidgetRef ref,
    Currency currency,
    bool isDark,
  ) {
    // Use FutureBuilder to load budget info asynchronously without blocking navigation
    return FutureBuilder<BudgetEntity?>(
      future: _getMonthlyBudgetAsync(ref),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final monthlyBudget = snapshot.data!;
        if (monthlyBudget.amount == 0) {
          return const SizedBox.shrink();
        }

        return Center(
          child: Text(
            'Monthly Budget: ${CurrencyFormatter.format(monthlyBudget.amount, currency)}',
            style: AppFonts.textStyle(
              fontSize: 13.scaledText(context),
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppTheme.textSecondary,
            ),
          ),
        );
      },
    );
  }

  Future<BudgetEntity?> _getMonthlyBudgetAsync(WidgetRef ref) async {
    try {
      final generalBudgetsAsync = ref.read(generalBudgetsProvider);
      final budgets = await generalBudgetsAsync.when(
        data: (data) => Future.value(data),
        loading: () => Future.value(<BudgetEntity>[]),
        error: (_, __) => Future.value(<BudgetEntity>[]),
      );

      if (budgets.isEmpty) return null;

      final monthlyBudget = budgets.firstWhere(
        (b) => b.type == BudgetType.monthly && b.amount > 0,
        orElse: () => BudgetEntity(
          id: '',
          type: BudgetType.monthly,
          category: BudgetCategory.general,
          amount: 0,
          spent: 0,
          enabled: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      return monthlyBudget.amount > 0 ? monthlyBudget : null;
    } catch (e) {
      return null;
    }
  }

  Widget _buildCategorySelectionLazy() {
    // Pre-warm the categories provider to avoid blocking
    // This ensures categories are loaded in the background
    ref.read(categoriesProvider);

    // Render immediately - CategorySelectionWidget handles loading state internally
    return CategorySelectionWidget(
      selectedCategory: _selectedCategory,
      onCategorySelected: (category) {
        setState(() {
          _selectedCategory = category;
        });
      },
      onAddCategory: () {
        showCategoryModal(
          context: context,
          onCategoryCreated: (newCategory) {
            setState(() {
              _selectedCategory = newCategory;
            });
          },
        );
      },
      showAddButton: true,
      showNoneOption: false,
      selectedColor: AppTheme.warningColor,
    );
  }

  Widget _buildLineItemRow(
    LineItem item,
    Currency currency,
    bool isDark,
    Color cardColor,
    int index,
    bool isLast,
  ) {
    final totalAmount = item.amount * (item.quantity ?? 1);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Item number or icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: AppFonts.textStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      style: AppFonts.textStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    if (item.quantity != null && item.quantity! > 1) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${item.quantity}x ',
                            style: AppFonts.textStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(item.amount, currency),
                            style: AppFonts.textStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(item.amount, currency),
                        style: AppFonts.textStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Total amount
              Text(
                CurrencyFormatter.format(totalAmount, currency),
                style: AppFonts.textStyle(
                  fontSize: 16.scaledText(context),
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              SizedBox(width: 8),
              // Edit/Delete buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _showAddLineItemDialog(
                      context,
                      currency,
                      item,
                      index: index,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _lineItems.removeAt(index);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppTheme.errorColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.borderColor,
            indent: 60,
            endIndent: 16,
          ),
      ],
    );
  }

  Future<void> _showAddLineItemDialog(
    BuildContext context,
    Currency currency,
    LineItem? existingItem, {
    int? index,
  }) async {
    final descriptionController = TextEditingController(
      text: existingItem?.description ?? '',
    );
    final amountController = TextEditingController(
      text: existingItem?.amount.toString() ?? '0.0',
    );
    int quantityValue = existingItem?.quantity ?? 1;

    await BottomSheetModal.show(
      context: context,
      title: existingItem == null ? 'Add Item' : 'Edit Item',
      subtitle: existingItem == null
          ? 'Add items you purchased'
          : 'Update item details',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final formKey = GlobalKey<FormState>();
          return Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Amount Display (Inline)
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Amount',
                        style: AppFonts.textStyle(
                          fontSize: 12.scaledText(context),
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.6)
                              : AppTheme.textSecondary,
                        ),
                      ),
                      SizedBox(height: 6),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Display text - shown when TextField is empty or has default value
                          // Use proper contrast: dark on light, light on dark
                          if (amountController.text.isEmpty ||
                              amountController.text == '0.0')
                            Text(
                              '${currency.symbol}0.0',
                              style: AppFonts.textStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: isDark 
                                    ? Colors.white.withValues(alpha: 0.95)
                                    : AppTheme.textPrimary.withValues(alpha: 0.95),
                                letterSpacing: -0.8,
                              ),
                            ),
                          // TextField with currency symbol inline
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                currency.symbol,
                                style: AppFonts.textStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: isDark 
                                      ? Colors.white.withValues(alpha: 0.95)
                                      : AppTheme.textPrimary.withValues(alpha: 0.95),
                                  letterSpacing: -0.8,
                                ),
                              ),
                              SizedBox(width: 2),
                              IntrinsicWidth(
                                child: TextField(
                                  controller: amountController,
                                  autofocus: true,
                                  textAlign: TextAlign.left,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [_AmountInputFormatter()],
                                  onChanged: (_) => setModalState(() {}),
                                  style: AppFonts.textStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: isDark 
                                        ? Colors.white.withValues(alpha: 0.95)
                                        : AppTheme.textPrimary.withValues(alpha: 0.95),
                                    letterSpacing: -0.8,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                // Item Name (Full Width)
                AppTextField(
                  controller: descriptionController,
                  label: 'Item Name',
                  hintText: 'Enter item name',
                  useDarkStyle: isDark,
                  autofocus: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter item name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                // Quantity Slider
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quantity',
                          style: AppFonts.textStyle(
                            fontSize: 12.scaledText(context),
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          quantityValue.toString(),
                          style: AppFonts.textStyle(
                            fontSize: 14.scaledText(context),
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.scaledVertical(context)),
                    Slider(
                      value: quantityValue.toDouble(),
                      min: 1,
                      max: 100,
                      divisions: 99,
                      activeColor: AppTheme.primaryColor,
                      inactiveColor: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppTheme.borderColor,
                      onChanged: (value) {
                        setModalState(() {
                          quantityValue = value.toInt();
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Action Button (Single button, no cancel)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      final description = descriptionController.text.trim();
                      // Remove thousand separators for parsing
                      final amountText = amountController.text
                          .replaceAll(',', '')
                          .trim();
                      final amount = double.tryParse(amountText);

                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Please enter a valid amount'),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                        return;
                      }

                      final lineItem = LineItem(
                        description: description,
                        amount: amount,
                        quantity: quantityValue > 1 ? quantityValue : null,
                      );

                      if (existingItem != null && index != null) {
                        setState(() {
                          _lineItems[index] = lineItem;
                        });
                      } else {
                        setState(() {
                          _lineItems.add(lineItem);
                        });
                      }

                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      elevation: 8,
                      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 18),
                        SizedBox(width: 6),
                        Text(
                          existingItem == null ? 'Add Item' : 'Save',
                          style: AppFonts.textStyle(
                            fontSize: 14.scaledText(context),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isPlaceholder = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use same background color logic as AppTextField
    // In light mode: soft slate-grey for clean, modern look
    // In dark mode: slightly lighter than card background
    final baseCardColor = isDark
        ? AppTheme.darkCardBackground
        : AppTheme.cardBackground;
    final backgroundColor = isDark
        ? Color.lerp(baseCardColor, Colors.white, 0.08) ?? baseCardColor
        : const Color(0xFFE2E8F0); // Soft slate-200 - clean and complementary

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppTheme.borderColor.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18.scaled(context),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : AppTheme.textSecondary,
            ),
            SizedBox(width: 10),
            Text(
              label,
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Expanded(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.right,
                style: AppFonts.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPlaceholder
                      ? (isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : AppTheme.textSecondary.withValues(alpha: 0.6))
                      : (isDark ? Colors.white : AppTheme.textPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraInfoFields(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address Field
        AppTextField(
          controller: _addressController,
          label: 'Merchant address',
          hintText: 'Enter merchant address',
          keyboardType: TextInputType.streetAddress,
          textInputAction: TextInputAction.next,
          prefixIcon: Icon(
            Icons.location_on_rounded,
            size: 18,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : AppTheme.textSecondary,
          ),
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 10.scaledVertical(context)),
        // Receipt Number Field
        AppTextField(
          controller: _receiptNumberController,
          label: 'Receipt number',
          hintText: 'Enter receipt number',
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          prefixIcon: Icon(
            Icons.receipt_long_rounded,
            size: 18,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : AppTheme.textSecondary,
          ),
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 10.scaledVertical(context)),
        // Telephone Field
        AppTextField(
          controller: _telephoneController,
          label: 'Phone number',
          hintText: 'Enter phone number',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          prefixIcon: Icon(
            Icons.phone_rounded,
            size: 18,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : AppTheme.textSecondary,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

/// Congratulations dialog with confetti when user creates their first expense.
class _FirstExpenseCelebrationDialog extends StatefulWidget {
  @override
  State<_FirstExpenseCelebrationDialog> createState() =>
      _FirstExpenseCelebrationDialogState();
}

class _FirstExpenseCelebrationDialogState
    extends State<_FirstExpenseCelebrationDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor =
        isDark ? Colors.grey[300]! : AppTheme.textSecondary;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti overlay (multiple emitters for full-screen effect)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 30,
              minBlastForce: 10,
              gravity: 0.15,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.8),
                const Color(0xFF10B981),
                const Color(0xFFF59E0B),
                const Color(0xFF6366F1),
              ],
              shouldLoop: false,
            ),
          ),
          // Dialog content
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.celebration_rounded,
                  size: 56,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 20),
                Text(
                  'Congratulations!',
                  style: AppFonts.textStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'You added your first expense.\nYour reports will now show your spending.',
                  style: AppFonts.textStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a horizontal dashed line for receipt-style dividers.
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashWidth = 4;
    const gap = 4;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
