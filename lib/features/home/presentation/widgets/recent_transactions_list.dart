import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/models/currency.dart';
import '../../../../core/widgets/transaction_list_card.dart';
import '../../../../core/widgets/transaction_item.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../expenses/presentation/providers/expenses_providers.dart';

class RecentTransactionsList extends ConsumerStatefulWidget {
  final List<ExpenseEntity>? transactions;
  final VoidCallback? onSeeAll;

  const RecentTransactionsList({
    super.key,
    this.transactions,
    this.onSeeAll,
  });

  @override
  ConsumerState<RecentTransactionsList> createState() =>
      _RecentTransactionsListState();
}

class _RecentTransactionsListState
    extends ConsumerState<RecentTransactionsList> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;

    // Get selected currency
    final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
    final currency =
        selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;

    // Fetch only the last 3 transactions from provider
    final expensesAsync = ref.watch(recentTransactionsProvider);

    // Use skipLoadingOnRefresh to prevent flickering when data is refreshed
    final displayTransactions = expensesAsync.when(
      skipLoadingOnRefresh: true,
      data: (recentExpenses) {
        // Return actual data from API, even if empty
        return recentExpenses;
      },
      loading: () => null,
      error: (_, __) => null,
    );

    // Use provided transactions, or fetched transactions (no mock data fallback)
    final finalTransactions = widget.transactions ?? displayTransactions ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with toggle and view all
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Recent Expenses',
                  style: AppFonts.textStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: -0.8,
                  ),
                ),
                if (finalTransactions.isNotEmpty) ...[
                  SizedBox(width: 6),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18.0,
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (widget.onSeeAll != null && finalTransactions.isNotEmpty)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onSeeAll,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: AppFonts.textStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Transaction list (collapsible)
        AnimatedCrossFade(
          firstChild: finalTransactions.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildTransactionsList(
                    finalTransactions,
                    currency,
                    isDark,
                  ),
                )
              : displayTransactions != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildEmptyState(isDark),
                )
              : const SizedBox.shrink(),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : AppTheme.textSecondary.withValues(alpha: 0.4),
            ),
            SizedBox(height: 16),
            Text(
              'No recent transactions',
              style: AppFonts.textStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700, // Increased from w600
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Your recent expenses will appear here',
              style: AppFonts.textStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500, // Increased from w400
                // Enhanced contrast
                color: isDark ? Colors.grey[300]! : AppTheme.textSecondary.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(
    List<ExpenseEntity> transactions,
    Currency currency,
    bool isDark,
  ) {
    // Same card as transaction list; tap goes straight to transaction details (no options modal)
    return TransactionListCard(
      transactions: transactions,
      currency: currency,
      isDark: isDark,
      showActions: false,
      dateFormatStyle: DateFormatStyle.time,
    );
  }
}
