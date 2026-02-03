import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../../core/widgets/transaction_list_card.dart';
import '../../../../core/widgets/transaction_item.dart' show DateFormatStyle;
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/models/currency.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/expense_entity.dart';
import '../providers/expenses_providers.dart';
import '../providers/transaction_filters_provider.dart';
import '../widgets/transaction_filters_sheet.dart';

class TransactionsListScreen extends ConsumerStatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  ConsumerState<TransactionsListScreen> createState() =>
      _TransactionsListScreenState();
}

class _TransactionsListScreenState
    extends ConsumerState<TransactionsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Cache previous data to prevent flickering
  List<Map<String, dynamic>>? _lastGroupedExpenses;
  bool _hasInitialData = false;

  @override
  void initState() {
    super.initState();
    // Sync search controller with filter state
    final filters = ref.read(transactionFiltersProvider);
    _searchController.text = filters.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppTheme.screenBackgroundColor;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark ? Colors.grey[400] : AppTheme.textSecondary;

    final groupedAsync = ref.watch(groupedTransactionsProvider);
    final filters = ref.watch(transactionFiltersProvider);
    final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
    final currency =
        selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Transactions',
              style: AppFonts.textStyle(
                fontSize: 24.scaledText(context),
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.8,
              ),
            ),
            Text(
              'View and manage your spending',
              style: AppFonts.textStyle(
                fontSize: 13.scaledText(context),
                fontWeight: FontWeight.w400,
                color: subtitleColor,
              ),
            ),
          ],
        ),
        titleSpacing: 0,
        actions: [
          // Filter button with badge
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  color: textColor,
                  size: 22.scaled(context),
                ),
                onPressed: () => showTransactionFiltersSheet(context),
              ),
              if (filters.activeFilterCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${filters.activeFilterCount}',
                      style: AppFonts.textStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 20.scaledVertical(context)),
          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkCardBackground
                    : Colors.white,
                borderRadius: BorderRadius.circular(16.scaled(context)),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppTheme.borderColor.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  ref.read(transactionFiltersProvider.notifier).setSearchQuery(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: AppFonts.textStyle(
                    fontSize: 14.scaledText(context),
                    color: subtitleColor,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: subtitleColor, size: 20.scaled(context)),
                  suffixIcon: filters.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, color: subtitleColor, size: 18.scaled(context)),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(transactionFiltersProvider.notifier).setSearchQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.scaled(context),
                    vertical: 14.scaledVertical(context),
                  ),
                ),
                style: AppFonts.textStyle(fontSize: 14.scaledText(context), color: textColor),
              ),
            ),
          ),
          // Active filters summary (show all active filters including category)
          if (filters.hasActiveFilters)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: 8.scaledVertical(context),
              ),
              child: _buildActiveFiltersSummary(filters, isDark, subtitleColor),
            ),
          SizedBox(height: 12.scaledVertical(context)),
          // Transactions List
          Expanded(
            child: _buildTransactionsList(
              groupedAsync,
              currency,
              isDark,
              textColor,
              subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(
    AsyncValue<List<Map<String, dynamic>>> groupedAsync,
    Currency currency,
    bool isDark,
    Color textColor,
    Color? subtitleColor,
  ) {
    // Get current data or fall back to cached data
    final groupedExpenses = groupedAsync.valueOrNull ?? _lastGroupedExpenses;

    // Only show loading on initial load
    if (groupedExpenses == null) {
      if (groupedAsync.isLoading) {
        return Center(
          child: LoadingSpinner.medium(color: AppTheme.primaryColor),
        );
      }
    }

    // Cache the data for future refreshes
    if (groupedAsync.hasValue) {
      _lastGroupedExpenses = groupedAsync.value;
      _hasInitialData = true;
    }

    // Show error only if no cached data
    if (groupedAsync.hasError && !_hasInitialData) {
      return _buildErrorState(textColor, subtitleColor);
    }

    // Empty state
    if (groupedExpenses == null || groupedExpenses.isEmpty) {
      return _buildEmptyState(textColor, subtitleColor);
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        left: AppSpacing.screenHorizontal,
        right: AppSpacing.screenHorizontal,
        bottom: AppSpacing.bottomNavPadding,
      ),
      itemCount: groupedExpenses.length,
      itemBuilder: (context, index) {
        final dateGroup = groupedExpenses[index];
        final date = dateGroup['date'] as DateTime;
        final dateExpenses = dateGroup['expenses'] as List<ExpenseEntity>;

        final dateHeaderBottom = 8.scaledVertical(context);
        final dateHeaderTop = index > 0 ? 16.scaledVertical(context) : 0.0;
        final dateHeaderFontSize = 13.scaledText(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: EdgeInsets.only(
                bottom: dateHeaderBottom,
                top: dateHeaderTop,
              ),
              child: Text(
                _formatDateHeader(date),
                style: AppFonts.textStyle(
                  fontSize: dateHeaderFontSize,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            // Transactions for this date (shared card component)
            TransactionListCard(
              transactions: dateExpenses,
              currency: currency,
              isDark: isDark,
              showActions: true,
              dateFormatStyle: DateFormatStyle.time,
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(Color textColor, Color? subtitleColor) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.scaled(context)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 64.scaled(context),
              color: subtitleColor,
            ),
            SizedBox(height: 16.scaledVertical(context)),
            Text(
              'No transactions found',
              style: AppFonts.textStyle(
                fontSize: 18.scaledText(context),
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            SizedBox(height: 8.scaledVertical(context)),
            Text(
              'Try adjusting your filters',
              style: AppFonts.textStyle(
                fontSize: 14.scaledText(context),
                color: subtitleColor,
              ),
            ),
            SizedBox(height: 24.scaledVertical(context)),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(transactionFiltersProvider.notifier).clearAllFilters();
                _searchController.clear();
              },
              icon: Icon(Icons.filter_alt_off_rounded, size: 18),
              label: Text('Clear Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(color: AppTheme.primaryColor),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Color textColor, Color? subtitleColor) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.scaled(context)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64.scaled(context),
              color: subtitleColor,
            ),
            SizedBox(height: 16.scaledVertical(context)),
            Text(
              'Failed to load transactions',
              style: AppFonts.textStyle(
                fontSize: 18.scaledText(context),
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            SizedBox(height: 8.scaledVertical(context)),
            Text(
              'Please try again later',
              style: AppFonts.textStyle(
                fontSize: 14.scaledText(context),
                color: subtitleColor,
              ),
            ),
            SizedBox(height: 24.scaledVertical(context)),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(expensesProvider),
              icon: Icon(Icons.refresh_rounded, size: 20.scaled(context)),
              label: Text(
                'Retry',
                style: AppFonts.textStyle(fontSize: 14.scaledText(context)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.scaled(context),
                  vertical: 14.scaledVertical(context),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.scaled(context)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFiltersSummary(
    TransactionFilters filters,
    bool isDark,
    Color? subtitleColor,
  ) {
    final chips = <Widget>[];

    // Category filter chip
    if (filters.category != null) {
      chips.add(_buildRemovableChip(
        label: filters.category!.name,
        icon: Icons.category_rounded,
        onRemove: () =>
            ref.read(transactionFiltersProvider.notifier).clearCategory(),
        isDark: isDark,
      ));
    }

    // Date range filter chip
    if (filters.dateRange != DateRangeFilter.all) {
      String label;
      switch (filters.dateRange) {
        case DateRangeFilter.today:
          label = 'Today';
          break;
        case DateRangeFilter.thisWeek:
          label = 'This Week';
          break;
        case DateRangeFilter.thisMonth:
          label = 'This Month';
          break;
        case DateRangeFilter.thisYear:
          label = 'This Year';
          break;
        case DateRangeFilter.custom:
          if (filters.customStartDate != null) {
            label =
                '${DateFormat('MMM d').format(filters.customStartDate!)} - ${DateFormat('MMM d').format(filters.customEndDate!)}';
          } else {
            label = 'Custom';
          }
          break;
        default:
          label = '';
      }
      if (label.isNotEmpty) {
        chips.add(_buildRemovableChip(
          label: label,
          icon: Icons.calendar_today_rounded,
          onRemove: () =>
              ref.read(transactionFiltersProvider.notifier).clearDateRange(),
          isDark: isDark,
        ));
      }
    }

    // Amount range filter chip
    if (filters.minAmount != null || filters.maxAmount != null) {
      String label;
      if (filters.minAmount != null && filters.maxAmount != null) {
        label = '\$${filters.minAmount!.toInt()} - \$${filters.maxAmount!.toInt()}';
      } else if (filters.minAmount != null) {
        label = '≥ \$${filters.minAmount!.toInt()}';
      } else {
        label = '≤ \$${filters.maxAmount!.toInt()}';
      }
      chips.add(_buildRemovableChip(
        label: label,
        icon: Icons.attach_money_rounded,
        onRemove: () =>
            ref.read(transactionFiltersProvider.notifier).clearAmountRange(),
        isDark: isDark,
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _buildRemovableChip({
    required String label,
    required IconData icon,
    required VoidCallback onRemove,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppFonts.textStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (now.difference(dateOnly).inDays < 7) {
      return DateFormat('EEEE').format(date); // Day name
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }
}

