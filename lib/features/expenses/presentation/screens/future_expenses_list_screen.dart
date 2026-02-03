import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/models/currency.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/future_expense_entity.dart';
import '../providers/future_expenses_providers.dart';
import 'add_future_expense_screen.dart';

class FutureExpensesListScreen extends ConsumerStatefulWidget {
  const FutureExpensesListScreen({super.key});

  @override
  ConsumerState<FutureExpensesListScreen> createState() =>
      _FutureExpensesListScreenState();
}

class _FutureExpensesListScreenState
    extends ConsumerState<FutureExpensesListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Refresh future expenses provider when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(futureExpensesProvider);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow';
    } else if (dateOnly.isBefore(today)) {
      return DateFormat('MMM d, yyyy').format(date);
    } else {
      final difference = dateOnly.difference(today).inDays;
      if (difference <= 7) {
        return DateFormat('EEEE, MMM d').format(date);
      } else {
        return DateFormat('MMM d, yyyy').format(date);
      }
    }
  }

  List<Map<String, dynamic>> _groupExpensesByDate(
      List<FutureExpenseEntity> expenses) {
    final Map<String, List<FutureExpenseEntity>> grouped = {};

    for (final expense in expenses) {
      final dateKey = DateFormat('yyyy-MM-dd').format(expense.expectedDate);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(expense);
    }

    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    return sortedDates.map((dateKey) {
      final date = DateTime.parse(dateKey);
      return {
        'date': date,
        'expenses': grouped[dateKey]!,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppTheme.screenBackgroundColor;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark ? Colors.grey[400]! : AppTheme.textSecondary;

    final futureExpensesAsync = ref.watch(futureExpensesProvider);
    final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
    final currency =
        selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: textColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddFutureExpenseScreen(),
                ),
              ).then((_) {
                // Refresh list after adding
                if (mounted) {
                  ref.invalidate(futureExpensesProvider);
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              24,
              AppSpacing.screenHorizontal,
              16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Future Expenses',
                        style: AppFonts.textStyle(
                          fontSize: 28.scaledText(context),
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Planned expenses and upcoming costs',
                        style: AppFonts.textStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBackground : Colors.white,
                borderRadius: BorderRadius.circular(12.scaled(context)),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppTheme.borderColor,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: AppFonts.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Search future expenses...',
                  hintStyle: AppFonts.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: subtitleColor,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: subtitleColor,
                    size: 20.scaled(context),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: subtitleColor,
                            size: 20.scaled(context),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.scaled(context),
                    vertical: 14.scaledVertical(context),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          // Future Expenses List
          Expanded(
            child: futureExpensesAsync.when(
              data: (expenses) {
                // Filter expenses by search query
                var filteredExpenses = expenses.where((e) => !e.isConverted);

                if (_searchQuery.isNotEmpty) {
                  filteredExpenses = filteredExpenses.where(
                    (e) =>
                        e.title.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ||
                        (e.description?.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ) ??
                                false) ||
                        (e.merchant?.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ) ??
                                false),
                  );
                }

                if (filteredExpenses.isEmpty) {
                  return EmptyStateWidget.large(
                    icon: Icons.calendar_today_outlined,
                    title: _searchQuery.isNotEmpty
                        ? 'No future expenses found'
                        : 'No future expenses yet',
                    subtitle: _searchQuery.isNotEmpty
                        ? 'Try adjusting your search'
                        : 'Plan your upcoming expenses to stay on track',
                    action: _searchQuery.isEmpty
                        ? ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AddFutureExpenseScreen(),
                                ),
                              ).then((_) {
                                if (mounted) {
                                  ref.invalidate(futureExpensesProvider);
                                }
                              });
                            },
                            icon: Icon(Icons.add_rounded),
                            label: const Text('Add Future Expense'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.warningColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          )
                        : null,
                  );
                }

                // Group expenses by date
                final groupedExpenses =
                    _groupExpensesByDate(filteredExpenses.toList());

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
                    final dateExpenses =
                        dateGroup['expenses'] as List<FutureExpenseEntity>;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date header
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: 12,
                            top: index > 0 ? 24 : 0,
                          ),
                          child: Text(
                            _formatDateHeader(date),
                            style: AppFonts.textStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: subtitleColor,
                            ),
                          ),
                        ),
                        // Expenses for this date
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkCardBackground
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16.scaled(context)),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : AppTheme.borderColor,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: dateExpenses.asMap().entries.map((entry) {
                              final expenseIndex = entry.key;
                              final expense = entry.value;
                              final isLast =
                                  expenseIndex == dateExpenses.length - 1;

                              return Column(
                                children: [
                                  _FutureExpenseItem(
                                    expense: expense,
                                    textColor: textColor,
                                    subtitleColor: subtitleColor,
                                    currency: currency,
                                    isDark: isDark,
                                  ),
                                  if (!isLast)
                                    Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : AppTheme.borderColor.withValues(
                                              alpha: 0.5,
                                            ),
                                      indent: 20,
                                      endIndent: 20,
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
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
                      size: 48,
                      color: AppTheme.errorColor,
                    ),
                    SizedBox(height: 16.scaledVertical(context)),
                    Text(
                      'Failed to load future expenses',
                      style: AppFonts.textStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(futureExpensesProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FutureExpenseItem extends StatelessWidget {
  final FutureExpenseEntity expense;
  final Color textColor;
  final Color subtitleColor;
  final Currency currency;
  final bool isDark;

  const _FutureExpenseItem({
    required this.expense,
    required this.textColor,
    required this.subtitleColor,
    required this.currency,
    required this.isDark,
  });

  String _getAmountText() {
    switch (expense.amountCertainty) {
      case AmountCertainty.exact:
        return CurrencyFormatter.format(
          expense.expectedAmount,
          currency,
        );
      case AmountCertainty.range:
        if (expense.minAmount != null && expense.maxAmount != null) {
          return '${CurrencyFormatter.format(expense.minAmount!, currency)} - ${CurrencyFormatter.format(expense.maxAmount!, currency)}';
        }
        return CurrencyFormatter.format(expense.expectedAmount, currency);
      case AmountCertainty.estimate:
        return '~${CurrencyFormatter.format(expense.expectedAmount, currency)}';
    }
  }

  Color _getPriorityColor() {
    switch (expense.priority) {
      case FutureExpensePriority.low:
        return Colors.grey;
      case FutureExpensePriority.medium:
        return AppTheme.warningColor;
      case FutureExpensePriority.high:
        return Colors.orange;
      case FutureExpensePriority.critical:
        return AppTheme.errorColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO: Navigate to future expense details screen
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Priority indicator
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: _getPriorityColor(),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: AppFonts.textStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (expense.merchant != null) ...[
                    SizedBox(height: 4),
                    Text(
                      expense.merchant!,
                      style: AppFonts.textStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: subtitleColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(expense.expectedDate),
                        style: AppFonts.textStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                        ),
                      ),
                      if (expense.dateFlexibility == DateFlexibility.flexible &&
                          expense.dateWindowDays != null) ...[
                        SizedBox(width: 8),
                        Text(
                          '±${expense.dateWindowDays} days',
                          style: AppFonts.textStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _getAmountText(),
                  style: AppFonts.textStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.warningColor,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    expense.priority.name.toUpperCase(),
                    style: AppFonts.textStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getPriorityColor(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

