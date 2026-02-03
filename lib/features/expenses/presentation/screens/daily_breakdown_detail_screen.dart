import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/models/currency.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import '../../domain/entities/detailed_weekly_summary_entity.dart';
import '../providers/expenses_providers.dart';
import '../../domain/entities/expense_entity.dart';

/// Daily Breakdown Detail Screen
/// Shows all expenses for a specific day with category breakdown
class DailyBreakdownDetailScreen extends ConsumerWidget {
  final DailyBreakdown day;
  final Currency currency;

  const DailyBreakdownDetailScreen({
    super.key,
    required this.day,
    required this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      backgroundColor: AppTheme.screenBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(),
        title: Text(
          DateFormat('EEEE, MMM d').format(day.date),
          style: AppFonts.textStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
      body: expensesAsync.when(
        data: (expenses) {
          // Filter expenses for this day
          final dayExpenses = expenses.where((expense) {
            final expenseDate = DateTime(
              expense.date.year,
              expense.date.month,
              expense.date.day,
            );
            final targetDate = DateTime(
              day.date.year,
              day.date.month,
              day.date.day,
            );
            return expenseDate == targetDate;
          }).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Summary Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    8,
                    AppSpacing.screenHorizontal,
                    20,
                  ),
                  child: _SummaryCard(
                    day: day,
                    currency: currency,
                    isDark: isDark,
                  ),
                ),
              ),

              // Expenses List
              if (dayExpenses.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 64.scaled(context),
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : AppTheme.textSecondary.withValues(alpha: 0.3),
                        ),
                        SizedBox(height: 16.scaledVertical(context)),
                        Text(
                          'No expenses recorded',
                          style: AppFonts.textStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final expense = dayExpenses[index];
                        final isLast = index == dayExpenses.length - 1;

                        return Column(
                          children: [
                            _ExpenseItem(
                              expense: expense,
                              currency: currency,
                              isDark: isDark,
                            ),
                            if (!isLast)
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : AppTheme.borderColor.withValues(alpha: 0.3),
                                indent: 0,
                                endIndent: 0,
                              ),
                          ],
                        );
                      },
                      childCount: dayExpenses.length,
                    ),
                  ),
                ),

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.bottomNavPadding),
              ),
            ],
          );
        },
        loading: () => Center(
          child: LoadingSpinner.medium(color: AppTheme.primaryColor),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48.scaled(context),
                color: AppTheme.errorColor,
              ),
              SizedBox(height: 16),
              Text(
                'Failed to load expenses',
                style: AppFonts.textStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Summary Card for the day
class _SummaryCard extends StatelessWidget {
  final DailyBreakdown day;
  final Currency currency;
  final bool isDark;

  const _SummaryCard({
    required this.day,
    required this.currency,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20.scaled(context)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Spent',
            style: AppFonts.textStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 8.scaled(context)),
          Text(
            CurrencyFormatter.format(day.totalSpent, currency),
            style: AppFonts.textStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppTheme.textPrimary,
              letterSpacing: -1.5,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _StatItem(
                label: 'Transactions',
                value: '${day.transactionCount}',
                isDark: isDark,
              ),
              if (day.topCategory != null) ...[
                SizedBox(width: 24),
                _StatItem(
                  label: 'Top Category',
                  value: day.topCategory!,
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _StatItem({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.textStyle(
            fontSize: 12.scaledText(context),
            fontWeight: FontWeight.w500,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : AppTheme.textSecondary,
          ),
        ),
        SizedBox(height: 4.scaled(context)),
        Text(
          value,
          style: AppFonts.textStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Expense Item
class _ExpenseItem extends StatelessWidget {
  final ExpenseEntity expense;
  final Currency currency;
  final bool isDark;

  const _ExpenseItem({
    required this.expense,
    required this.currency,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.scaledVertical(context)),
      child: Row(
        children: [
          // Category icon/color
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.category_rounded,
              color: AppTheme.primaryColor,
              size: 22,
            ),
          ),
          SizedBox(width: 14),
          // Expense details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: AppFonts.textStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.scaled(context)),
                Row(
                  children: [
                    Text(
                      expense.category.name,
                      style: AppFonts.textStyle(
                        fontSize: 12.scaledText(context),
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : AppTheme.textSecondary,
                      ),
                    ),
                    if (expense.merchant != null) ...[
                      Text(
                        ' • ',
                        style: AppFonts.textStyle(
                          fontSize: 12.scaledText(context),
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : AppTheme.textSecondary.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                    if (expense.merchant != null)
                      Text(
                        expense.merchant!,
                        style: AppFonts.textStyle(
                          fontSize: 12.scaledText(context),
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          // Amount
          Text(
            CurrencyFormatter.format(expense.amount, currency),
            style: AppFonts.textStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
