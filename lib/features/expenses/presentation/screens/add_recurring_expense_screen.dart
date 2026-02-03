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
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/category_selection_widget.dart';
import '../../../../core/widgets/selection_pill.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/recurring_expense_entity.dart';
import '../providers/recurring_expenses_providers.dart';
// TODO: Re-implement user profile providers
// import '../../../auth/presentation/providers/user_profile_providers.dart';
import '../../../home/presentation/screens/home_screen.dart';
import 'expense_type_selection_screen.dart';

class AddRecurringExpenseScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? extractedData; // Data from intent classification
  final RecurringExpenseEntity? existingExpense;
  final bool isFirstExpense; // If true, navigate to home after saving

  const AddRecurringExpenseScreen({
    super.key,
    this.extractedData,
    this.existingExpense,
    this.isFirstExpense = false,
  });

  @override
  ConsumerState<AddRecurringExpenseScreen> createState() =>
      _AddRecurringExpenseScreenState();
}

class _AddRecurringExpenseScreenState
    extends ConsumerState<AddRecurringExpenseScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  CategoryModel? _selectedCategory;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  AmountType _amountType = AmountType.fixed;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _autoPost = false;
  bool _sendReminders = true;
  final Set<int> _selectedReminderDays = {3}; // Default: 3 days before
  bool _isSubmitting = false;

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

  void _preFillFromExistingExpense(RecurringExpenseEntity expense) {
    _titleController.text = expense.title;
    if (expense.description != null) {
      _descriptionController.text = expense.description!;
    }
    if (expense.merchant != null) {
      _merchantController.text = expense.merchant!;
    }
    _amountController.text = expense.amount.toString();
    _amountType = expense.amountType;
    _frequency = expense.frequency;
    _startDate = expense.startDate;
    _endDate = expense.endDate;
    _autoPost = expense.autoPost;
    _sendReminders = expense.sendReminders;
    // Convert single reminder day to set for multiple reminders support
    if (expense.reminderDaysBefore != null) {
      _selectedReminderDays.clear();
      _selectedReminderDays.add(expense.reminderDaysBefore!);
    }

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

  void _preFillFromExtractedData(Map<String, dynamic> data) {
    if (data['title'] != null) {
      _titleController.text = data['title'].toString();
    }
    if (data['amount'] != null) {
      _amountController.text = data['amount'].toString();
    }
    if (data['description'] != null) {
      _descriptionController.text = data['description'].toString();
    }
    if (data['merchant'] != null) {
      _merchantController.text = data['merchant'].toString();
    }
    if (data['frequency'] != null) {
      final freqStr = data['frequency'].toString().toLowerCase();
      _frequency = RecurrenceFrequency.values.firstWhere(
        (f) => f.name == freqStr,
        orElse: () => RecurrenceFrequency.monthly,
      );
    }
    if (data['startDate'] != null) {
      try {
        _startDate = DateTime.parse(data['startDate'].toString());
      } catch (e) {
        // Ignore parse errors
      }
    }
  }

  /// Check if there's unsaved data in the form
  bool _hasUnsavedData() {
    // Check if any field has been filled
    return _titleController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _merchantController.text.trim().isNotEmpty ||
        _amountController.text.trim().isNotEmpty ||
        _selectedCategory != null ||
        _endDate != null;
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
            borderRadius: BorderRadius.circular(20),
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
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Discard expense?',
                      style: AppFonts.textStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
                      padding: const EdgeInsets.symmetric(
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
                          builder: (context) => const ExpenseTypeSelectionScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
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
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _merchantController.dispose();
    _amountController.dispose();
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
        _submitRecurringExpense();
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
          _showError('Please enter a title for your recurring expense');
          return false;
        }
        if (_amountController.text.trim().isEmpty) {
          _showError('Please enter an amount');
          return false;
        }
        final amount =
            double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
        if (amount <= 0) {
          _showError('Amount must be greater than 0');
          return false;
        }
        return true;
      case 1: // Frequency & Schedule
        return true; // Dates are always set
      case 2: // Categorize
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

  Future<void> _selectDate(
    BuildContext context,
    bool isStartDate,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If end date is before new start date, clear it
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _deleteRecurringExpense(BuildContext context, WidgetRef ref) async {
    if (widget.existingExpense == null) return;

    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: 'Delete Recurring Expense',
      message:
          'Are you sure you want to delete "${widget.existingExpense!.title}"? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmColor: AppTheme.errorColor,
    );

    if (confirmed != true || !mounted) return;

    try {
      final apiService = ref.read(apiServiceV2Provider);
      await apiService.dio.delete('/recurring-expenses/${widget.existingExpense!.id}');

      // Invalidate providers
      ref.invalidate(recurringExpensesProvider);

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
                    'Recurring expense deleted successfully',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.scaled(context)),
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
              borderRadius: BorderRadius.circular(12.scaled(context)),
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref) async {
    if (widget.existingExpense == null) return;

    final isCurrentlyActive = widget.existingExpense!.isActive;
    final action = isCurrentlyActive ? 'pause' : 'activate';
    final actionPast = isCurrentlyActive ? 'paused' : 'activated';

    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: isCurrentlyActive ? 'Pause Recurring Expense' : 'Activate Recurring Expense',
      message: isCurrentlyActive
          ? 'Pause "${widget.existingExpense!.title}"? It will stop auto-posting until you activate it again.'
          : 'Activate "${widget.existingExpense!.title}"? It will resume auto-posting based on its schedule.',
      confirmText: isCurrentlyActive ? 'Pause' : 'Activate',
      cancelText: 'Cancel',
      confirmColor: isCurrentlyActive ? AppTheme.warningColor : AppTheme.successColor,
    );

    if (confirmed != true || !mounted) return;

    try {
      final apiService = ref.read(apiServiceV2Provider);
      await apiService.dio.patch(
        '/recurring-expenses/${widget.existingExpense!.id}',
        data: {'isActive': !isCurrentlyActive},
      );

      // Invalidate providers
      ref.invalidate(recurringExpensesProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isCurrentlyActive
                      ? Icons.pause_circle_rounded
                      : Icons.play_circle_rounded,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.existingExpense!.title} $actionPast successfully!',
                  ),
                ),
              ],
            ),
            backgroundColor: isCurrentlyActive
                ? AppTheme.warningColor
                : AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.scaled(context)),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to $action: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.scaled(context)),
            ),
          ),
        );
      }
    }
  }

  Future<void> _submitRecurringExpense() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a title'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter an amount'),
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

    // Parse amount
    final amountText = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiService = ref.read(apiServiceV2Provider);

      // Map category to ExpenseCategory enum
      final expenseCategory = _mapCategoryToExpenseCategory(_selectedCategory!);

      final recurringData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'merchant': _merchantController.text.trim().isEmpty
            ? null
            : _merchantController.text.trim(),
        'amount': amount,
        'amountType': _amountType.name,
        'category': expenseCategory.name,
        'frequency': _frequency.name,
        'startDate': _startDate.toIso8601String().split('T')[0],
        'endDate': _endDate?.toIso8601String().split('T')[0],
        'autoPost': _autoPost,
        'sendReminders': _sendReminders,
        // Send first reminder day for backward compatibility (or could be updated to array)
        'reminderDaysBefore': _sendReminders && _selectedReminderDays.isNotEmpty
            ? _selectedReminderDays.first
            : null,
        'isActive': true,
      };

      if (widget.existingExpense != null) {
        await apiService.dio.patch(
          '/recurring-expenses/${widget.existingExpense!.id}',
          data: recurringData,
        );
      } else {
        await apiService.dio.post(
          '/recurring-expenses',
          data: recurringData,
        );
      }

      // Invalidate providers
      ref.invalidate(recurringExpensesProvider);

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
      //     AppLogger.w('Failed to mark onboarding complete: $e', tag: 'RecurringExpense');
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
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.existingExpense != null
                        ? 'Recurring expense updated successfully! 🎉'
                        : 'Recurring expense created successfully! 🎉',
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.scaled(context)),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        debugPrint(
            '❌ Error ${widget.existingExpense != null ? 'updating' : 'creating'} recurring expense: $e');
        if (e is DioException) {
          debugPrint('   Status code: ${e.response?.statusCode}');
          debugPrint('   Response data: ${e.response?.data}');
          debugPrint('   Request data: ${e.requestOptions.data}');

          final errorMessage =
              e.response?.data?['message'] ??
              e.response?.data?['error'] ??
              (widget.existingExpense != null
                  ? 'Failed to update recurring expense'
                  : 'Failed to create recurring expense');
          _showError(errorMessage);
        } else {
          _showError(widget.existingExpense != null
              ? 'Failed to update recurring expense: ${e.toString()}'
              : 'Failed to create recurring expense: ${e.toString()}');
        }
      }
    } finally {
      if (mounted) {
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
              ? 'Edit Recurring Expense'
              : 'Recurring Expense',
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
                    borderRadius: BorderRadius.circular(12.scaled(context)),
                  ),
                  elevation: 16,
                  shadowColor: Colors.black.withValues(alpha: 0.4),
                  onSelected: (value) {
                    if (value == 'toggle_active') {
                      _toggleActive(context, ref);
                    } else if (value == 'update') {
                      // Navigate to last step to allow quick update
                      setState(() {
                        _currentStep = _totalSteps - 1;
                        _animationController.reset();
                        _animationController.forward();
                      });
                    } else if (value == 'delete') {
                      _deleteRecurringExpense(context, ref);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle_active',
                      child: Row(
                        children: [
                          Icon(
                            widget.existingExpense!.isActive
                                ? Icons.pause_circle_outline_rounded
                                : Icons.play_circle_outline_rounded,
                            size: 20.scaled(context),
                            color: widget.existingExpense!.isActive
                                ? AppTheme.warningColor
                                : AppTheme.successColor,
                          ),
                          SizedBox(width: 12),
                          Text(
                            widget.existingExpense!.isActive
                                ? 'Pause Recurring'
                                : 'Activate Recurring',
                            style: AppFonts.textStyle(
                              fontSize: 14.scaledText(context),
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : AppTheme.textPrimary,
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
                              color: isDark ? Colors.white : AppTheme.textPrimary,
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
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: 10),
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
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (index < _totalSteps - 1)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
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
        return 'Frequency & Schedule';
      case 2:
        return 'Categorize';
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
        return 'Tell us about your recurring expense';
      case 1:
        return 'How often does this expense occur?';
      case 2:
        return 'Help us organize your expense';
      case 3:
        return 'Add any extra information (optional)';
      case 4:
        return 'Review your recurring expense details';
      default:
        return '';
    }
  }

  Widget _buildStepContent(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildStep1WhatAndHowMuch(isDark);
      case 1:
        return _buildStep2FrequencyAndSchedule(isDark);
      case 2:
        return _buildStep3Categorize(isDark);
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
          hintText: 'e.g., Netflix Subscription, Gym Membership',
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
        SizedBox(height: 16.scaledVertical(context)),

        // Amount
        AmountInputField(
          controller: _amountController,
          label: 'Amount',
        ),
        SizedBox(height: 16.scaledVertical(context)),

        // Amount Type
        _buildAmountTypeSelector(isDark),
      ],
    );
  }

  Widget _buildStep2FrequencyAndSchedule(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frequency
        _buildFrequencySelector(isDark),
        SizedBox(height: 16.scaledVertical(context)),

        // Dates
        _buildDateSelector(
          'Start Date',
          _startDate,
          true,
          isDark,
        ),
        SizedBox(height: 10.scaledVertical(context)),
        _buildDateSelector(
          'End Date (Optional)',
          _endDate,
          false,
          isDark,
        ),
      ],
    );
  }

  Widget _buildStep3Categorize(bool isDark) {
    return Column(
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
        SizedBox(height: 16.scaledVertical(context)),

        // Description
        AppTextField(
          controller: _descriptionController,
          label: 'Description (Optional)',
          hintText: 'Add a description',
          maxLines: 3,
          prefixIcon: Icon(
            Icons.description_rounded,
            size: 18,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : AppTheme.textSecondary,
          ),
        ),
        SizedBox(height: 10.scaledVertical(context)),

        // Merchant
        AppTextField(
          controller: _merchantController,
          label: 'Merchant Name (Optional)',
          hintText: 'e.g., Netflix, Amazon',
          prefixIcon: Icon(
            Icons.store_rounded,
            size: 18,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : AppTheme.textSecondary,
          ),
        ),
        SizedBox(height: 16.scaledVertical(context)),

        // Options
        _buildToggleOption(
          'Auto-post when due',
          _autoPost,
          (value) => setState(() => _autoPost = value),
          isDark,
        ),
        SizedBox(height: 10.scaledVertical(context)),
        _buildToggleOption(
          'Send reminders',
          _sendReminders,
          (value) => setState(() => _sendReminders = value),
          isDark,
        ),
        if (_sendReminders) ...[
          SizedBox(height: 10.scaledVertical(context)),
          _buildReminderDaysSelector(isDark),
        ],
      ],
    );
  }

  Widget _buildStep5Review(bool isDark) {
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final currency = currencyAsync.valueOrNull ?? Currency.defaultCurrency;
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    final reminderDaysValue = _sendReminders && _selectedReminderDays.isNotEmpty
        ? () {
            final sortedDays = _selectedReminderDays.toList()..sort();
            return sortedDays
                .map((days) => '$days day${days > 1 ? 's' : ''} before')
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
                _buildReceiptRow('Amount', CurrencyFormatter.format(amount, currency), isDark),
                _buildReceiptDivider(isDark),
                _buildReceiptRow('Amount Type', _amountType.name.toUpperCase(), isDark),
                _buildReceiptDivider(isDark),
                _buildReceiptRow('Frequency', _frequency.name.toUpperCase(), isDark),
                _buildReceiptDivider(isDark),
                _buildReceiptRow('Start Date', DateFormat('MMM d, y').format(_startDate), isDark),
                if (_endDate != null) ...[
                  _buildReceiptDivider(isDark),
                  _buildReceiptRow('End Date', DateFormat('MMM d, y').format(_endDate!), isDark),
                ],
                _buildReceiptDivider(isDark),
                _buildReceiptRow('Category', _selectedCategory?.name ?? 'Not selected', isDark),
                if (_descriptionController.text.isNotEmpty) ...[
                  _buildReceiptDivider(isDark),
                  _buildReceiptRow('Description', _descriptionController.text.trim(), isDark),
                ],
                if (_merchantController.text.isNotEmpty) ...[
                  _buildReceiptDivider(isDark),
                  _buildReceiptRow('Merchant', _merchantController.text.trim(), isDark),
                ],
                _buildReceiptDivider(isDark),
                _buildReceiptRow('Auto-post', _autoPost ? 'Enabled' : 'Disabled', isDark),
                _buildReceiptDivider(isDark),
                _buildReceiptRow('Send Reminders', _sendReminders ? 'Enabled' : 'Disabled', isDark),
                if (reminderDaysValue != null) ...[
                  _buildReceiptDivider(isDark),
                  _buildReceiptRow('Reminder Days', reminderDaysValue, isDark),
                ],
              ],
            ),
          ),
          SizedBox(height: 16.scaledVertical(context)),
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
                    'This recurring expense will be included in your financial forecasts. If auto-post is enabled, expenses will be created automatically when due.',
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                          ? 'Create Expense'
                          : 'Continue',
                      style: AppFonts.textStyle(
                        fontSize: 16.scaledText(context),
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

  Widget _buildAmountTypeSelector(bool isDark) {
    return SelectionPillGroup(
      label: 'Amount Type',
      useWrap: false,
      spacing: 12,
      children: [
        SelectionPill(
          label: 'Fixed',
          description: 'Same amount each time',
          icon: Icons.attach_money_rounded,
          isSelected: _amountType == AmountType.fixed,
          onTap: () => setState(() => _amountType = AmountType.fixed),
          isExpanded: true,
        ),
        SelectionPill(
          label: 'Variable',
          description: 'Amount may vary',
          icon: Icons.trending_up_rounded,
          isSelected: _amountType == AmountType.variable,
          onTap: () => setState(() => _amountType = AmountType.variable),
          isExpanded: true,
        ),
      ],
    );
  }

  IconData _getFrequencyIcon(RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return Icons.today_rounded;
      case RecurrenceFrequency.weekly:
        return Icons.view_week_rounded;
      case RecurrenceFrequency.biweekly:
        return Icons.calendar_view_week_rounded;
      case RecurrenceFrequency.monthly:
        return Icons.calendar_month_rounded;
      case RecurrenceFrequency.quarterly:
        return Icons.event_repeat_rounded;
      case RecurrenceFrequency.yearly:
        return Icons.calendar_today_rounded;
    }
  }

  String _getFrequencyLabel(RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.biweekly:
        return 'Bi-weekly';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.quarterly:
        return 'Quarterly';
      case RecurrenceFrequency.yearly:
        return 'Yearly';
    }
  }

  Widget _buildFrequencySelector(bool isDark) {
    final frequencies = [
      RecurrenceFrequency.daily,
      RecurrenceFrequency.weekly,
      RecurrenceFrequency.biweekly,
      RecurrenceFrequency.monthly,
      RecurrenceFrequency.quarterly,
      RecurrenceFrequency.yearly,
    ];

    return SelectionPillGroup(
      label: 'Frequency',
      useWrap: true,
      children: frequencies.map((freq) {
        return SelectionPill(
          label: _getFrequencyLabel(freq),
          icon: _getFrequencyIcon(freq),
          isSelected: _frequency == freq,
          onTap: () => setState(() => _frequency = freq),
        );
      }).toList(),
    );
  }

  Widget _buildDateSelector(
    String label,
    DateTime? date,
    bool isStartDate,
    bool isDark,
  ) {
    // Use same background color logic as AppTextField with increased contrast
    final baseCardColor = isDark ? AppTheme.darkCardBackground : AppTheme.cardBackground;
    final backgroundColor = isDark
        ? Color.lerp(baseCardColor, Colors.white, 0.08) ?? baseCardColor
        : Color.lerp(baseCardColor, const Color(0xFFE5E7EB), 0.3) ?? baseCardColor;

    return GestureDetector(
      onTap: () => _selectDate(context, isStartDate),
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
              Icons.calendar_today_rounded,
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
            Text(
              date != null
                  ? DateFormat('MMM d, y').format(date)
                  : 'Not set',
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: date != null
                    ? (isDark ? Colors.white : AppTheme.textPrimary)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : AppTheme.textSecondary.withValues(alpha: 0.6)),
              ),
            ),
            if (date != null && !isStartDate) ...[
              SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _endDate = null),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
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
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderDaysSelector(bool isDark) {
    return SelectionPillGroup(
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

