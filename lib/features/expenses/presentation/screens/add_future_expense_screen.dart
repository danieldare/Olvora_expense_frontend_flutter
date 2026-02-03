import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../../../core/models/currency.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/amount_input_field.dart';
import '../../../../core/widgets/category_selection_widget.dart';
import '../../../../core/widgets/bottom_sheet_modal.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/selection_pill.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/future_expense_entity.dart';
import '../providers/future_expenses_providers.dart';
import '../providers/expenses_providers.dart';
// TODO: Re-implement user profile providers
// import '../../../auth/presentation/providers/user_profile_providers.dart';
import '../../../home/presentation/screens/home_screen.dart';
import 'expense_type_selection_screen.dart';

class AddFutureExpenseScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? extractedData;
  final FutureExpenseEntity? existingExpense;
  final bool isFirstExpense; // If true, navigate to home after saving

  const AddFutureExpenseScreen({
    super.key,
    this.extractedData,
    this.existingExpense,
    this.isFirstExpense = false,
  });

  @override
  ConsumerState<AddFutureExpenseScreen> createState() =>
      _AddFutureExpenseScreenState();
}

class _AddFutureExpenseScreenState extends ConsumerState<AddFutureExpenseScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _expectedAmountController =
      TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // State
  CategoryModel? _selectedCategory;
  AmountCertainty _amountCertainty = AmountCertainty.estimate;
  FutureExpensePriority _priority = FutureExpensePriority.medium;
  DateFlexibility _dateFlexibility = DateFlexibility.flexible;
  DateTime _expectedDate = DateTime.now().add(const Duration(days: 7));
  int? _dateWindowDays = 7;
  bool _isSubmitting = false;

  // Reminder state
  bool _reminderEnabled = false;
  final Set<int> _selectedReminderDays = {1}; // Default: 1 day before

  // Wizard state
  int _currentStep = 0;
  final int _totalSteps = 5;
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

    // Pre-fill from existing expense if editing
    if (widget.existingExpense != null) {
      _preFillFromExistingExpense(widget.existingExpense!);
    } else if (widget.extractedData != null) {
      // Pre-fill from extracted data if available
      _preFillFromExtractedData(widget.extractedData!);
    }
  }

  void _preFillFromExistingExpense(FutureExpenseEntity expense) {
    _titleController.text = expense.title;
    if (expense.merchant != null) {
      _merchantController.text = expense.merchant!;
    }
    _expectedAmountController.text = expense.expectedAmount.toString();
    if (expense.minAmount != null) {
      _minAmountController.text = expense.minAmount.toString();
    }
    if (expense.maxAmount != null) {
      _maxAmountController.text = expense.maxAmount.toString();
    }
    if (expense.note != null) {
      _noteController.text = expense.note!;
    }
    _amountCertainty = expense.amountCertainty;
    _priority = expense.priority;
    _dateFlexibility = expense.dateFlexibility;
    _expectedDate = expense.expectedDate;
    _dateWindowDays = expense.dateWindowDays;

    // Set category
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final categoriesAsync = ref.read(categoriesProvider);
        categoriesAsync.whenData((categories) {
          if (categories.isNotEmpty) {
            final matchingCategory = categories.firstWhere(
              (cat) => cat.name.toLowerCase() == expense.category.toLowerCase(),
              orElse: () => categories.first,
            );
            if (mounted) {
              setState(() {
                _selectedCategory = matchingCategory;
              });
            }
          }
        });
      }
    });
  }

  /// Check if there's unsaved data in the form
  bool _hasUnsavedData() {
    // Check if any field has been filled
    return _titleController.text.trim().isNotEmpty ||
        _merchantController.text.trim().isNotEmpty ||
        _expectedAmountController.text.trim().isNotEmpty ||
        _minAmountController.text.trim().isNotEmpty ||
        _maxAmountController.text.trim().isNotEmpty ||
        _noteController.text.trim().isNotEmpty ||
        _selectedCategory != null ||
        _dateWindowDays != null;
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
                      size: 24.scaled(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Discard expense?',
                        style: AppFonts.textStyle(
                          fontSize: 18,
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
                const SizedBox(height: 16),
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
                            fontSize: 15.scaledText(context),
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
                            fontSize: 15.scaledText(context),
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
  void dispose() {
    _titleController.dispose();
    _merchantController.dispose();
    _expectedAmountController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _noteController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _preFillFromExtractedData(Map<String, dynamic> data) {
    if (data['title'] != null) {
      _titleController.text = data['title'].toString();
    }
    if (data['expectedAmount'] != null || data['amount'] != null) {
      final amount = data['expectedAmount'] ?? data['amount'];
      _expectedAmountController.text = amount.toString();
    }
    if (data['description'] != null || data['note'] != null) {
      _noteController.text = (data['description'] ?? data['note']).toString();
    }
    if (data['merchant'] != null) {
      _merchantController.text = data['merchant'].toString();
    }
    if (data['expectedDate'] != null || data['date'] != null) {
      try {
        final dateStr = data['expectedDate'] ?? data['date'];
        _expectedDate = DateTime.parse(dateStr.toString());
      } catch (e) {
        // Ignore parse errors
      }
    }
    if (data['priority'] != null) {
      final priorityStr = data['priority'].toString().toLowerCase();
      _priority = FutureExpensePriority.values.firstWhere(
        (p) => p.name == priorityStr,
        orElse: () => FutureExpensePriority.medium,
      );
    }
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
        _submitFutureExpense();
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
      case 0: // What & How Much
        if (_titleController.text.trim().isEmpty) {
          _showError('Please enter a title for your future expense');
          return false;
        }
        if (_expectedAmountController.text.trim().isEmpty) {
          _showError('Please enter an expected amount');
          return false;
        }
        final expectedAmount =
            double.tryParse(
              _expectedAmountController.text.replaceAll(',', ''),
            ) ??
            0.0;
        if (expectedAmount <= 0) {
          _showError('Expected amount must be greater than 0');
          return false;
        }
        if (_amountCertainty == AmountCertainty.range) {
          if (_minAmountController.text.trim().isEmpty ||
              _maxAmountController.text.trim().isEmpty) {
            _showError('Please enter both min and max amounts');
            return false;
          }
          final minAmount =
              double.tryParse(_minAmountController.text.replaceAll(',', '')) ??
              0.0;
          final maxAmount =
              double.tryParse(_maxAmountController.text.replaceAll(',', '')) ??
              0.0;
          if (minAmount >= maxAmount) {
            _showError('Min amount must be less than max amount');
            return false;
          }
          // Validate expectedAmount is within range
          final expectedAmount =
              double.tryParse(
                _expectedAmountController.text.replaceAll(',', ''),
              ) ??
              0.0;
          if (expectedAmount < minAmount || expectedAmount > maxAmount) {
            _showError('Expected amount must be between min and max amounts');
            return false;
          }
        }
        return true;
      case 1: // When
        return true; // Date is always set
      case 2: // Categorize & Prioritize
        if (_selectedCategory == null) {
          _showError('Please select a category');
          return false;
        }
        return true;
      case 3: // Additional Details
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

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _expectedDate = picked;
      });
    }
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

  Future<void> _deleteFutureExpense(BuildContext context, WidgetRef ref) async {
    if (widget.existingExpense == null) return;

    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Delete Future Expense',
      message:
          'Are you sure you want to delete "${widget.existingExpense!.title}"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmColor: AppTheme.errorColor,
    );

    if (confirmed != true || !mounted) return;

    try {
      final apiService = ref.read(apiServiceV2Provider);
      await apiService.dio.delete(
        '/future-expenses/${widget.existingExpense!.id}',
      );

      // Invalidate providers
      ref.invalidate(futureExpensesProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Future expense deleted successfully')),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _markAsPaid(BuildContext context, WidgetRef ref) async {
    if (widget.existingExpense == null || widget.existingExpense!.isConverted) {
      return;
    }

    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Mark as Paid',
      message:
          'Convert "${widget.existingExpense!.title}" to an actual expense? This will mark it as paid and add it to your expense history.',
      confirmText: 'Mark as Paid',
      cancelText: 'Cancel',
      confirmColor: AppTheme.successColor,
    );

    if (confirmed != true || !mounted) return;

    try {
      final apiService = ref.read(apiServiceV2Provider);
      await apiService.dio.post(
        '/future-expenses/${widget.existingExpense!.id}/convert',
      );

      // Invalidate providers
      ref.invalidate(futureExpensesProvider);
      ref.invalidate(expensesProvider);
      ref.invalidate(recentTransactionsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.existingExpense!.title} marked as paid! 🎉',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as paid: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _submitFutureExpense() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiService = ref.read(apiServiceV2Provider);

      final expectedAmount =
          double.tryParse(_expectedAmountController.text.replaceAll(',', '')) ??
          0.0;

      // Map category to ExpenseCategory enum
      final expenseCategory = _mapCategoryToExpenseCategory(_selectedCategory!);

      final futureExpenseData = {
        'title': _titleController.text.trim(),
        if (_noteController.text.isNotEmpty)
          'description': _noteController.text.trim(),
        if (_merchantController.text.isNotEmpty)
          'merchant': _merchantController.text.trim(),
        'expectedAmount': expectedAmount,
        if (_amountCertainty == AmountCertainty.range)
          'minAmount':
              double.tryParse(_minAmountController.text.replaceAll(',', '')) ??
              0.0,
        if (_amountCertainty == AmountCertainty.range)
          'maxAmount':
              double.tryParse(_maxAmountController.text.replaceAll(',', '')) ??
              0.0,
        'amountCertainty': _amountCertainty.name,
        'category': expenseCategory.name,
        'expectedDate': _expectedDate.toIso8601String().split('T')[0],
        'dateFlexibility': _dateFlexibility.name,
        if (_dateFlexibility == DateFlexibility.flexible &&
            _dateWindowDays != null)
          'dateWindowDays': _dateWindowDays,
        'priority': _priority.name,
        if (_noteController.text.isNotEmpty)
          'note': _noteController.text.trim(),
      };

      debugPrint('📤 Submitting future expense:');
      debugPrint('   Data: $futureExpenseData');

      final response = widget.existingExpense != null
          ? await apiService.dio.patch(
              '/future-expenses/${widget.existingExpense!.id}',
              data: futureExpenseData,
            )
          : await apiService.dio.post(
              '/future-expenses',
              data: futureExpenseData,
            );

      debugPrint(
        '✅ Future expense ${widget.existingExpense != null ? 'updated' : 'created'} successfully',
      );
      debugPrint('   Response: ${response.data}');

      final futureExpenseId = response.data['id'] as String?;

      // Schedule reminders if enabled
      if (_reminderEnabled &&
          futureExpenseId != null &&
          _selectedReminderDays.isNotEmpty) {
        await _scheduleReminders(futureExpenseId);
      }

      // Invalidate future expenses provider
      ref.invalidate(futureExpensesProvider);

      // TODO: Re-implement onboarding completion
      // Mark onboarding as complete if this is the first expense
      // if (widget.existingExpense == null && widget.isFirstExpense) {
      //   try {
      //     final userProfileService = ref.read(userProfileServiceProvider);
      //     await userProfileService.completeOnboarding();
      //     // Invalidate user profile to refresh onboarding status
      //     ref.invalidate(userProfileProvider);
      //   } catch (e) {
      //     // Don't block expense creation if onboarding update fails
      //     AppLogger.w('Failed to mark onboarding complete: $e', tag: 'FutureExpense');
      //   }
      // }

      if (mounted) {
        // If this is the first expense, navigate to home screen
        if (widget.isFirstExpense) {
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
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  widget.existingExpense != null
                      ? 'Future expense updated successfully! 🎉'
                      : (_reminderEnabled && _selectedReminderDays.isNotEmpty
                            ? 'Future expense created! ${_selectedReminderDays.length} reminder${_selectedReminderDays.length > 1 ? 's' : ''} set. 🎉'
                            : 'Future expense created successfully! 🎉'),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        debugPrint('❌ Error creating future expense: $e');
        if (e is DioException) {
          debugPrint('   Status code: ${e.response?.statusCode}');
          debugPrint('   Response data: ${e.response?.data}');
          debugPrint('   Request data: ${e.requestOptions.data}');

          final errorMessage =
              e.response?.data?['message'] ??
              e.response?.data?['error'] ??
              (widget.existingExpense != null
                  ? 'Failed to update future expense'
                  : 'Failed to create future expense');
          _showError(errorMessage);
        } else {
          _showError(
            widget.existingExpense != null
                ? 'Failed to update future expense: ${e.toString()}'
                : 'Failed to create future expense: ${e.toString()}',
          );
        }
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppTheme.screenBackgroundColor;

    return PopScope(
      canPop: !_hasUnsavedData(),
      onPopInvoked: (didPop) {
        if (!didPop && _hasUnsavedData()) {
          _showExitConfirmation();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
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
            widget.existingExpense != null
                ? 'Edit Future Expense'
                : 'Plan Future Expense',
            style: AppFonts.textStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          actions: widget.existingExpense != null
              ? [
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 16,
                    shadowColor: Colors.black.withValues(alpha: 0.4),
                    onSelected: (value) {
                      if (value == 'mark_completed') {
                        _markAsPaid(context, ref);
                      } else if (value == 'update') {
                        // Navigate to last step to allow quick update
                        setState(() {
                          _currentStep = _totalSteps - 1;
                          _animationController.reset();
                          _animationController.forward();
                        });
                      } else if (value == 'delete') {
                        _deleteFutureExpense(context, ref);
                      }
                    },
                    itemBuilder: (context) => [
                      if (!widget.existingExpense!.isConverted)
                        PopupMenuItem(
                          value: 'mark_completed',
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 20.scaled(context),
                                color: AppTheme.successColor,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Mark as Completed',
                                style: AppFonts.textStyle(
                                  fontSize: 14.scaledText(context),
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'update',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              size: 20.scaled(context),
                              color: AppTheme.primaryColor,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Update Expense',
                              style: AppFonts.textStyle(
                                fontSize: 14.scaledText(context),
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_rounded,
                              size: 20.scaled(context),
                              color: AppTheme.errorColor,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Delete Expense',
                              style: AppFonts.textStyle(
                                fontSize: 14.scaledText(context),
                                fontWeight: FontWeight.w500,
                                color: AppTheme.errorColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ]
              : null,
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
          SizedBox(height: 8),
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
        return 'What & How Much';
      case 1:
        return 'When';
      case 2:
        return 'Categorize & Prioritize';
      case 3:
        return 'Additional Details';
      case 4:
        return 'Review & Confirm';
      default:
        return '';
    }
  }

  String _getStepSubtitle(int step) {
    switch (step) {
      case 0:
        return 'Tell us about your planned expense';
      case 1:
        return 'When do you expect this expense?';
      case 2:
        return 'Help us organize and prioritize';
      case 3:
        return 'Add any extra information (optional)';
      case 4:
        return 'Review your future expense details';
      default:
        return '';
    }
  }

  Widget _buildStepContent(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildStep1WhatAndHowMuch(isDark);
      case 1:
        return _buildStep2When(isDark);
      case 2:
        return _buildStep3CategorizeAndPrioritize(isDark);
      case 3:
        return _buildStep4AdditionalDetails(isDark);
      case 4:
        return _buildStep5Review(isDark);
      default:
        return SizedBox();
    }
  }

  Widget _buildStep1WhatAndHowMuch(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        AppTextField(
          controller: _titleController,
          label: 'What is this expense?',
          hintText: 'e.g., Vacation to Paris, New Laptop, Wedding Gift',
          minLines: 2,
          maxLines: 3,
          prefixIcon: Icon(
            Icons.title_rounded,
            size: 18,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : AppTheme.textSecondary,
          ),
        ),
        SizedBox(height: 16),

        // Expected Amount
        AmountInputField(
          controller: _expectedAmountController,
          label: 'Expected Amount',
        ),
        SizedBox(height: 16),

        // Amount Certainty
        _buildAmountCertaintySelector(isDark),
        if (_amountCertainty == AmountCertainty.range) ...[
          SizedBox(height: 12.scaledVertical(context)),
          Row(
            children: [
              Expanded(
                child: AmountInputField(
                  controller: _minAmountController,
                  label: 'Min Amount',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: AmountInputField(
                  controller: _maxAmountController,
                  label: 'Max Amount',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStep2When(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Expected Date
        _buildInputField(
          icon: Icons.calendar_today_rounded,
          label: 'Expected Date',
          value: DateFormat('MMM d, y').format(_expectedDate),
          onTap: () => _selectDate(context),
        ),
        SizedBox(height: 16),

        // Date Flexibility
        _buildDateFlexibilitySelector(isDark),
        if (_dateFlexibility == DateFlexibility.flexible) ...[
          SizedBox(height: 12.scaledVertical(context)),
          _buildDateWindowSelector(isDark),
        ],
        SizedBox(height: 16),

        // Reminder Section
        _buildReminderSection(isDark),
      ],
    );
  }

  Widget _buildStep3CategorizeAndPrioritize(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            SizedBox(height: 8),
            CategorySelectionWidget(
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
          ],
        ),
        SizedBox(height: 20),

        // Priority
        _buildPrioritySelector(isDark),
      ],
    );
  }

  Widget _buildStep4AdditionalDetails(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'These fields are optional. You can skip this step if you don\'t need them.',
          style: AppFonts.textStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: isDark
                ? Colors.white.withValues(alpha: 0.6)
                : AppTheme.textSecondary,
          ),
        ),
        SizedBox(height: 16),

        // Note
        _buildInputField(
          icon: Icons.note_rounded,
          label: 'Note',
          value: _noteController.text.isEmpty
              ? 'Add a note (optional)'
              : _noteController.text,
          isPlaceholder: _noteController.text.isEmpty,
          onTap: () async {
            final result = await _showNoteBottomSheet(
              context,
              _noteController.text,
            );
            if (result != null) {
              setState(() {
                _noteController.text = result;
              });
            }
          },
        ),
        SizedBox(height: 10.scaledVertical(context)),

        // Merchant
        _buildInputField(
          icon: Icons.store_rounded,
          label: 'Merchant Name',
          value: _merchantController.text.isEmpty
              ? 'Add merchant name (optional)'
              : _merchantController.text,
          isPlaceholder: _merchantController.text.isEmpty,
          onTap: () async {
            final result = await _showMerchantBottomSheet(
              context,
              _merchantController.text,
            );
            if (result != null) {
              setState(() {
                _merchantController.text = result;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildStep5Review(bool isDark) {
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final currency = currencyAsync.valueOrNull ?? Currency.defaultCurrency;
    final expectedAmount =
        double.tryParse(_expectedAmountController.text.replaceAll(',', '')) ??
        0.0;
    final amountRangeValue = _amountCertainty == AmountCertainty.range &&
            _minAmountController.text.isNotEmpty &&
            _maxAmountController.text.isNotEmpty
        ? '${CurrencyFormatter.format(double.tryParse(_minAmountController.text.replaceAll(',', '')) ?? 0.0, currency)} - ${CurrencyFormatter.format(double.tryParse(_maxAmountController.text.replaceAll(',', '')) ?? 0.0, currency)}'
        : null;
    final flexibilityValue = _dateFlexibility == DateFlexibility.flexible &&
            _dateWindowDays != null
        ? '±$_dateWindowDays day${_dateWindowDays! > 1 ? 's' : ''}'
        : null;
    final remindersValue = _reminderEnabled && _selectedReminderDays.isNotEmpty
        ? () {
            final sortedDays = _selectedReminderDays.toList()..sort();
            return sortedDays
                .map((days) {
                  final reminderDate =
                      _expectedDate.subtract(Duration(days: days));
                  return '$days day${days > 1 ? 's' : ''} before (${DateFormat('MMM d').format(reminderDate)})';
                })
                .join(', ');
          }()
        : null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                _buildReceiptRow('Title', _titleController.text.trim(), isDark),
                _buildReceiptDivider(isDark),
                _buildReceiptRow(
                  'Expected Amount',
                  CurrencyFormatter.format(expectedAmount, currency),
                  isDark,
                ),
                _buildReceiptDivider(isDark),
                _buildReceiptRow(
                  'Amount Certainty',
                  _amountCertainty.name.toUpperCase(),
                  isDark,
                ),
                if (amountRangeValue != null) ...[
                  _buildReceiptDivider(isDark),
                  _buildReceiptRow('Amount Range', amountRangeValue, isDark),
                ],
                _buildReceiptDivider(isDark),
                _buildReceiptRow(
                  'Expected Date',
                  DateFormat('MMM d, y').format(_expectedDate),
                  isDark,
                ),
                _buildReceiptDivider(isDark),
                _buildReceiptRow(
                  'Date Flexibility',
                  _dateFlexibility.name.toUpperCase(),
                  isDark,
                ),
                if (flexibilityValue != null) ...[
                  _buildReceiptDivider(isDark),
                  _buildReceiptRow('Flexibility Window', flexibilityValue, isDark),
                ],
                if (remindersValue != null) ...[
                  _buildReceiptDivider(isDark),
                  _buildReceiptRow('Reminders', remindersValue, isDark),
                ],
                _buildReceiptDivider(isDark),
                _buildReceiptRow(
                  'Category',
                  _selectedCategory?.name ?? 'Not selected',
                  isDark,
                ),
                _buildReceiptDivider(isDark),
                _buildReceiptRow('Priority', _priority.name.toUpperCase(), isDark),
                if (_noteController.text.isNotEmpty) ...[
                  _buildReceiptDivider(isDark),
                  _buildReceiptRow('Note', _noteController.text, isDark),
                ],
                if (_merchantController.text.isNotEmpty) ...[
                  _buildReceiptDivider(isDark),
                  _buildReceiptRow('Merchant', _merchantController.text, isDark),
                ],
              ],
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This planned expense will be included in your financial forecasts. You can convert it to an actual expense when it occurs.',
                    style: AppFonts.textStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                          ? 'Create Expense'
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

  Widget _buildAmountCertaintySelector(bool isDark) {
    return SelectionPillGroup(
      label: 'Amount Certainty',
      onHelpTap: () => _showHintDialog(
        context,
        'Amount Certainty',
        'Choose how certain you are about the expense amount:\n\n'
            '• Exact: You know the precise amount\n'
            '• Range: You know the minimum and maximum amounts\n'
            '• Estimate: You have a rough idea of the amount',
      ),
      useWrap: false,
      spacing: 8,
      children: [
        SelectionPill(
          label: 'Exact',
          icon: Icons.check_circle_outline_rounded,
          isSelected: _amountCertainty == AmountCertainty.exact,
          onTap: () => setState(() => _amountCertainty = AmountCertainty.exact),
          isExpanded: true,
        ),
        SelectionPill(
          label: 'Range',
          icon: Icons.swap_horiz_rounded,
          isSelected: _amountCertainty == AmountCertainty.range,
          onTap: () => setState(() => _amountCertainty = AmountCertainty.range),
          isExpanded: true,
        ),
        SelectionPill(
          label: 'Estimate',
          icon: Icons.help_outline_rounded,
          isSelected: _amountCertainty == AmountCertainty.estimate,
          onTap: () =>
              setState(() => _amountCertainty = AmountCertainty.estimate),
          isExpanded: true,
        ),
      ],
    );
  }

  Widget _buildDateFlexibilitySelector(bool isDark) {
    return SelectionPillGroup(
      label: 'Date Flexibility',
      onHelpTap: () => _showHintDialog(
        context,
        'Date Flexibility',
        'Choose how flexible the expense date is:\n\n'
            '• Fixed: The expense will occur on a specific date\n'
            '• Flexible: The expense can occur within a date range',
      ),
      useWrap: false,
      spacing: 12,
      children: [
        SelectionPill(
          label: 'Fixed',
          icon: Icons.calendar_today_rounded,
          isSelected: _dateFlexibility == DateFlexibility.fixed,
          onTap: () {
            setState(() {
              _dateFlexibility = DateFlexibility.fixed;
              _dateWindowDays = null;
            });
          },
          isExpanded: true,
        ),
        SelectionPill(
          label: 'Flexible',
          icon: Icons.event_available_rounded,
          isSelected: _dateFlexibility == DateFlexibility.flexible,
          onTap: () {
            setState(() {
              _dateFlexibility = DateFlexibility.flexible;
              _dateWindowDays = 7;
            });
          },
          isExpanded: true,
        ),
      ],
    );
  }

  Widget _buildDateWindowSelector(bool isDark) {
    final dateWindowOptions = [
      {'days': 1, 'label': '1 day'},
      {'days': 3, 'label': '3 days'},
      {'days': 7, 'label': '1 week'},
      {'days': 14, 'label': '2 weeks'},
      {'days': 30, 'label': '1 month'},
    ];

    return SelectionPillGroup(
      label: 'Flexibility Window',
      onHelpTap: () => _showHintDialog(
        context,
        'Flexibility Window',
        'Select how flexible the date can be. This allows the expense to occur within a range around your expected date:\n\n'
            '• 1 day: Very tight window (±1 day)\n'
            '• 3 days: Short window (±3 days)\n'
            '• 1 week: Weekly window (±7 days)\n'
            '• 2 weeks: Bi-weekly window (±14 days)\n'
            '• 1 month: Monthly window (±30 days)',
      ),
      useWrap: true,
      spacing: 8,
      children: dateWindowOptions.map((option) {
        final days = option['days'] as int;
        final label = option['label'] as String;
        final isSelected = _dateWindowDays == days;

        return SelectionPill(
          label: label,
          icon: Icons.event_available_rounded,
          isSelected: isSelected,
          onTap: () => setState(() => _dateWindowDays = days),
        );
      }).toList(),
    );
  }

  IconData _getPriorityIcon(FutureExpensePriority priority) {
    switch (priority) {
      case FutureExpensePriority.low:
        return Icons.arrow_downward_rounded;
      case FutureExpensePriority.medium:
        return Icons.remove_rounded;
      case FutureExpensePriority.high:
        return Icons.arrow_upward_rounded;
      case FutureExpensePriority.critical:
        return Icons.priority_high_rounded;
    }
  }

  Widget _buildPrioritySelector(bool isDark) {
    return SelectionPillGroup(
      label: 'Priority',
      onHelpTap: () => _showHintDialog(
        context,
        'Priority',
        'Set the importance level of this expense:\n\n'
            '• Low: Not urgent, can be delayed\n'
            '• Medium: Normal priority\n'
            '• High: Important, should be planned for\n'
            '• Critical: Very important, must be accounted for',
      ),
      useWrap: true,
      spacing: 8,
      children: FutureExpensePriority.values.map((priority) {
        return SelectionPill(
          label: priority.name.toUpperCase(),
          icon: _getPriorityIcon(priority),
          isSelected: _priority == priority,
          onTap: () => setState(() => _priority = priority),
        );
      }).toList(),
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
    // Use same background color logic as AppTextField with increased contrast
    final baseCardColor = isDark
        ? AppTheme.darkCardBackground
        : AppTheme.cardBackground;
    final backgroundColor = isDark
        ? Color.lerp(baseCardColor, Colors.white, 0.08) ?? baseCardColor
        : Color.lerp(baseCardColor, const Color(0xFFE5E7EB), 0.3) ??
              baseCardColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          // No border to match AppTextField style
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
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.textSecondary,
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

  Future<String?> _showMerchantBottomSheet(
    BuildContext context,
    String initialValue,
  ) async {
    final merchantController = TextEditingController(text: initialValue);

    return await BottomSheetModal.show<String>(
      context: context,
      title: 'Add Merchant Name',
      subtitle: 'Add a merchant name to this future expense',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: merchantController,
              autofocus: true,
              style: AppFonts.textStyle(
                fontSize: 14.scaledText(context),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Enter merchant name...',
                hintStyle: AppFonts.textStyle(
                  fontSize: 14.scaledText(context),
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, merchantController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Save',
                style: AppFonts.textStyle(
                  fontSize: 14.scaledText(context),
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

  Future<String?> _showNoteBottomSheet(
    BuildContext context,
    String initialValue,
  ) async {
    final noteController = TextEditingController(text: initialValue);

    return await BottomSheetModal.show<String>(
      context: context,
      title: 'Add Note',
      subtitle: 'Add a note to this future expense',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: noteController,
              autofocus: true,
              maxLines: 4,
              style: AppFonts.textStyle(
                fontSize: 14.scaledText(context),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Enter note...',
                hintStyle: AppFonts.textStyle(
                  fontSize: 14.scaledText(context),
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, noteController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Save',
                style: AppFonts.textStyle(
                  fontSize: 14.scaledText(context),
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

  void _showHintDialog(BuildContext context, String title, String message) {
    AppDialog.showInfo(
      context: context,
      title: title,
      message: message,
      icon: Icons.info_outline_rounded,
    );
  }

  Widget _buildReminderSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _reminderEnabled = !_reminderEnabled;
            });
          },
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Send Reminders',
                  style: AppFonts.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _reminderEnabled,
                  onChanged: (value) {
                    setState(() {
                      _reminderEnabled = value;
                    });
                  },
                  activeThumbColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
        if (_reminderEnabled) ...[
          SizedBox(height: 12.scaledVertical(context)),
          SelectionPillGroup(
            label: 'Remind me',
            useWrap: true,
            spacing: 8,
            children: [1, 2, 3, 7, 14, 30].map((days) {
              final isSelected = _selectedReminderDays.contains(days);
              return SelectionPill(
                label: '$days day${days > 1 ? 's' : ''} before',
                icon: Icons.notifications_active_rounded,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedReminderDays.remove(days);
                      // Ensure at least one reminder is selected
                      if (_selectedReminderDays.isEmpty) {
                        _selectedReminderDays.add(1);
                      }
                    } else {
                      _selectedReminderDays.add(days);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Future<void> _scheduleReminders(String futureExpenseId) async {
    try {
      final notificationService = LocalNotificationService();
      await notificationService.initialize();

      final currencyAsync = ref.read(selectedCurrencyProvider);
      final currency = currencyAsync.valueOrNull ?? Currency.defaultCurrency;
      final expectedAmount =
          double.tryParse(_expectedAmountController.text.replaceAll(',', '')) ??
          0.0;

      final title = _titleController.text.trim();
      final amountText = CurrencyFormatter.format(expectedAmount, currency);
      final now = DateTime.now();
      int scheduledCount = 0;
      int skippedCount = 0;

      // Schedule a reminder for each selected day
      for (final daysBefore in _selectedReminderDays) {
        // Calculate reminder date (expected date minus reminder days)
        final reminderDate = _expectedDate.subtract(Duration(days: daysBefore));

        // Only schedule if reminder date is in the future
        if (reminderDate.isBefore(now)) {
          skippedCount++;
          continue;
        }

        // Schedule notification at 9 AM on the reminder date
        final reminderDateTime = DateTime(
          reminderDate.year,
          reminderDate.month,
          reminderDate.day,
          9, // 9 AM
        );

        // Use unique ID for each reminder (futureExpenseId + daysBefore)
        final reminderId = '$futureExpenseId-$daysBefore';

        await notificationService.scheduleFutureExpenseReminder(
          id: reminderId,
          title: title,
          amount: amountText,
          expectedDate: _expectedDate,
          reminderDate: reminderDateTime,
        );

        scheduledCount++;
      }

      if (mounted) {
        if (scheduledCount > 0) {
          debugPrint(
            '✅ Scheduled $scheduledCount reminder${scheduledCount > 1 ? 's' : ''} for future expense',
          );
        }
        if (skippedCount > 0) {
          debugPrint(
            '⚠️ Skipped $skippedCount reminder${skippedCount > 1 ? 's' : ''} (date in past)',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint('❌ Error scheduling reminders: $e');
        // Don't show error to user - reminder is optional
      }
    }
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
