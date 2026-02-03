import 'package:flutter/material.dart';
import '../../../../core/widgets/app_back_button.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/expense_entity.dart';
import 'add_expense_screen.dart';
import 'add_recurring_expense_screen.dart';
import 'add_future_expense_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';

/// Expense Type Selection Screen
///
/// Shown when user taps "Add Expense" to select the type:
/// - One-time Expense (past transaction)
/// - Recurring Expense (repeating pattern)
/// - Future Expense (planned expense)
class ExpenseTypeSelectionScreen extends StatelessWidget {
  /// If true, this is the first expense after signup - navigate to home after
  final bool isFirstExpense;

  const ExpenseTypeSelectionScreen({super.key, this.isFirstExpense = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppTheme.screenBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(
          onPressed: () {
            // Always navigate to HomeScreen to avoid going back to
            // loading/processing screens that may have been replaced
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
        title: Text(
          'Add Expense',
          style: AppFonts.textStyle(
            fontSize: 18.scaledText(context),
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                16.scaled(context),
                AppSpacing.screenHorizontal,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Expense Type',
                    style: AppFonts.textStyle(
                      fontSize: 18.scaledText(context),
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 6.scaled(context)),
                  Text(
                    'Choose the type of expense you want to add',
                    style: AppFonts.textStyle(
                      fontSize: 13.scaledText(context),
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.scaledVertical(context)),
            Expanded(
              child: ListView.separated(
                  itemCount: 3,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppTheme.borderColor.withValues(alpha: 0.3),
                  ),
                  itemBuilder: (context, index) {
                    final expenseTypes = [
                      {
                        'title': 'One-time Expense',
                        'description': 'A transaction that already occurred',
                        'icon': Icons.receipt_long_rounded,
                        'color': AppTheme.primaryColor,
                        'onTap': () {
                          HapticFeedback.mediumImpact();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddExpenseScreen(
                                entryMode: EntryMode.manual,
                                isFirstExpense: isFirstExpense,
                              ),
                            ),
                          );
                        },
                      },
                      {
                        'title': 'Recurring Expense',
                        'description':
                            'A repeating expense (subscription, rent, etc.)',
                        'icon': Icons.repeat_rounded,
                        'color': AppTheme.accentColor,
                        'onTap': () {
                          HapticFeedback.mediumImpact();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddRecurringExpenseScreen(
                                isFirstExpense: isFirstExpense,
                              ),
                            ),
                          );
                        },
                      },
                      {
                        'title': 'Future Expense',
                        'description': 'A planned expense (not yet occurred)',
                        'icon': Icons.calendar_today_rounded,
                        'color': AppTheme.warningColor,
                        'onTap': () {
                          HapticFeedback.mediumImpact();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddFutureExpenseScreen(
                                isFirstExpense: isFirstExpense,
                              ),
                            ),
                          );
                        },
                      },
                    ];

                    final expenseType = expenseTypes[index];

                    return InkWell(
                      onTap: expenseType['onTap'] as VoidCallback,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenHorizontal,
                          vertical: 10.scaledVertical(context),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12.scaled(context)),
                        ),
                        child: Row(
                            children: [
                              // Icon
                              Container(
                              width: 32.scaledMin(context, 38),
                              height: 32.scaledMin(context, 38),
                              decoration: BoxDecoration(
                                color: (expenseType['color'] as Color)
                                    .withValues(alpha: isDark ? 0.15 : 0.08),
                                borderRadius: BorderRadius.circular(8.scaled(context)),
                              ),
                              child: Center(
                                child: Icon(
                                  expenseType['icon'] as IconData,
                                  color: expenseType['color'] as Color,
                                  size: 18.scaled(context),
                                ),
                              ),
                            ),
                            SizedBox(width: 10.scaled(context)),
                            // Title and description
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expenseType['title'] as String,
                                    style: AppFonts.textStyle(
                                      fontSize: 14.scaledText(context),
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2.scaled(context)),
                                  Text(
                                    expenseType['description'] as String,
                                    style: AppFonts.textStyle(
                                      fontSize: 11.scaledText(context),
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.6)
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Arrow indicator
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14.scaled(context),
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : AppTheme.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
    );
  }
}

