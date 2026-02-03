import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_fonts.dart';
import '../theme/app_theme.dart';
import '../services/expense_parsing/parsed_expense_result.dart';
import '../services/expense_parsing/confidence_scorer.dart';

/// Result from the expense preview modal
class ExpensePreviewResult {
  /// Whether the user confirmed the expense
  final bool confirmed;

  /// The (possibly edited) expense result
  final ParsedExpenseResult result;

  /// Whether user selected "don't ask again" for similar transactions
  final bool dontAskAgain;

  ExpensePreviewResult({
    required this.confirmed,
    required this.result,
    this.dontAskAgain = false,
  });
}

/// A modal that shows a preview of a detected expense and allows the user
/// to confirm, edit, or dismiss it.
///
/// This modal is shown when an expense is detected from SMS, clipboard,
/// or voice input with medium confidence (70-89%).
class ExpensePreviewModal extends StatefulWidget {
  /// The parsed expense result to preview
  final ParsedExpenseResult result;

  /// Whether to show the "don't ask again" checkbox
  final bool showDontAskAgain;

  /// Callback when user wants to edit fields
  final VoidCallback? onEditRequested;

  const ExpensePreviewModal({
    super.key,
    required this.result,
    this.showDontAskAgain = true,
    this.onEditRequested,
  });

  /// Show the expense preview modal
  static Future<ExpensePreviewResult?> show({
    required BuildContext context,
    required ParsedExpenseResult result,
    bool showDontAskAgain = true,
    VoidCallback? onEditRequested,
  }) async {
    return showModalBottomSheet<ExpensePreviewResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpensePreviewModal(
        result: result,
        showDontAskAgain: showDontAskAgain,
        onEditRequested: onEditRequested,
      ),
    );
  }

  @override
  State<ExpensePreviewModal> createState() => _ExpensePreviewModalState();
}

class _ExpensePreviewModalState extends State<ExpensePreviewModal> {
  late ParsedExpenseResult _result;
  bool _dontAskAgain = false;
  bool _isEditing = false;

