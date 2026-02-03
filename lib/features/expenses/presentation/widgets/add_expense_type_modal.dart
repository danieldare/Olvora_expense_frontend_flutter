import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_option_row.dart';
import '../../../../core/widgets/bottom_sheet_modal.dart';
import '../../domain/entities/expense_entity.dart';
import '../screens/add_expense_screen.dart';
import '../screens/add_recurring_expense_screen.dart';
import '../screens/add_future_expense_screen.dart';

/// Add Expense Type Modal
///
/// Bottom modal that allows users to select from 3 expense entry types:
/// - One-time Expense
/// - Recurring Expense
/// - Future Expense
class AddExpenseTypeModal extends StatelessWidget {
  const AddExpenseTypeModal({super.key});

  /// Show the add expense type modal
  static Future<void> show({required BuildContext context}) {
    return BottomSheetModal.show(
      context: context,
      title: 'Add Expense',
      subtitle: 'Select the type of expense you want to add',
      maxHeightFraction: 0.5,
      isScrollable: false,
      child: const AddExpenseTypeModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppOptionRow(
          title: 'One-time Expense',
          subtitle: 'A transaction that already occurred',
          icon: Icons.receipt_long_rounded,
          color: AppTheme.primaryColor,
          dense: true,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddExpenseScreen(
                  entryMode: EntryMode.manual,
                ),
              ),
            );
          },
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor.withValues(alpha: 0.3),
        ),
        AppOptionRow(
          title: 'Recurring Expense',
          subtitle: 'A repeating expense (subscription, rent, etc.)',
          icon: Icons.repeat_rounded,
          color: AppTheme.accentColor,
          dense: true,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddRecurringExpenseScreen(),
              ),
            );
          },
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor.withValues(alpha: 0.3),
        ),
        AppOptionRow(
          title: 'Future Expense',
          subtitle: 'A planned expense (not yet occurred)',
          icon: Icons.calendar_today_rounded,
          color: AppTheme.warningColor,
          dense: true,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddFutureExpenseScreen(),
              ),
            );
          },
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}
