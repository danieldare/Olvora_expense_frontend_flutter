import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/models/currency.dart';
import '../providers/report_providers.dart';

class TopExpensesList extends ConsumerStatefulWidget {
  final ReportDateRangeParams dateRangeParams;
  final Currency currency;

  const TopExpensesList({
    super.key,
    required this.dateRangeParams,
    required this.currency,
  });

  @override
  ConsumerState<TopExpensesList> createState() => _TopExpensesListState();
}

class _TopExpensesListState extends ConsumerState<TopExpensesList> {
  // Cache previous data to prevent flickering during refresh
  List? _lastTransactions;
  bool _hasInitialData = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overviewAsync = ref.watch(
      spendingOverviewProvider(widget.dateRangeParams),
    );

    // Show error state only if there's an error AND no cached data
    if (overviewAsync.hasError && !_hasInitialData) {
      return _buildErrorState(context, isDark);
    }

    // Get current transactions or fall back to cached data
    final data = overviewAsync.valueOrNull;
    final transactions = data?['transactions'] as List? ?? _lastTransactions;

    // Only show empty state on initial load with no data
    if (transactions == null || (transactions.isEmpty && !_hasInitialData)) {
      if (overviewAsync.isLoading) {
        return _buildLoadingState(isDark);
      }
      return _buildEmptyState();
    }

    // Cache the data for future refreshes
    if (overviewAsync.hasValue && data != null) {
      _lastTransactions = data['transactions'] as List;
      _hasInitialData = true;
    }

    if (transactions.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: transactions.asMap().entries.map((entry) {
            final index = entry.key;
            final expense = entry.value;
            final isLast = index == transactions.length - 1;

            return _TopExpenseItem(
              expense: expense,
              rank: index + 1,
              currency: widget.currency,
              isDark: isDark,
              isLast: isLast,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: EmptyStateWidget.compact(
        icon: Icons.receipt_long_outlined,
        title: 'No expenses found',
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.borderColor,
            width: 1,
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.borderColor,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 32,
              color: AppTheme.errorColor,
            ),
            SizedBox(height: 12),
            Text(
              'Failed to load expenses',
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(
                spendingOverviewProvider(widget.dateRangeParams),
              ),
              icon: Icon(Icons.refresh_rounded, size: 16),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopExpenseItem extends StatelessWidget {
  final dynamic expense;
  final int rank;
  final Currency currency;
  final bool isDark;
  final bool isLast;

  const _TopExpenseItem({
    required this.expense,
    required this.rank,
    required this.currency,
    required this.isDark,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final amount = expense.amount as double;
    final title = expense.title as String;
    final date = expense.date as DateTime;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppTheme.borderColor,
                  width: 1,
                ),
              ),
      ),
      child: Row(
        children: [
          // Rank badge - compact
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppTheme.borderColor),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: AppFonts.textStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: rank <= 3
                      ? AppTheme.primaryColor
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppTheme.textSecondary),
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          // Expense details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppFonts.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  DateFormat('MMM d, yyyy').format(date),
                  style: AppFonts.textStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            CurrencyFormatter.format(amount, currency),
            style: AppFonts.textStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
