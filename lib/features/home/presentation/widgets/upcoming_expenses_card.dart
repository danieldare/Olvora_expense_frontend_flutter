import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/models/currency.dart';
import '../../../expenses/domain/entities/future_expense_entity.dart';
import '../../../expenses/presentation/providers/future_expenses_providers.dart';
import '../../../expenses/presentation/screens/planned_expenses_screen.dart';

class UpcomingExpensesCard extends ConsumerWidget {
  const UpcomingExpensesCard({super.key});

  List<FutureExpenseEntity> _getUpcomingExpenses(
    List<FutureExpenseEntity> expenses,
  ) {
    final now = DateTime.now();
    final sevenDaysFromNow = now.add(const Duration(days: 7));

    return expenses
        .where((e) =>
            !e.isConverted &&
            e.expectedDate.isAfter(now) &&
            e.expectedDate.isBefore(sevenDaysFromNow))
        .toList()
      ..sort((a, b) {
        // Sort by priority first (critical > high > medium > low)
        final priorityOrder = {
          FutureExpensePriority.critical: 0,
          FutureExpensePriority.high: 1,
          FutureExpensePriority.medium: 2,
          FutureExpensePriority.low: 3,
        };
        final priorityDiff =
            priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
        if (priorityDiff != 0) return priorityDiff;

        // Then by date
        return a.expectedDate.compareTo(b.expectedDate);
      });
  }

  Color _getPriorityColor(FutureExpensePriority priority) {
    switch (priority) {
      case FutureExpensePriority.critical:
        return AppTheme.errorColor;
      case FutureExpensePriority.high:
        return Colors.orange;
      case FutureExpensePriority.medium:
        return AppTheme.warningColor;
      case FutureExpensePriority.low:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow';
    } else {
      final difference = dateOnly.difference(today).inDays;
      if (difference <= 7) {
        return DateFormat('EEE, MMM d').format(date);
      } else {
        return DateFormat('MMM d').format(date);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCardBackground : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark ? Colors.grey[400] : AppTheme.textSecondary;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppTheme.borderColor.withValues(alpha: 0.5);

    final futureExpensesAsync = ref.watch(futureExpensesProvider);
    final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
    final currency =
        selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;

    // Use skipLoadingOnRefresh to prevent flickering when data refreshes
    return futureExpensesAsync.when(
      skipLoadingOnRefresh: true,
      data: (expenses) {
        final upcomingExpenses = _getUpcomingExpenses(expenses);

        if (upcomingExpenses.isEmpty) {
          return const SizedBox.shrink();
        }

        final criticalCount = upcomingExpenses
            .where((e) => e.priority == FutureExpensePriority.critical)
            .length;
        final totalAmount = upcomingExpenses.fold<double>(
          0.0,
          (sum, e) => sum + e.expectedAmount,
        );

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlannedExpensesScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: criticalCount > 0
                              ? AppTheme.errorColor.withValues(alpha: 0.1)
                              : AppTheme.warningColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          criticalCount > 0
                              ? Icons.warning_rounded
                              : Icons.calendar_today_rounded,
                          color: criticalCount > 0
                              ? AppTheme.errorColor
                              : AppTheme.warningColor,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upcoming Expenses',
                              style: AppFonts.textStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '${upcomingExpenses.length} expense${upcomingExpenses.length != 1 ? 's' : ''} due in 7 days',
                              style: AppFonts.textStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: subtitleColor,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Top 3 expenses
                  ...upcomingExpenses.take(3).map((expense) {
                    final priorityColor = _getPriorityColor(expense.priority);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 32,
                            decoration: BoxDecoration(
                              color: priorityColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expense.title,
                                  style: AppFonts.textStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 10,
                                      color: subtitleColor,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      _formatDate(expense.expectedDate),
                                      style: AppFonts.textStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: subtitleColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(
                              expense.expectedAmount,
                              currency,
                            ),
                            style: AppFonts.textStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (upcomingExpenses.length > 3) ...[
                    SizedBox(height: 4),
                    Text(
                      '+ ${upcomingExpenses.length - 3} more',
                      style: AppFonts.textStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                  SizedBox(height: 8),
                  // Total amount
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : AppTheme.borderColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Due',
                          style: AppFonts.textStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: subtitleColor,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(totalAmount, currency),
                          style: AppFonts.textStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

