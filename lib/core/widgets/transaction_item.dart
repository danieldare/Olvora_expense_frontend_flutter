import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../models/currency.dart';
import '../providers/api_providers_v2.dart';
import '../responsive/responsive_extensions.dart';
import '../../features/expenses/domain/entities/expense_entity.dart';
import '../../features/expenses/presentation/screens/transaction_details_screen.dart';
import '../../features/expenses/presentation/screens/add_expense_screen.dart';
import '../../features/expenses/presentation/providers/expenses_providers.dart';
import 'bottom_sheet_modal.dart';
import 'bottom_sheet_option_tile.dart';

/// Sleek, reusable Transaction Item Widget
///
/// A world-class transaction item component with:
/// - Colored category indicator bar
/// - Clean typography and spacing
/// - Flexible date formatting
/// - Consistent design across the app
class TransactionItem extends ConsumerWidget {
  final ExpenseEntity transaction;
  final Currency currency;
  final bool isDark;
  final DateFormatStyle dateFormatStyle;
  final VoidCallback? onTap;
  final bool showActions;

  const TransactionItem({
    super.key,
    required this.transaction,
    required this.currency,
    required this.isDark,
    this.dateFormatStyle = DateFormatStyle.relative,
    this.onTap,
    this.showActions = false,
  });

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return const Color(0xFF10B981); // Green
      case ExpenseCategory.transport:
        return const Color(0xFF3B82F6); // Blue
      case ExpenseCategory.entertainment:
        return const Color(0xFFEC4899); // Pink
      case ExpenseCategory.shopping:
        return const Color(0xFF8B5CF6); // Purple
      case ExpenseCategory.bills:
        return const Color(0xFF6366F1); // Indigo
      case ExpenseCategory.health:
        return const Color(0xFFEF4444); // Red
      case ExpenseCategory.education:
        return const Color(0xFF14B8A6); // Teal
      case ExpenseCategory.debit:
        return const Color(0xFFEA580C); // Orange
      case ExpenseCategory.other:
        return const Color(0xFF6B7280); // Gray
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_car_rounded;
      case ExpenseCategory.entertainment:
        return Icons.movie_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.bills:
        return Icons.receipt_rounded;
      case ExpenseCategory.health:
        return Icons.medical_services_rounded;
      case ExpenseCategory.education:
        return Icons.school_rounded;
      case ExpenseCategory.debit:
        return Icons.account_balance_wallet_rounded;
      case ExpenseCategory.other:
        return Icons.category_rounded;
    }
  }

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

  String _formatEntryMode(EntryMode entryMode) {
    switch (entryMode) {
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

  String _toSentenceCase(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark
        ? (Colors.grey[400] ?? Colors.grey)
        : AppTheme.textSecondary;
    final amountColor = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppTheme.textPrimary;
    final categoryColor = _getCategoryColor(transaction.category);

    // Match past trip row styling: prominent amount, clear hierarchy
    final paddingH = 16.0;
    final paddingV = 12.0;
    final iconSize = 20.0;
    final spacing = 10.0;
    final titleFontSize = 14.0;
    final subtitleFontSize = 11.0;
    final amountFontSize = 16.0;
    final rowGap = 6.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (showActions) {
            _showExpenseActions(context, ref);
          } else if (onTap != null) {
            onTap!();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TransactionDetailsScreen(transaction: transaction),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Category icon (no container)
              Icon(
                _getCategoryIcon(transaction.category),
                size: iconSize,
                color: categoryColor,
              ),
              SizedBox(width: spacing),
              // Transaction details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Merchant/Title - clean and prominent
                    Text(
                      _toSentenceCase(
                        transaction.merchant ?? transaction.title,
                      ),
                      style: AppFonts.textStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1),
                    // Entry mode and category - minimal
                    Row(
                      children: [
                        Text(
                          _formatEntryMode(transaction.entryMode),
                          style: AppFonts.textStyle(
                            fontSize: subtitleFontSize,
                            fontWeight: FontWeight.w400,
                            color: subtitleColor,
                          ),
                        ),
                        SizedBox(width: rowGap),
                        Text(
                          '•',
                          style: AppFonts.textStyle(
                            fontSize: subtitleFontSize,
                            color: subtitleColor.withValues(alpha: 0.5),
                          ),
                        ),
                        SizedBox(width: rowGap),
                        Text(
                          _formatCategory(transaction.category),
                          style: AppFonts.textStyle(
                            fontSize: subtitleFontSize,
                            fontWeight: FontWeight.w500,
                            color: categoryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing),
              // Amount - sleek and prominent (slightly brighter than title)
              Text(
                CurrencyFormatter.format(transaction.amount, currency),
                style: AppFonts.textStyle(
                  fontSize: amountFontSize,
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExpenseActions(BuildContext context, WidgetRef ref) {
    BottomSheetModal.show(
      context: context,
      title: transaction.merchant ?? transaction.title,
      subtitle: 'Manage expense',
      borderRadius: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomSheetOptionTile(
            icon: Icons.visibility_rounded,
            label: 'View Details',
            color: AppTheme.primaryColor,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TransactionDetailsScreen(transaction: transaction),
                ),
              );
            },
          ),
          const BottomSheetOptionDivider(),
          BottomSheetOptionTile(
            icon: Icons.edit_rounded,
            label: 'Edit',
            color: AppTheme.primaryColor,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddExpenseScreen(
                    existingExpense: transaction,
                    entryMode: EntryMode.manual,
                  ),
                ),
              );
            },
          ),
          const BottomSheetOptionDivider(),
          BottomSheetOptionTile(
            icon: Icons.share_rounded,
            label: 'Share',
            color: AppTheme.primaryColor,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionDetailsScreen(
                    transaction: transaction,
                    showShareModal: true,
                  ),
                ),
              );
            },
          ),
          const BottomSheetOptionDivider(),
          BottomSheetOptionTile(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: AppTheme.errorColor,
            useColorForText: true,
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context, ref);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DeleteConfirmationDialog(
        expenseName: transaction.merchant ?? transaction.title,
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final apiService = ref.read(apiServiceV2Provider);
      await apiService.dio.delete('/expenses/${transaction.id}');

      // Invalidate providers
      ref.invalidate(expensesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8.scaled(context)),
                Expanded(child: Text('Expense deleted successfully')),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete expense: ${e.toString()}'),
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
}

/// Date format style for transaction items
enum DateFormatStyle {
  /// Relative format: "Just now", "2 hours ago", "Yesterday", "Mon", "Jan 15"
  relative,

  /// Time format: "2:30 PM"
  time,

  /// Date and time format: "Jan 15, 2:30 PM"
  dateTime,
}

/// Delete confirmation dialog that requires typing "delete" to confirm
class _DeleteConfirmationDialog extends StatefulWidget {
  final String expenseName;

  const _DeleteConfirmationDialog({required this.expenseName});

  @override
  State<_DeleteConfirmationDialog> createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  final TextEditingController _confirmController = TextEditingController();
  bool _canDelete = false;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : AppTheme.textSecondary;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.scaled(context))),
      title: Text(
        'Delete Expense',
        style: AppFonts.textStyle(
          fontSize: 20.scaledText(context),
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete "${widget.expenseName}"?',
            style: AppFonts.textStyle(
              fontSize: 15.scaledText(context),
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
          ),
          SizedBox(height: 24.scaled(context)),
          Text(
            'This action cannot be undone. Type "delete" to confirm:',
            style: AppFonts.textStyle(
              fontSize: 14.scaledText(context),
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
          ),
          SizedBox(height: 12.scaled(context)),
          TextField(
            controller: _confirmController,
            autofocus: true,
            style: AppFonts.textStyle(
              fontSize: 16.scaledText(context),
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            decoration: InputDecoration(
              hintText: 'Type "delete"',
              hintStyle: AppFonts.textStyle(fontSize: 16.scaledText(context), color: subtitleColor),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppTheme.borderColor.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.scaled(context)),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.scaled(context)),
                borderSide: BorderSide(
                  color: _canDelete
                      ? AppTheme.errorColor
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppTheme.borderColor),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.scaled(context)),
                borderSide: BorderSide(
                  color: _canDelete
                      ? AppTheme.errorColor
                      : AppTheme.primaryColor,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              final newCanDelete = value.toLowerCase().trim() == 'delete';
              if (newCanDelete != _canDelete) {
                setState(() {
                  _canDelete = newCanDelete;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: AppFonts.textStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.accentColor,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _canDelete ? () => Navigator.pop(context, true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppTheme.errorColor.withValues(alpha: 0.5),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.scaled(context)),
            ),
          ),
          child: Text(
            'Delete',
            style: AppFonts.textStyle(
              fontSize: 16.scaledText(context),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