  // Controllers for inline editing
  late TextEditingController _amountController;
  late TextEditingController _merchantController;
  late TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _result = widget.result;
    _amountController = TextEditingController(
      text: _result.amount?.toStringAsFixed(2) ?? '',
    );
    _merchantController = TextEditingController(
      text: _result.merchant ?? '',
    );
    _categoryController = TextEditingController(
      text: _result.category ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _updateResult() {
    setState(() {
      _result = _result.copyWith(
        amount: double.tryParse(_amountController.text),
        merchant: _merchantController.text.isNotEmpty
            ? _merchantController.text
            : null,
        category: _categoryController.text.isNotEmpty
            ? _categoryController.text
            : null,
      );
    });
  }

  void _confirmExpense() {
    _updateResult();
    Navigator.pop(
      context,
      ExpensePreviewResult(
        confirmed: true,
        result: _result,
        dontAskAgain: _dontAskAgain,
      ),
    );
  }

  void _dismiss() {
    Navigator.pop(
      context,
      ExpensePreviewResult(
        confirmed: false,
        result: _result,
        dontAskAgain: _dontAskAgain,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCardBackground : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark ? Colors.grey[400] : AppTheme.textSecondary;
    final confidenceColor = _getConfidenceColor(_result.confidence);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: subtitleColor?.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getSourceIcon(_result.source),
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expense Detected',
                          style: AppFonts.textStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getSourceLabel(_result.source),
                          style: AppFonts.textStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: subtitleColor,
                      size: 22,
                    ),
                    onPressed: _dismiss,
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  // Amount field
                  _buildFieldRow(
                    icon: Icons.attach_money_rounded,
                    label: 'Amount',
                    value: _result.formattedAmount.isNotEmpty
                        ? _result.formattedAmount
                        : 'Not detected',
                    isEditing: _isEditing,
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    isEmpty: _result.amount == null,
                  ),

                  const SizedBox(height: 12),

                  // Merchant field
                  _buildFieldRow(
                    icon: Icons.store_rounded,
                    label: 'Merchant',
                    value: _result.merchant ?? 'Not detected',
                    isEditing: _isEditing,
                    controller: _merchantController,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    isEmpty: _result.merchant == null,
                  ),

                  const SizedBox(height: 12),

                  // Date field
                  _buildFieldRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: _result.date != null
                        ? _formatDate(_result.date!)
                        : 'Today',
                    isEditing: false, // Date editing not supported inline
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    isEmpty: _result.date == null,
                  ),

                  const SizedBox(height: 12),

                  // Category field (if detected)
                  if (_result.category != null || _isEditing)
                    _buildFieldRow(
                      icon: Icons.category_rounded,
                      label: 'Category',
                      value: _result.category ?? 'Not detected',
                      isEditing: _isEditing,
                      controller: _categoryController,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      isEmpty: _result.category == null,
                    ),

                  const SizedBox(height: 16),

                  // Confidence indicator
                  _buildConfidenceIndicator(confidenceColor, textColor, subtitleColor),

                  const SizedBox(height: 16),

                  // Don't ask again checkbox
                  if (widget.showDontAskAgain && _result.confidence >= 0.85)
                    _buildDontAskAgainCheckbox(textColor, subtitleColor),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Primary button - Add Expense
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _result.hasAmount ? _confirmExpense : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Add Expense',
                        style: AppFonts.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Secondary buttons row
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() => _isEditing = !_isEditing);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            _isEditing ? 'Done Editing' : 'Edit First',
                            style: AppFonts.textStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: subtitleColor?.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: _dismiss,
                          style: TextButton.styleFrom(
                            foregroundColor: subtitleColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Dismiss',
                            style: AppFonts.textStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: subtitleColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isEditing,
    required Color? textColor,
    required Color? subtitleColor,
    bool isEmpty = false,
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppTheme.primaryColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEmpty
              ? AppTheme.warningColor.withValues(alpha: 0.3)
              : isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppTheme.borderColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isEmpty ? AppTheme.warningColor : AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.textStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                if (isEditing && controller != null)
                  TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    style: AppFonts.textStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => _updateResult(),
                  )
                else
                  Text(
                    value,
                    style: AppFonts.textStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isEmpty
                          ? subtitleColor?.withValues(alpha: 0.7)
                          : textColor,
                    ),
                  ),
              ],
            ),
          ),
          if (isEditing && controller != null)
            Icon(
              Icons.edit_rounded,
              size: 16,
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(
    Color confidenceColor,
    Color? textColor,
    Color? subtitleColor,
  ) {
    final percentage = (_result.confidence * 100).round();
    final barWidth = _result.confidence;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: confidenceColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: confidenceColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Confidence',
                style: AppFonts.textStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor,
                ),
              ),
              Text(
                '$percentage%',
                style: AppFonts.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: confidenceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: barWidth,
              backgroundColor: confidenceColor.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(confidenceColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getConfidenceMessage(_result.confidence),
            style: AppFonts.textStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDontAskAgainCheckbox(Color? textColor, Color? subtitleColor) {
    return GestureDetector(
      onTap: () => setState(() => _dontAskAgain = !_dontAskAgain),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _dontAskAgain
              ? AppTheme.successColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _dontAskAgain
                ? AppTheme.successColor.withValues(alpha: 0.3)
                : subtitleColor?.withValues(alpha: 0.2) ?? Colors.grey,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: _dontAskAgain
                    ? AppTheme.successColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: _dontAskAgain
                      ? AppTheme.successColor
                      : subtitleColor ?? Colors.grey,
                  width: 1.5,
                ),
              ),
              child: _dontAskAgain
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Auto-add similar transactions in the future',
                style: AppFonts.textStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _dontAskAgain ? textColor : subtitleColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    final colorType = ConfidenceScorer.getConfidenceColor(confidence);
    switch (colorType) {
      case ConfidenceColor.green:
        return AppTheme.successColor;
      case ConfidenceColor.yellow:
        return const Color(0xFFF59E0B); // Amber
      case ConfidenceColor.orange:
        return AppTheme.warningColor;
      case ConfidenceColor.red:
        return AppTheme.errorColor;
    }
  }

  String _getConfidenceMessage(double confidence) {
    if (confidence >= 0.90) {
      return 'High confidence - all key fields detected';
    } else if (confidence >= 0.70) {
      return 'Good confidence - please verify the details';
    } else if (confidence >= 0.50) {
      return 'Some fields may need correction';
    } else {
      return 'Low confidence - manual entry recommended';
    }
  }

  IconData _getSourceIcon(ParsingSource source) {
    switch (source) {
      case ParsingSource.sms:
        return Icons.sms_rounded;
      case ParsingSource.clipboard:
        return Icons.content_paste_rounded;
      case ParsingSource.voice:
        return Icons.mic_rounded;
      case ParsingSource.receipt:
        return Icons.receipt_long_rounded;
      case ParsingSource.manual:
        return Icons.edit_rounded;
    }
  }

  String _getSourceLabel(ParsingSource source) {
    switch (source) {
      case ParsingSource.sms:
        return 'From notification';
      case ParsingSource.clipboard:
        return 'From clipboard';
      case ParsingSource.voice:
        return 'From voice input';
      case ParsingSource.receipt:
        return 'From receipt';
      case ParsingSource.manual:
        return 'Manual entry';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today, ${DateFormat.jm().format(date)}';
    } else if (dateOnly == yesterday) {
      return 'Yesterday, ${DateFormat.jm().format(date)}';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}
