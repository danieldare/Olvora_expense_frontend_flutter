import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/models/currency.dart';
import '../../../../core/widgets/bottom_sheet_modal.dart';
import '../../../../core/widgets/bottom_sheet_option_tile.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/future_expense_entity.dart';
import '../../domain/entities/recurring_expense_entity.dart';
import '../providers/future_expenses_providers.dart';
import '../providers/recurring_expenses_providers.dart';
import '../providers/expenses_providers.dart';
import 'add_future_expense_screen.dart';
import 'add_recurring_expense_screen.dart';

class PlannedExpensesScreen extends ConsumerStatefulWidget {
  const PlannedExpensesScreen({super.key});

  @override
  ConsumerState<PlannedExpensesScreen> createState() =>
      _PlannedExpensesScreenState();
}

// Filter types for Future Expenses
enum FutureExpenseFilter { all, critical, dueSoon }

// Filter types for Recurring Expenses
enum RecurringExpenseFilter { all, autoPost, manual }

class _PlannedExpensesScreenState extends ConsumerState<PlannedExpensesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  FutureExpenseFilter _futureFilter = FutureExpenseFilter.all;
  RecurringExpenseFilter _recurringFilter = RecurringExpenseFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChanged);
    // Refresh providers when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(futureExpensesProvider);
        ref.invalidate(recurringExpensesProvider);
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (mounted) {
      setState(() {
        // Reset filters when switching tabs
        _futureFilter = FutureExpenseFilter.all;
        _recurringFilter = RecurringExpenseFilter.all;
      });
    }
  }

  Widget _buildSummaryStats({
    required AsyncValue<List<FutureExpenseEntity>> futureExpensesAsync,
    required AsyncValue<List<RecurringExpenseEntity>> recurringExpensesAsync,
    required Currency currency,
    required bool isDark,
  }) {
    return futureExpensesAsync.when(
      data: (futureExpenses) {
        return recurringExpensesAsync.when(
          data: (recurringExpenses) {
            if (_tabController.index == 0) {
              // Future Expenses Stats
              var filteredExpenses = futureExpenses
                  .where((e) => !e.isConverted)
                  .toList();
              if (_searchQuery.isNotEmpty) {
                filteredExpenses = filteredExpenses
                    .where(
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
                    )
                    .toList();
              }
              final totalAmount = filteredExpenses.fold<double>(
                0.0,
                (sum, e) => sum + e.expectedAmount,
              );
              final criticalCount = filteredExpenses
                  .where(
                    (e) =>
                        e.priority ==
                        FutureExpensePriority.critical,
                  )
                  .length;
              final upcomingCount = filteredExpenses.where((e) {
                final daysUntil = e.expectedDate
                    .difference(DateTime.now())
                    .inDays;
                return daysUntil >= 0 && daysUntil <= 7;
              }).length;

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  0,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: _SummaryStatsCard(
                  totalAmount: totalAmount,
                  totalCount: filteredExpenses.length,
                  criticalCount: criticalCount,
                  upcomingCount: upcomingCount,
                  currency: currency,
                  isDark: isDark,
                  selectedFilter: _futureFilter,
                  onFilterChanged: (filter) {
                    setState(() {
                      _futureFilter = filter;
                    });
                  },
                ),
              );
            } else {
              // Recurring Expenses Stats
              var filteredExpenses = recurringExpenses
                  .where((e) => e.isActive)
                  .toList();
              if (_searchQuery.isNotEmpty) {
                filteredExpenses = filteredExpenses
                    .where(
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
                              false) ||
                          e.category.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ),
                    )
                    .toList();
              }
              final totalMonthly = filteredExpenses.fold<double>(
                0.0,
                (sum, e) {
                  double monthlyAmount = e.amount;
                  switch (e.frequency) {
                    case RecurrenceFrequency.daily:
                      monthlyAmount = e.amount * 30;
                      break;
                    case RecurrenceFrequency.weekly:
                      monthlyAmount = e.amount * 4;
                      break;
                    case RecurrenceFrequency.biweekly:
                      monthlyAmount = e.amount * 2;
                      break;
                    case RecurrenceFrequency.monthly:
                      monthlyAmount = e.amount;
                      break;
                    case RecurrenceFrequency.quarterly:
                      monthlyAmount = e.amount / 3;
                      break;
                    case RecurrenceFrequency.yearly:
                      monthlyAmount = e.amount / 12;
                      break;
                  }
                  return sum + monthlyAmount;
                },
              );
              final autoPostCount = filteredExpenses
                  .where((e) => e.autoPost)
                  .length;

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  0,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: _RecurringSummaryStatsCard(
                  totalMonthly: totalMonthly,
                  totalCount: filteredExpenses.length,
                  autoPostCount: autoPostCount,
                  currency: currency,
                  isDark: isDark,
                  selectedFilter: _recurringFilter,
                  onFilterChanged: (filter) {
                    setState(() {
                      _recurringFilter = filter;
                    });
                  },
                ),
              );
            }
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppTheme.screenBackgroundColor;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark ? Colors.grey[400] : AppTheme.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header (Weekly Summary style: back + title + action)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 10, 0),
              child: Row(
                children: [
                  AppBackButton(),
                  Expanded(
                    child: Text(
                      'Scheduled Expenses',
                      style: AppFonts.textStyle(
                        fontSize: 18.scaledText(context),
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_rounded, color: textColor, size: 24),
                    onPressed: () {
                      if (_tabController.index == 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddFutureExpenseScreen(),
                          ),
                        ).then((_) {
                          if (mounted) {
                            ref.invalidate(futureExpensesProvider);
                          }
                        });
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddRecurringExpenseScreen(),
                          ),
                        ).then((_) {
                          if (mounted) {
                            ref.invalidate(recurringExpensesProvider);
                          }
                        });
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.scaledVertical(context)),
            // Tab selector as pill (Weekly Summary week-navigator style)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
              child: _CustomTabSelector(
                tabController: _tabController,
                onTabChanged: (index) {
                  _tabController.animateTo(index);
                },
                isDark: isDark,
              ),
            ),
            SizedBox(height: 8.scaledVertical(context)),
            Expanded(
              child: Consumer(
        builder: (context, ref, _) {
          final futureExpensesAsync = ref.watch(futureExpensesProvider);
          final recurringExpensesAsync = ref.watch(recurringExpensesProvider);
          final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
          final currency =
              selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;

          // Check if current tab has data
          final hasFutureData = futureExpensesAsync.maybeWhen(
            data: (expenses) => expenses.where((e) => !e.isConverted).isNotEmpty,
            orElse: () => false,
          );
          final hasRecurringData = recurringExpensesAsync.maybeWhen(
            data: (expenses) => expenses.where((e) => e.isActive).isNotEmpty,
            orElse: () => false,
          );

          return AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              final isOnFutureTab = _tabController.index == 0;
              final currentTabHasData = isOnFutureTab ? hasFutureData : hasRecurringData;
              final showStatsAndSearch = currentTabHasData || _searchQuery.isNotEmpty;

              return Column(
                children: [
                  // Hero + Quick stats + Search (Weekly Summary inspired)
                  if (showStatsAndSearch) ...[
                    SizedBox(height: 4.scaledVertical(context)),
                    // Summary Stats (hero + quick stats)
                    _buildSummaryStats(
                      futureExpensesAsync: futureExpensesAsync,
                      recurringExpensesAsync: recurringExpensesAsync,
                      currency: currency,
                      isDark: isDark,
                    ),
                    SizedBox(height: 16.scaledVertical(context)),
                    // Search Bar
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12.scaled(context)),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.15)
                                : (Colors.grey[300]!.withValues(alpha: 0.6)),
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
                            fontSize: 14.scaledText(context),
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search scheduled expenses...',
                            hintStyle: AppFonts.textStyle(
                              fontSize: 14.scaledText(context),
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
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.scaledVertical(context)),
                  ] else ...[
                    SizedBox(height: 8.scaledVertical(context)),
                  ],
                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _FutureExpensesTab(
                          searchQuery: _searchQuery,
                          filter: _futureFilter,
                        ),
                        _RecurringExpensesTab(
                          searchQuery: _searchQuery,
                          filter: _recurringFilter,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
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

class _FutureExpensesTab extends ConsumerWidget {
  final String searchQuery;
  final FutureExpenseFilter filter;

  const _FutureExpensesTab({required this.searchQuery, required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark ? Colors.grey[400] : AppTheme.textSecondary;
    final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
    final currency =
        selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;

    final futureExpensesAsync = ref.watch(futureExpensesProvider);

    return futureExpensesAsync.when(
      data: (expenses) {
        var filteredExpenses = expenses.where((e) => !e.isConverted).toList();

        // Apply stat filter
        switch (filter) {
          case FutureExpenseFilter.critical:
            filteredExpenses = filteredExpenses
                .where((e) => e.priority == FutureExpensePriority.critical)
                .toList();
            break;
          case FutureExpenseFilter.dueSoon:
            filteredExpenses = filteredExpenses.where((e) {
              final daysUntil = e.expectedDate
                  .difference(DateTime.now())
                  .inDays;
              return daysUntil >= 0 && daysUntil <= 7;
            }).toList();
            break;
          case FutureExpenseFilter.all:
            // No additional filter
            break;
        }

        if (searchQuery.isNotEmpty) {
          filteredExpenses = filteredExpenses
              .where(
                (e) =>
                    e.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                    (e.description?.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ??
                        false) ||
                    (e.merchant?.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ??
                        false),
              )
              .toList();
        }

        if (filteredExpenses.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: 40,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 32,
                    color: subtitleColor,
                  ),
                  SizedBox(height: 8),
                  Text(
                    searchQuery.isNotEmpty
                        ? 'No future expenses found'
                        : 'No future expenses yet',
                    style: AppFonts.textStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    searchQuery.isNotEmpty
                        ? 'Try adjusting your search'
                        : 'Plan your upcoming expenses to stay on track.',
                    style: AppFonts.textStyle(
                      fontSize: 14,
                      color: subtitleColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (searchQuery.isEmpty) ...[
                    SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AddFutureExpenseScreen(),
                          ),
                        ).then((_) {
                          if (context.mounted) {
                            ref.invalidate(futureExpensesProvider);
                          }
                        });
                      },
                      icon: Icon(Icons.add_rounded, size: 20),
                      label: Text(
                        'Add future expense',
                        style: AppFonts.textStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        final groupedExpenses = _groupFutureExpensesByDate(filteredExpenses);

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Expenses List
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final dateGroup = groupedExpenses[index];
                final date = dateGroup['date'] as DateTime;
                final dateExpenses =
                    dateGroup['expenses'] as List<FutureExpenseEntity>;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: 16.scaledVertical(context),
                    left: AppSpacing.screenHorizontal,
                    right: AppSpacing.screenHorizontal,
                    top: index == 0 ? 0 : 8.scaledVertical(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date header
                      Padding(
                        padding: EdgeInsets.only(bottom: 12.scaledVertical(context)),
                        child: Text(
                          _formatDateHeader(date),
                          style: AppFonts.textStyle(
                            fontSize: 15.scaledText(context),
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      // Expenses for this date (TransactionListCard style)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14.scaled(context)),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : AppTheme.borderColor.withValues(alpha: 0.6),
                            width: 1,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    AppTheme.darkCardBackground,
                                    AppTheme.darkCardBackground.withValues(alpha: 0.95),
                                  ]
                                : [
                                    Colors.white,
                                    Color.lerp(Colors.white, AppTheme.borderColor, 0.04)!,
                                  ],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: dateExpenses.asMap().entries.map((entry) {
                            final expenseIndex = entry.key;
                            final expense = entry.value;
                            final isLast =
                                expenseIndex == dateExpenses.length - 1;

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _FutureExpenseItem(
                                  expense: expense,
                                  currency: currency,
                                  isDark: isDark,
                                ),
                                if (!isLast)
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.16)
                                        : AppTheme.borderColor.withValues(alpha: 0.55),
                                    indent: 14.scaled(context),
                                    endIndent: 14.scaled(context),
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              }, childCount: groupedExpenses.length),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.bottomNavPadding),
            ),
          ],
        );
      },
      loading: () => Center(
        child: LoadingSpinner.medium(color: AppTheme.primaryColor),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64.scaled(context), color: subtitleColor),
              SizedBox(height: 16),
              Text(
                'Failed to load future expenses',
                style: AppFonts.textStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please try again later',
                style: AppFonts.textStyle(fontSize: 14, color: subtitleColor),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(futureExpensesProvider);
                },
                icon: Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  List<Map<String, dynamic>> _groupFutureExpensesByDate(
    List<FutureExpenseEntity> expenses,
  ) {
    final Map<String, List<FutureExpenseEntity>> grouped = {};

    for (final expense in expenses) {
      final dateKey = DateFormat('yyyy-MM-dd').format(expense.expectedDate);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(expense);
    }

    final sortedDates = grouped.keys.toList()..sort((a, b) => a.compareTo(b));

    return sortedDates.map((dateKey) {
      final date = DateTime.parse(dateKey);
      return {'date': date, 'expenses': grouped[dateKey]!};
    }).toList();
  }
}

class _RecurringExpensesTab extends ConsumerWidget {
  final String searchQuery;
  final RecurringExpenseFilter filter;

  const _RecurringExpensesTab({
    required this.searchQuery,
    required this.filter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark ? Colors.grey[400] : AppTheme.textSecondary;
    final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
    final currency =
        selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;

    final recurringExpensesAsync = ref.watch(recurringExpensesProvider);

    return recurringExpensesAsync.when(
      data: (expenses) {
        var filteredExpenses = expenses.where((e) => e.isActive).toList();

        // Apply stat filter
        switch (filter) {
          case RecurringExpenseFilter.autoPost:
            filteredExpenses = filteredExpenses
                .where((e) => e.autoPost)
                .toList();
            break;
          case RecurringExpenseFilter.manual:
            filteredExpenses = filteredExpenses
                .where((e) => !e.autoPost)
                .toList();
            break;
          case RecurringExpenseFilter.all:
            // No additional filter
            break;
        }

        if (searchQuery.isNotEmpty) {
          filteredExpenses = filteredExpenses
              .where(
                (e) =>
                    e.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                    (e.description?.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ??
                        false) ||
                    (e.merchant?.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ??
                        false) ||
                    e.category.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ),
              )
              .toList();
        }

        if (filteredExpenses.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: 40,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.repeat_rounded, size: 32, color: subtitleColor),
                  SizedBox(height: 8),
                  Text(
                    searchQuery.isNotEmpty
                        ? 'No recurring expenses found'
                        : 'No recurring expenses yet',
                    style: AppFonts.textStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    searchQuery.isNotEmpty
                        ? 'Try adjusting your search'
                        : 'Set up recurring expenses to track subscriptions and regular payments.',
                    style: AppFonts.textStyle(
                      fontSize: 14,
                      color: subtitleColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (searchQuery.isEmpty) ...[
                    SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AddRecurringExpenseScreen(),
                          ),
                        ).then((_) {
                          if (context.mounted) {
                            ref.invalidate(recurringExpensesProvider);
                          }
                        });
                      },
                      icon: Icon(Icons.add_rounded, size: 20),
                      label: Text(
                        'Add recurring expense',
                        style: AppFonts.textStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        final sortedExpenses = filteredExpenses
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Single card with dividers (TransactionListCard style)
        final cardRadius = 14.scaled(context);
        final dividerIndent = 14.scaled(context);
        final borderColor = isDark
            ? Colors.white.withValues(alpha: 0.12)
            : AppTheme.borderColor.withValues(alpha: 0.6);
        final dividerColor = isDark
            ? Colors.white.withValues(alpha: 0.16)
            : AppTheme.borderColor.withValues(alpha: 0.55);

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  0,
                  AppSpacing.screenHorizontal,
                  AppSpacing.bottomNavPadding,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cardRadius),
                    border: Border.all(color: borderColor, width: 1),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              AppTheme.darkCardBackground,
                              AppTheme.darkCardBackground.withValues(alpha: 0.95),
                            ]
                          : [
                              Colors.white,
                              Color.lerp(Colors.white, AppTheme.borderColor, 0.04)!,
                            ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: sortedExpenses.asMap().entries.map((entry) {
                      final index = entry.key;
                      final expense = entry.value;
                      final isLast = index == sortedExpenses.length - 1;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _RecurringExpenseItem(
                            expense: expense,
                            currency: currency,
                            isDark: isDark,
                          ),
                          if (!isLast)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: dividerColor,
                              indent: dividerIndent,
                              endIndent: dividerIndent,
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => Center(
        child: LoadingSpinner.medium(color: AppTheme.primaryColor),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64.scaled(context), color: subtitleColor),
              SizedBox(height: 16),
              Text(
                'Failed to load recurring expenses',
                style: AppFonts.textStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please try again later',
                style: AppFonts.textStyle(fontSize: 14, color: subtitleColor),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(recurringExpensesProvider);
                },
                icon: Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryStatsCard extends StatelessWidget {
  final double totalAmount;
  final int totalCount;
  final int criticalCount;
  final int upcomingCount;
  final Currency currency;
  final bool isDark;
  final FutureExpenseFilter selectedFilter;
  final Function(FutureExpenseFilter) onFilterChanged;

  const _SummaryStatsCard({
    required this.totalAmount,
    required this.totalCount,
    required this.criticalCount,
    required this.upcomingCount,
    required this.currency,
    required this.isDark,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark
        ? (Colors.grey[400] ?? Colors.grey)
        : AppTheme.textSecondary;
    final gradientColors = AppTheme.walletGradient.isNotEmpty
        ? AppTheme.walletGradient
        : [AppTheme.primaryColor, AppTheme.secondaryColor];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero card (Weekly Summary _HeroStatusCard style)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors.length >= 2
                  ? gradientColors
                  : [gradientColors.first, gradientColors.first],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (gradientColors.isNotEmpty
                        ? gradientColors.first
                        : AppTheme.primaryColor)
                    .withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total planned',
                      style: AppFonts.textStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(totalAmount, currency),
                      style: AppFonts.textStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.scaledVertical(context)),
        // Quick stats row (Weekly Summary _QuickStatsRow style)
        SizedBox(
          height: 98.scaledVertical(context),
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              _StatItem(
                icon: Icons.receipt_long_rounded,
                label: 'Total',
                value: totalCount.toString(),
                color: AppTheme.primaryColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                isDark: isDark,
                isSelected: selectedFilter == FutureExpenseFilter.all,
                onTap: () => onFilterChanged(FutureExpenseFilter.all),
              ),
              SizedBox(width: 10),
              _StatItem(
                icon: Icons.warning_rounded,
                label: 'Critical',
                value: criticalCount.toString(),
                color: AppTheme.errorColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                isDark: isDark,
                isSelected: selectedFilter == FutureExpenseFilter.critical,
                onTap: () => onFilterChanged(FutureExpenseFilter.critical),
              ),
              SizedBox(width: 10),
              _StatItem(
                icon: Icons.schedule_rounded,
                label: 'Due Soon',
                value: upcomingCount.toString(),
                color: AppTheme.warningColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                isDark: isDark,
                isSelected: selectedFilter == FutureExpenseFilter.dueSoon,
                onTap: () => onFilterChanged(FutureExpenseFilter.dueSoon),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecurringSummaryStatsCard extends StatelessWidget {
  final double totalMonthly;
  final int totalCount;
  final int autoPostCount;
  final Currency currency;
  final bool isDark;
  final RecurringExpenseFilter selectedFilter;
  final Function(RecurringExpenseFilter) onFilterChanged;

  const _RecurringSummaryStatsCard({
    required this.totalMonthly,
    required this.totalCount,
    required this.autoPostCount,
    required this.currency,
    required this.isDark,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark
        ? (Colors.grey[400] ?? Colors.grey)
        : AppTheme.textSecondary;
    final gradientColors = AppTheme.walletGradient.isNotEmpty
        ? AppTheme.walletGradient
        : [AppTheme.primaryColor, AppTheme.secondaryColor];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero card (Weekly Summary style)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors.length >= 2
                  ? gradientColors
                  : [gradientColors.first, gradientColors.first],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (gradientColors.isNotEmpty
                        ? gradientColors.first
                        : AppTheme.primaryColor)
                    .withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.repeat_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly total',
                      style: AppFonts.textStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(totalMonthly, currency),
                      style: AppFonts.textStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.scaledVertical(context)),
        // Quick stats row
        SizedBox(
          height: 98.scaledVertical(context),
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              _StatItem(
                icon: Icons.receipt_long_rounded,
                label: 'Total Active',
                value: totalCount.toString(),
                color: AppTheme.primaryColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                isDark: isDark,
                isSelected: selectedFilter == RecurringExpenseFilter.all,
                onTap: () => onFilterChanged(RecurringExpenseFilter.all),
              ),
              SizedBox(width: 10),
              _StatItem(
                icon: Icons.auto_awesome_rounded,
                label: 'Auto-Post',
                value: autoPostCount.toString(),
                color: AppTheme.successColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                isDark: isDark,
                isSelected: selectedFilter == RecurringExpenseFilter.autoPost,
                onTap: () => onFilterChanged(RecurringExpenseFilter.autoPost),
              ),
              SizedBox(width: 10),
              _StatItem(
                icon: Icons.notifications_active_rounded,
                label: 'Manual',
                value: '${totalCount - autoPostCount}',
                color: AppTheme.warningColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                isDark: isDark,
                isSelected: selectedFilter == RecurringExpenseFilter.manual,
                onTap: () => onFilterChanged(RecurringExpenseFilter.manual),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CustomTabSelector extends StatefulWidget {
  final TabController tabController;
  final Function(int) onTabChanged;
  final bool isDark;

  const _CustomTabSelector({
    required this.tabController,
    required this.onTabChanged,
    required this.isDark,
  });

  @override
  State<_CustomTabSelector> createState() => _CustomTabSelectorState();
}

class _CustomTabSelectorState extends State<_CustomTabSelector> {
  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = widget.isDark
        ? (Colors.grey[400] ?? Colors.grey)
        : AppTheme.textSecondary;
    final selectedIndex = widget.tabController.index;

    return Row(
      children: [
        Expanded(
          child: _TabButton(
            label: 'Future',
            isSelected: selectedIndex == 0,
            onTap: () => widget.onTabChanged(0),
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _TabButton(
            label: 'Recurring',
            isSelected: selectedIndex == 1,
            onTap: () => widget.onTabChanged(1),
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color textColor;
  final Color subtitleColor;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppFonts.textStyle(
                fontSize: 15.scaledText(context),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? textColor : subtitleColor,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color textColor;
  final Color subtitleColor;
  final bool isDark;
  final bool isSelected;
  final VoidCallback? onTap;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
    required this.subtitleColor,
    required this.isDark,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Active stat: light = grey; dark = complementary so they’re distinct.
    final complementaryColor = AppTheme.complementaryColor;
    const lightGray = Color(0xFFE5E7EB); // very light gray for selected in light mode

    final valueColor = isSelected
        ? (isDark ? Colors.white : textColor)
        : textColor;
    final labelColor = isSelected
        ? (isDark ? Colors.white.withValues(alpha: 0.9) : subtitleColor)
        : subtitleColor;
    final iconColor = isSelected ? (isDark ? Colors.white : color) : color;
    final iconBgColor = isSelected
        ? (isDark
            ? Colors.white.withValues(alpha: 0.25)
            : color.withValues(alpha: 0.2))
        : color.withValues(alpha: isDark ? 0.35 : 0.25);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.scaled(context)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: 150.scaled(context),
          height: 90.scaledVertical(context),
          padding: EdgeInsets.symmetric(
            horizontal: 12.scaled(context),
            vertical: 8.scaledVertical(context),
          ),
          decoration: BoxDecoration(
            color: isSelected && !isDark ? lightGray : null,
            gradient: isSelected && isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      complementaryColor,
                      complementaryColor.withValues(alpha: 0.85),
                    ],
                  )
                : isSelected && !isDark
                    ? null
                    : isDark
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1a1f2e), Color(0xFF111827)],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Color.lerp(Colors.white, AppTheme.borderColor, 0.06)!,
                            ],
                          ),
            borderRadius: BorderRadius.circular(14.scaled(context)),
            border: Border.all(
              color: isSelected && isDark
                  ? complementaryColor.withValues(alpha: 0.6)
                  : isSelected && !isDark
                      ? AppTheme.borderColor
                      : isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : AppTheme.borderColor.withValues(alpha: 0.7),
              width: isSelected && isDark ? 2 : 1,
            ),
            boxShadow: isSelected && isDark
                ? [
                    BoxShadow(
                      color: complementaryColor.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon - colored (e.g. red for Critical, yellow for Due Soon) when unselected; white when selected
              Container(
                padding: EdgeInsets.all(5.scaled(context)),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8.scaled(context)),
                ),
                child: Icon(
                  icon,
                  size: 14.scaled(context),
                  color: iconColor,
                ),
              ),
              SizedBox(height: 5.scaledVertical(context)),
              // Value
              Text(
                value,
                style: AppFonts.textStyle(
                  fontSize: 18.scaledText(context),
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2.scaledVertical(context)),
              // Label
              Text(
                label,
                style: AppFonts.textStyle(
                  fontSize: 11.scaledText(context),
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                  height: 1.15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FutureExpenseItem extends ConsumerWidget {
  final FutureExpenseEntity expense;
  final Currency currency;
  final bool isDark;

  const _FutureExpenseItem({
    required this.expense,
    required this.currency,
    required this.isDark,
  });

  String _getAmountText() {
    switch (expense.amountCertainty) {
      case AmountCertainty.exact:
        return CurrencyFormatter.format(expense.expectedAmount, currency);
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
      if (difference < 0) {
        return 'Overdue';
      } else if (difference <= 7) {
        return DateFormat('EEE, MMM d').format(date);
      } else {
        return DateFormat('MMM d, yyyy').format(date);
      }
    }
  }

  bool _isUrgent(DateTime date) {
    final daysUntil = date.difference(DateTime.now()).inDays;
    return daysUntil >= 0 && daysUntil <= 3;
  }

  void _showExpenseMenu(
    BuildContext context,
    WidgetRef ref,
    FutureExpenseEntity expense,
  ) {
    BottomSheetModal.show(
      context: context,
      title: expense.title,
      subtitle: 'Manage expense',
      borderRadius: 20,
      isScrollControlled: false,
      isScrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomSheetOptionTile(
            icon: Icons.edit_rounded,
            label: 'Edit',
            color: AppTheme.primaryColor,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddFutureExpenseScreen(existingExpense: expense),
                ),
              ).then((_) {
                if (context.mounted) {
                  ref.invalidate(futureExpensesProvider);
                }
              });
            },
          ),
          if (!expense.isConverted) ...[
            const BottomSheetOptionDivider(),
            BottomSheetOptionTile(
              icon: Icons.check_circle_rounded,
              label: 'Mark as Completed',
              color: AppTheme.successColor,
              onTap: () {
                Navigator.pop(context);
                _markAsCompleted(context, ref, expense);
              },
            ),
          ],
          const BottomSheetOptionDivider(),
          BottomSheetOptionTile(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: AppTheme.errorColor,
            useColorForText: true,
            onTap: () {
              Navigator.pop(context);
              _deleteFutureExpense(context, ref, expense);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _markAsCompleted(
    BuildContext context,
    WidgetRef ref,
    FutureExpenseEntity expense,
  ) async {
    try {
      final apiService = ref.read(apiServiceV2Provider);
      await apiService.dio.post('/future-expenses/${expense.id}/convert');

      // Invalidate providers
      ref.invalidate(futureExpensesProvider);
      ref.invalidate(expensesProvider);
      ref.invalidate(recentTransactionsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8.scaled(context)),
                Expanded(
                  child: Text('${expense.title} marked as completed! 🎉'),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as completed: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteFutureExpense(
    BuildContext context,
    WidgetRef ref,
    FutureExpenseEntity expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Future Expense',
            style: AppFonts.textStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${expense.title}"? This action cannot be undone.',
            style: AppFonts.textStyle(
              fontSize: 14,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppTheme.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: AppFonts.textStyle(
                  fontSize: 16.scaledText(context),
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final apiService = ref.read(apiServiceV2Provider);
      await apiService.dio.delete('/future-expenses/${expense.id}');

      // Invalidate providers
      ref.invalidate(futureExpensesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8.scaled(context)),
                Expanded(child: Text('Future expense deleted successfully')),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark ? Colors.grey[400] : AppTheme.textSecondary;
    final priorityColor = _getPriorityColor();
    final isUrgent = _isUrgent(expense.expectedDate);

    // TransactionItem-style layout: icon, title/subtitle, amount (padding 16/12)
    final paddingH = 16.0;
    final paddingV = 12.0;
    final iconSize = 20.0;
    final spacing = 10.0;
    final titleFontSize = 14.0;
    final subtitleFontSize = 11.0;
    final amountFontSize = 16.0;
    final amountColor = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppTheme.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showExpenseMenu(context, ref, expense),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: iconSize,
                color: priorityColor,
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      expense.title,
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
                    Row(
                      children: [
                        Text(
                          _formatDate(expense.expectedDate),
                          style: AppFonts.textStyle(
                            fontSize: subtitleFontSize,
                            fontWeight: FontWeight.w400,
                            color: subtitleColor,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '•',
                          style: AppFonts.textStyle(
                            fontSize: subtitleFontSize,
                            color: (subtitleColor ?? AppTheme.textSecondary).withValues(alpha: 0.5),
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          expense.priority.name.toUpperCase(),
                          style: AppFonts.textStyle(
                            fontSize: subtitleFontSize,
                            fontWeight: FontWeight.w500,
                            color: priorityColor,
                          ),
                        ),
                        if (isUrgent) ...[
                          SizedBox(width: 6),
                          Text(
                            'Due soon',
                            style: AppFonts.textStyle(
                              fontSize: subtitleFontSize,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.errorColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing),
              Text(
                _getAmountText(),
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
}

class _RecurringExpenseItem extends ConsumerWidget {
  final RecurringExpenseEntity expense;
  final Currency currency;
  final bool isDark;

  const _RecurringExpenseItem({
    required this.expense,
    required this.currency,
    required this.isDark,
  });

  String _getFrequencyText() {
    switch (expense.frequency) {
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.biweekly:
        return 'Bi-weekly';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.quarterly:
        return 'Quarterly';
      case RecurrenceFrequency.yearly:
        return 'Yearly';
    }
  }

  String _getAmountText() {
    // Always show the amount value, even if it's variable
    return CurrencyFormatter.format(expense.amount, currency);
  }

  String _getNextDueDate() {
    // Calculate next occurrence based on frequency
    final now = DateTime.now();
    final startDate = expense.startDate;

    if (now.isBefore(startDate)) {
      return DateFormat('MMM d').format(startDate);
    }

    switch (expense.frequency) {
      case RecurrenceFrequency.daily:
        return DateFormat('MMM d').format(now.add(const Duration(days: 1)));
      case RecurrenceFrequency.weekly:
        final daysUntilNext = 7 - (now.weekday - startDate.weekday) % 7;
        return DateFormat(
          'MMM d',
        ).format(now.add(Duration(days: daysUntilNext)));
      case RecurrenceFrequency.biweekly:
        final daysSinceStart = now.difference(startDate).inDays;
        final periods = (daysSinceStart / 14).floor();
        final nextDate = startDate.add(Duration(days: (periods + 1) * 14));
        return DateFormat('MMM d').format(nextDate);
      case RecurrenceFrequency.monthly:
        var nextDate = DateTime(now.year, now.month, startDate.day);
        if (nextDate.isBefore(now) || nextDate.isAtSameMomentAs(now)) {
          nextDate = DateTime(now.year, now.month + 1, startDate.day);
        }
        return DateFormat('MMM d').format(nextDate);
      case RecurrenceFrequency.quarterly:
        var nextDate = DateTime(now.year, now.month, startDate.day);
        while (nextDate.isBefore(now) || nextDate.isAtSameMomentAs(now)) {
          nextDate = DateTime(nextDate.year, nextDate.month + 3, nextDate.day);
        }
        return DateFormat('MMM d').format(nextDate);
      case RecurrenceFrequency.yearly:
        var nextDate = DateTime(now.year, startDate.month, startDate.day);
        if (nextDate.isBefore(now) || nextDate.isAtSameMomentAs(now)) {
          nextDate = DateTime(now.year + 1, startDate.month, startDate.day);
        }
        return DateFormat('MMM d').format(nextDate);
    }
  }

  void _showRecurringExpenseMenu(
    BuildContext context,
    WidgetRef ref,
    RecurringExpenseEntity expense,
  ) {
    BottomSheetModal.show(
      context: context,
      title: expense.title,
      subtitle: 'Manage recurring expense',
      borderRadius: 20,
      isScrollControlled: false,
      isScrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomSheetOptionTile(
            icon: Icons.edit_rounded,
            label: 'Edit',
            color: AppTheme.primaryColor,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddRecurringExpenseScreen(existingExpense: expense),
                ),
              ).then((_) {
                if (context.mounted) {
                  ref.invalidate(recurringExpensesProvider);
                }
              });
            },
          ),
          if (expense.isActive) ...[
            const BottomSheetOptionDivider(),
            BottomSheetOptionTile(
              icon: Icons.check_circle_rounded,
              label: 'Mark as Completed',
              color: AppTheme.successColor,
              onTap: () {
                Navigator.pop(context);
                _markRecurringAsCompleted(context, ref, expense);
              },
            ),
          ],
          const BottomSheetOptionDivider(),
          BottomSheetOptionTile(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: AppTheme.errorColor,
            useColorForText: true,
            onTap: () {
              Navigator.pop(context);
              _deleteRecurringExpense(context, ref, expense);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _markRecurringAsCompleted(
    BuildContext context,
    WidgetRef ref,
    RecurringExpenseEntity expense,
  ) async {
    try {
      final apiService = ref.read(apiServiceV2Provider);
      await apiService.dio.patch(
        '/recurring-expenses/${expense.id}',
        data: {'isActive': false},
      );

      // Invalidate providers
      ref.invalidate(recurringExpensesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8.scaled(context)),
                Expanded(
                  child: Text('${expense.title} marked as completed! 🎉'),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as completed: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteRecurringExpense(
    BuildContext context,
    WidgetRef ref,
    RecurringExpenseEntity expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Recurring Expense',
            style: AppFonts.textStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${expense.title}"? This action cannot be undone.',
            style: AppFonts.textStyle(
              fontSize: 14,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppTheme.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: AppFonts.textStyle(
                  fontSize: 16.scaledText(context),
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final apiService = ref.read(apiServiceV2Provider);
      await apiService.dio.delete('/recurring-expenses/${expense.id}');

      // Invalidate providers
      ref.invalidate(recurringExpensesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8.scaled(context)),
                Expanded(child: Text('Recurring expense deleted successfully')),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark ? Colors.grey[400] : AppTheme.textSecondary;
    // TransactionItem-style layout: icon, title/subtitle, amount (padding 16/12)
    final paddingH = 16.0;
    final paddingV = 12.0;
    final iconSize = 20.0;
    final spacing = 10.0;
    final titleFontSize = 14.0;
    final subtitleFontSize = 11.0;
    final amountFontSize = 16.0;
    final amountColor = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppTheme.textPrimary;
    final categoryColor = AppTheme.primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showRecurringExpenseMenu(context, ref, expense),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.repeat_rounded,
                size: iconSize,
                color: categoryColor,
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      expense.title,
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
                    Row(
                      children: [
                        Text(
                          _getFrequencyText(),
                          style: AppFonts.textStyle(
                            fontSize: subtitleFontSize,
                            fontWeight: FontWeight.w400,
                            color: subtitleColor,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '•',
                          style: AppFonts.textStyle(
                            fontSize: subtitleFontSize,
                            color: (subtitleColor ?? AppTheme.textSecondary).withValues(alpha: 0.5),
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Next: ${_getNextDueDate()}',
                          style: AppFonts.textStyle(
                            fontSize: subtitleFontSize,
                            fontWeight: FontWeight.w500,
                            color: subtitleColor,
                          ),
                        ),
                        if (expense.autoPost) ...[
                          SizedBox(width: 6),
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 12,
                            color: AppTheme.successColor,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing),
              Text(
                _getAmountText(),
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
}
