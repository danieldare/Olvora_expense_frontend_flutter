import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/user_info_provider.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../expenses/presentation/screens/transactions_list_screen.dart';
import '../../../expenses/presentation/screens/expense_type_selection_screen.dart';
import '../../../expenses/presentation/screens/planned_expenses_screen.dart';
import '../providers/planned_expenses_summary_provider.dart';
import '../../../receipts/presentation/screens/scan_receipt_screen.dart';
import '../../../ora/presentation/screens/ora_chat_screen.dart';
import '../widgets/welcome_header.dart';
import '../widgets/spending_summary_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/spending_trends_chart.dart';
import '../widgets/recent_transactions_list.dart';
import '../../../../core/navigation/bottom_nav_bar.dart';
import '../../../../core/navigation/nav_item.dart';
import '../../../../core/navigation/navigation_providers.dart';
import '../../../more/presentation/screens/more_screen.dart';
import '../../../budget/presentation/screens/budget_screen.dart';
import '../../../report/presentation/screens/report_screen.dart';
import '../../../expenses/presentation/screens/weekly_summary_screen.dart';
import '../../../expenses/presentation/screens/weekly_summary_history_screen.dart';
import '../../../expenses/presentation/providers/weekly_summary_providers.dart';
import '../../../expenses/domain/entities/weekly_summary_entity.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../trips/presentation/widgets/active_trip_banner.dart';
import '../../../trips/presentation/screens/trip_details_screen.dart';
import '../../../../core/widgets/floating_add_expense_button.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Navigation is handled by AuthNavigationCoordinator in AppRoot
    // This screen only displays UI and user data
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.screenBackgroundColor;

    // Navigation is now handled by AuthNavigationCoordinator in AppRoot
    // This screen only renders UI - no auth state listening or navigation logic

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            _buildContentForNav(),
            Positioned(left: 0, right: 0, bottom: 0, child: BottomNavBar()),
            // Floating Add Expense Button (overlaps bottom nav bar)
            const FloatingAddExpenseButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildContentForNav() {
    final currentNavItem = ref.watch(currentNavItemProvider);

    switch (currentNavItem) {
      case NavItem.home:
        // Use centralized user info provider - memoizes user info extraction
        final userInfo = ref.watch(currentUserInfoProvider);
        final userName = userInfo.displayName;
        final userPhotoUrl = userInfo.photoUrl;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  20,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: WelcomeHeader(
                  userName: userName,
                  userPhotoUrl: userPhotoUrl,
                  notificationCount:
                      ref.watch(unreadNotificationCountProvider).valueOrNull ??
                      0,
                ),
              ),
            ),

            // Hero Section - Spending Summary
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.sectionLarge,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: SpendingSummaryCard(compact: true),
              ),
            ),

            // Active Trip Banner (if active trip exists) - reduced gap above to sit closer to budget messages
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.sectionSmall,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: _buildActiveTripBanner(),
              ),
            ),

            // Quick Actions Section (compact) - reduced gap above to sit closer to trip/budget messages
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.spacingXXSmall,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: QuickActions(
                  onAddEntry: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ExpenseTypeSelectionScreen(),
                      ),
                    );
                  },
                  onScanReceipt: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScanReceiptScreen(),
                      ),
                    );
                  },
                  onVoiceInput: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OraChatScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Insights & Quick Access Section (compact)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.sectionMedium,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header
                    Text(
                      'Insights & Quick Access',
                      style: AppFonts.textStyle(
                        fontSize: 14.scaledText(context),
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppTheme.textPrimary,
                        letterSpacing: -0.8,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sectionSmall),

                    // Two-column grid: Weekly Summary and Planned Expenses
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _WeeklySummaryCard()),
                        SizedBox(width: AppSpacing.spacingSmall),
                        Expanded(child: _PlannedExpensesCard()),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Spending Trends Section (compact)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.sectionSmall,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: SpendingTrendsChart(compact: true),
              ),
            ),

            // Recent Activity Section (compact)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.sectionSmall,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: RecentTransactionsList(
                  onSeeAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransactionsListScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Bottom padding for navigation bar and FAB
            SliverToBoxAdapter(
              child: SizedBox(
                height: AppSpacing.bottomNavPadding + AppSpacing.sectionLarge,
              ),
            ),
          ],
        );
      case NavItem.more:
        return const MoreScreen();
      case NavItem.budget:
        return const BudgetScreen();
      case NavItem.report:
        return const ReportScreen();
    }
  }

  /// Build Active Trip Banner
  /// Shows when a Trip is active, hidden when no active Trip
  Widget _buildActiveTripBanner() {
    final activeTripAsync = ref.watch(activeTripProvider);

    // Use skipLoadingOnRefresh to prevent flickering when data refreshes
    return activeTripAsync.when(
      skipLoadingOnRefresh: true,
      data: (activeTrip) {
        if (activeTrip == null) {
          return const SizedBox.shrink();
        }

        return ActiveTripBanner(
          trip: activeTrip,
          onViewTrip: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TripDetailsScreen(tripId: activeTrip.id),
              ),
            );
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

class _WeeklySummaryCard extends ConsumerWidget {
  const _WeeklySummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if there's a new summary (not viewed)
    final summaryAsync = ref.watch(currentWeekSummaryProvider);
    final hasNewSummary = summaryAsync.maybeWhen(
      data: (summary) => summary.status == SummaryStatus.sent,
      orElse: () => false,
    );

    // Use app theme gradient for Weekly Summary
    final gradientColors = AppTheme.walletGradient;
    final gradient = gradientColors.length >= 2
        ? gradientColors
        : [AppTheme.primaryColor, AppTheme.primaryColor];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WeeklySummaryScreen(),
            ),
          );
        },
        onLongPress: () {
          // Long press to view history
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WeeklySummaryHistoryScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(
          AppSpacing.radiusMedium.scaled(context),
        ),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.cardPaddingSmall.scaled(context)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(
              AppSpacing.radiusMedium.scaled(context),
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.3),
                blurRadius: 12.scaled(context),
                offset: Offset(0, 4.scaled(context)),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with badge (compact)
              Stack(
                children: [
                  Container(
                    width: 32.scaledMin(context, 38),
                    height: 32.scaledMin(context, 38),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10.scaled(context)),
                    ),
                    child: Icon(
                      Icons.summarize_rounded,
                      color: Colors.white,
                      size: AppSpacing.iconSizeSmall.scaled(context),
                    ),
                  ),
                  if (hasNewSummary)
                    Positioned(
                      right: -2.scaled(context),
                      top: -2.scaled(context),
                      child: Container(
                        width: 12.scaled(context),
                        height: 12.scaled(context),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade300,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: gradient.first,
                            width: 2.5.scaled(context),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: AppSpacing.spacingMedium),
              // Title
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Weekly Summary',
                      style: AppFonts.textStyle(
                        fontSize: 14.scaledText(context),
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasNewSummary)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.scaled(context),
                        vertical: 2.scaled(context),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade300,
                        borderRadius: BorderRadius.circular(5.scaled(context)),
                      ),
                      child: Text(
                        'New',
                        style: AppFonts.textStyle(
                          fontSize: 8.scaledText(context),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: AppSpacing.spacingXXSmall),
              Text(
                hasNewSummary ? 'New insights available' : 'View your week',
                style: AppFonts.textStyle(
                  fontSize: 11.scaledText(context),
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
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

class _PlannedExpensesCard extends ConsumerWidget {
  const _PlannedExpensesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Light mode: solid shade instead of pure white
    final cardColor = isDark ? AppTheme.darkCardBackground : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark ? Colors.grey[400] : AppTheme.textSecondary;

    // Use combined provider - eliminates nested .when() calls
    final summaryAsync = ref.watch(plannedExpensesSummaryProvider);

    // Use skipLoadingOnRefresh to prevent flickering when data refreshes
    return summaryAsync.when(
      skipLoadingOnRefresh: true,
      data: (summary) {
        final totalPlanned = summary.total;
        final activeFutureExpenses = summary.activeFutureExpenses;
        final activeRecurringExpenses = summary.activeRecurringExpenses;

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
            borderRadius: BorderRadius.circular(
              AppSpacing.radiusLarge.scaled(context),
            ),
            child: Container(
              padding: EdgeInsets.all(
                AppSpacing.cardPaddingSmall.scaled(context),
              ),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(
                  AppSpacing.radiusMedium.scaled(context),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppTheme.borderColor.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark
                          ? AppShadows.cardAlphaDark
                          : AppShadows.cardAlphaLight,
                    ),
                    blurRadius: AppShadows.cardBlur.scaled(context),
                    offset: Offset(0, AppShadows.cardOffsetY.scaled(context)),
                    spreadRadius: AppShadows.cardSpread,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon (compact)
                  Container(
                    width: 32.scaledMin(context, 38),
                    height: 32.scaledMin(context, 38),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(
                        alpha: isDark ? 0.35 : 0.25,
                      ),
                      borderRadius: BorderRadius.circular(10.scaled(context)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentColor.withValues(
                            alpha: isDark ? 0.2 : 0.15,
                          ),
                          blurRadius: 4.scaled(context),
                          offset: Offset(0, 2.scaled(context)),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.event_note_rounded,
                      color: AppTheme.accentColor,
                      size: AppSpacing.iconSizeSmall.scaled(context),
                    ),
                  ),
                  SizedBox(height: AppSpacing.spacingMedium),
                  // Title
                  Text(
                    'Scheduled',
                    style: AppFonts.textStyle(
                      fontSize: 14.scaledText(context),
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppSpacing.spacingXXSmall.scaled(context)),
                  // Count
                  Text(
                    totalPlanned == 0
                        ? 'None'
                        : '$totalPlanned expense${totalPlanned > 1 ? 's' : ''}',
                    style: AppFonts.textStyle(
                      fontSize: 11.scaledText(context),
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.grey[300]
                          : AppTheme.textSecondary.withValues(alpha: 0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (totalPlanned > 0) ...[
                    SizedBox(height: AppSpacing.spacingSmall),
                    // Mini stats
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStatItem(
                            count: activeFutureExpenses,
                            label: 'Future',
                            color: AppTheme.accentColor, // Blue color
                            textColor: textColor,
                            subtitleColor:
                                subtitleColor ?? AppTheme.textSecondary,
                          ),
                        ),
                        SizedBox(width: AppSpacing.spacingXSmall),
                        Expanded(
                          child: _MiniStatItem(
                            count: activeRecurringExpenses,
                            label: 'Recurring',
                            color: AppTheme.successColor, // Green color
                            textColor: textColor,
                            subtitleColor:
                                subtitleColor ?? AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const _ScheduledCardLoader(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ScheduledCardLoader extends StatelessWidget {
  const _ScheduledCardLoader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140.scaledVertical(context), // Compact card height
      child: Center(child: LoadingSpinner.small(color: AppTheme.warningColor)),
    );
  }
}

class _MiniStatItem extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final Color textColor;
  final Color subtitleColor;

  const _MiniStatItem({
    required this.count,
    required this.label,
    required this.color,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6.scaled(context),
        vertical: 5.scaledVertical(context),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.scaled(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: AppFonts.textStyle(
              fontSize: 14.scaledText(context),
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            style: AppFonts.textStyle(
              fontSize: 9.scaledText(context),
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
