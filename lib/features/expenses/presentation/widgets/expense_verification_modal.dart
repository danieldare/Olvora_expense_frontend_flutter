import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/bottom_sheet_modal.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../../core/services/notification_detection_service.dart';
import '../../domain/entities/expense_entity.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/models/currency.dart';
import '../../presentation/providers/expenses_providers.dart';

class ExpenseVerificationModal extends ConsumerStatefulWidget {
  final DetectedExpense detectedExpense;

  const ExpenseVerificationModal({super.key, required this.detectedExpense});

  @override
  ConsumerState<ExpenseVerificationModal> createState() =>
      _ExpenseVerificationModalState();

  static void show(BuildContext context, DetectedExpense detectedExpense) {
    BottomSheetModal.show(
      context: context,
      title: 'Verify Expense',
      subtitle: 'Review and confirm the detected expense',
      child: ExpenseVerificationModal(detectedExpense: detectedExpense),
      maxHeightFraction: 0.9,
    );
  }
}

class _ExpenseVerificationModalState
    extends ConsumerState<ExpenseVerificationModal> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;
  File? _selectedAttachment;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    // Format amount with proper decimal places
    final amount = widget.detectedExpense.amount;
    _amountController.text = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);

    _merchantController.text = widget.detectedExpense.merchant ?? '';
    _descriptionController.text = widget.detectedExpense.description ?? '';
    _selectedDate = widget.detectedExpense.timestamp;

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

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectCategory() async {
    // Load categories using provider
    final categoriesAsync = ref.read(categoriesProvider);
    final categories = categoriesAsync.when(
      data: (data) => data,
      loading: () => <CategoryModel>[],
      error: (_, __) => <CategoryModel>[],
    );

    if (!mounted) return;

    final selected = await BottomSheetModal.show<CategoryModel>(
      context: context,
      title: 'Select Category',
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return ListTile(
            title: Text(
              category.name,
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            onTap: () => Navigator.pop(context, category),
          );
        },
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedCategory = selected;
      });
    }
  }

  ExpenseCategory _mapCategoryToExpenseCategory(CategoryModel category) {
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

  Future<String?> _uploadAttachment() async {
    if (_selectedAttachment == null) return null;

    try {
      final apiService = ref.read(apiServiceV2Provider);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          _selectedAttachment!.path,
          filename: _selectedAttachment!.path.split('/').last,
        ),
      });

      final response = await apiService.dio.post(
        '/expenses/attachments',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      // Handle response wrapper if needed
      dynamic actualData = response.data;
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap.containsKey('data') && responseMap['data'] != null) {
          actualData = responseMap['data'];
        }
      }

      return actualData['url'] as String?;
    } catch (e) {
      debugPrint('Error uploading attachment: $e');
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedAttachment = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _saveExpense() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid amount'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      if (!mounted) return;
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

      // Upload attachment if selected
      String? attachmentUrl;
      if (_selectedAttachment != null) {
        attachmentUrl = await _uploadAttachment();
        if (attachmentUrl == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to upload attachment. Continuing without it.'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        }
      }

      // Build expense data with proper validation
      final title = _merchantController.text.trim().isNotEmpty
          ? _merchantController.text.trim()
          : (_descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : _selectedCategory!.name);

      // Combine description and note if both exist
      String? description;
      if (_descriptionController.text.trim().isNotEmpty) {
        description = _descriptionController.text.trim();
        if (_noteController.text.trim().isNotEmpty) {
          description = '$description\n\nNote: ${_noteController.text.trim()}';
        }
      } else if (_noteController.text.trim().isNotEmpty) {
        description = _noteController.text.trim();
      }

      // Get user preference currency
      final currency = ref.read(selectedCurrencyProvider).valueOrNull ?? Currency.defaultCurrency;

      final expenseData = {
        'title': title,
        'amount': amount,
        'category': expenseCategory.name.toLowerCase(),
        'date': _selectedDate.toIso8601String().split('T')[0],
        'entryMode': 'notification',
        'currency': currency.code, // Always include currency from user preference
        if (description != null) 'description': description,
        if (_merchantController.text.trim().isNotEmpty)
          'merchant': _merchantController.text.trim(),
        if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      };

      await apiService.dio.post('/expenses', data: expenseData);

      // Invalidate expenses providers to refresh the lists
      ref.invalidate(expensesProvider);
      ref.invalidate(recentTransactionsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Expense saved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save expense: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Notification preview
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.darkCardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications,
                      color: AppTheme.warningColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Detected from Notification',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  widget.detectedExpense.notificationText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Amount field
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Amount',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              prefixIcon: Icon(Icons.attach_money, color: Colors.white70),
              filled: true,
              fillColor: AppTheme.darkCardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 16),

          // Merchant field
          TextField(
            controller: _merchantController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Merchant/Store',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              prefixIcon: Icon(Icons.store, color: Colors.white70),
              filled: true,
              fillColor: AppTheme.darkCardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 16),

          // Description field
          TextField(
            controller: _descriptionController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Description',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              prefixIcon: Icon(Icons.description, color: Colors.white70),
              filled: true,
              fillColor: AppTheme.darkCardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 16),

          // Category selection
          GestureDetector(
            onTap: _selectCategory,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkCardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.category, color: Colors.white70),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedCategory?.name ?? 'Select Category',
                      style: TextStyle(
                        color: _selectedCategory != null
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Date selection
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkCardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.white70),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Attachment field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attachment (Optional)',
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkCardBackground
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : AppTheme.borderColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedAttachment != null
                            ? Icons.image
                            : Icons.add_photo_alternate_outlined,
                        color: _selectedAttachment != null
                            ? AppTheme.warningColor
                            : (isDark ? Colors.white70 : AppTheme.textSecondary),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedAttachment != null
                              ? _selectedAttachment!.path.split('/').last
                              : 'Add receipt or image',
                          style: TextStyle(
                            color: _selectedAttachment != null
                                ? (isDark ? Colors.white : AppTheme.textPrimary)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : AppTheme.textSecondary),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_selectedAttachment != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAttachment = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: AppTheme.errorColor,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_selectedAttachment != null) ...[
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedAttachment!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 16),

          // Note field (optional)
          TextField(
            controller: _noteController,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Note (Optional)',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              prefixIcon: Icon(Icons.note, color: Colors.white70),
              filled: true,
              fillColor: AppTheme.darkCardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warningColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          child: LoadingSpinnerVariants.black(
                            size: 20,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Expense',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
