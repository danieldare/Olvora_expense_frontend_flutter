import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/bottom_sheet_modal.dart';
import '../../../../core/widgets/bottom_sheet_option_tile.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import '../../domain/entities/trip_entity.dart';
import '../providers/trip_providers.dart';
import '../providers/trip_expenses_providers.dart';
import '../widgets/add_trip_message_modal.dart';
import '../widgets/invite_participant_modal.dart';
import '../widgets/expense_split_modal.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../expenses/presentation/screens/transaction_details_screen.dart';
import '../../../expenses/presentation/widgets/quick_add_expense_modal.dart';
import '../../../../core/providers/currency_providers.dart';

/// Trip Details Screen
///
/// Shows full details of a Trip including:
/// - Trip information (name, dates, status)
/// - Linked expenses
/// - Messages (if shared)
/// - Participants (if shared)
/// - Actions (end trip, share, etc.)
class TripDetailsScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripDetailsScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends ConsumerState<TripDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripProvider(widget.tripId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.screenBackgroundColor,
      body: SafeArea(
        child: tripAsync.when(
          data: (trip) => _buildTripContent(trip, isDark),
          loading: () => Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
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
                SizedBox(height: 16),
                Text(
                  'Failed to load trip',
                  style: AppFonts.textStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: AppFonts.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: tripAsync.valueOrNull?.status == TripStatus.active
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToAddExpense(),
              backgroundColor: AppTheme.primaryColor,
              icon: Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'Add Expense',
                style: AppFonts.textStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTripContent(TripEntity trip, bool isDark) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        // Header with back button and title
        SliverToBoxAdapter(child: _buildHeader(trip, isDark)),

        // Content
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Trip Info Card (replaces hero)
              _buildTripInfoCard(trip, isDark),
              SizedBox(height: 20),

              // Expenses Section
              _buildExpensesSection(trip, isDark),
              SizedBox(height: 20),

              // Participants Section (if shared)
              if (trip.visibility == TripVisibility.shared) ...[
                _buildParticipantsSection(trip, isDark),
                SizedBox(height: 20),
              ],

              // Messages Section (if shared)
              if (trip.visibility == TripVisibility.shared)
                _buildMessagesSection(trip, isDark),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.bottomNavPadding),
        ),
      ],
    );
  }

  Widget _buildHeader(TripEntity trip, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 10, 0),
      child: Row(
        children: [
          AppBackButton(),
          Expanded(
            child: Text(
              'Trip Details',
              style: AppFonts.textStyle(
                fontSize: 18.scaledText(context),
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (trip.status == TripStatus.active)
            GestureDetector(
              onTap: () => _showTripOptions(trip),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppTheme.borderColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.more_horiz_rounded,
                  size: 20,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTripInfoCard(TripEntity trip, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.walletGradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.walletGradient.isNotEmpty
                ? AppTheme.walletGradient.first.withValues(alpha: 0.3)
                : AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with icon and status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.luggage_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  trip.name,
                  style: AppFonts.textStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Status Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: trip.status == TripStatus.active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      trip.status == TripStatus.active ? 'Active' : 'Closed',
                      style: AppFonts.textStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              // Total Spent
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Spent',
                      style: AppFonts.textStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${trip.currency} ${trip.totalSpent.toStringAsFixed(2)}',
                      style: AppFonts.textStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Vertical divider
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              SizedBox(width: 16),
              // Expenses count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expenses',
                      style: AppFonts.textStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${trip.expenseCount}',
                      style: AppFonts.textStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Date info
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Started ${DateFormat('MMM d, y').format(trip.startTime)} at ${DateFormat('h:mm a').format(trip.startTime)}',
                  style: AppFonts.textStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesSection(TripEntity trip, bool isDark) {
    final expensesAsync = ref.watch(tripExpensesProvider(trip.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Expenses',
              style: AppFonts.textStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            if (trip.expenseCount > 0)
              Text(
                '${trip.expenseCount}',
                style: AppFonts.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : AppTheme.textSecondary,
                ),
              ),
          ],
        ),
        SizedBox(height: 16),
        expensesAsync.when(
          data: (expenses) {
            if (expenses.isEmpty) {
              return _buildEmptyExpensesState(trip, isDark);
            }

            return Column(
              children: expenses.asMap().entries.map((entry) {
                final index = entry.key;
                final expense = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < expenses.length - 1 ? 12 : 0,
                  ),
                  child: _buildExpenseCard(expense, trip, isDark),
                );
              }).toList(),
            );
          },
          loading: () => Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 48),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBackground : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppTheme.borderColor.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ),
          error: (error, stack) => _buildErrorState(isDark),
        ),
      ],
    );
  }

  Widget _buildEmptyExpensesState(TripEntity trip, bool isDark) {
    final isActive = trip.status == TripStatus.active;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppTheme.borderColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 32,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 16),
          Text(
            isActive ? 'Ready to track expenses' : 'No expenses recorded',
            style: AppFonts.textStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          Text(
            isActive
                ? 'Add your first expense to start\ntracking this trip\'s spending'
                : 'This trip ended without\nany recorded expenses',
            style: AppFonts.textStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (isActive) ...[
            SizedBox(height: 20),
            // Quick add options hint
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : AppTheme.borderColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildQuickOptionIcon(Icons.edit_rounded, AppTheme.primaryColor),
                  SizedBox(width: 8),
                  _buildQuickOptionIcon(Icons.camera_alt_rounded, AppTheme.accentColor),
                  SizedBox(width: 8),
                  _buildQuickOptionIcon(Icons.mic_rounded, AppTheme.warningColor),
                  SizedBox(width: 12),
                  Text(
                    'Type, scan, or speak',
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
          ],
        ],
      ),
    );
  }

  Widget _buildQuickOptionIcon(IconData icon, Color color) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }

  Widget _buildExpenseCard(
    ExpenseEntity expense,
    TripEntity trip,
    bool isDark,
  ) {
    final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
    final currency = selectedCurrencyAsync.valueOrNull?.code ?? trip.currency;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TransactionDetailsScreen(transaction: expense),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardBackground : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppTheme.borderColor.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.receipt_rounded,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ),
              SizedBox(width: 14),
              // Expense Info
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
                    SizedBox(height: 4),
                    Text(
                      expense.merchant != null
                          ? '${DateFormat('MMM d, h:mm a').format(expense.date)} · ${expense.merchant}'
                          : DateFormat('MMM d, h:mm a').format(expense.date),
                      style: AppFonts.textStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Amount
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$currency ${expense.amount.toStringAsFixed(2)}',
                    style: AppFonts.textStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (trip.visibility == TripVisibility.shared &&
                      trip.status == TripStatus.active)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: GestureDetector(
                        onTap: () => _showExpenseSplitModal(expense, trip),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Split',
                            style: AppFonts.textStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppTheme.borderColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: AppTheme.errorColor.withValues(alpha: 0.7),
          ),
          SizedBox(height: 12),
          Text(
            'Failed to load expenses',
            style: AppFonts.textStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection(TripEntity trip, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Participants',
              style: AppFonts.textStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '${trip.participants.length}',
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardBackground : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppTheme.borderColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: trip.participants.asMap().entries.map((entry) {
              final index = entry.key;
              final participant = entry.value;
              final isLast = index == trip.participants.length - 1;

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primaryColor.withValues(
                        alpha: 0.1,
                      ),
                      child: Text(
                        participant.userName[0].toUpperCase(),
                        style: AppFonts.textStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            participant.userName,
                            style: AppFonts.textStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (participant.role == TripParticipantRole.owner)
                            Text(
                              'Owner',
                              style: AppFonts.textStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : AppTheme.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesSection(TripEntity trip, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Messages',
              style: AppFonts.textStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            if (trip.status == TripStatus.active)
              TextButton(
                onPressed: () => _showAddMessageModal(trip),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Add',
                      style: AppFonts.textStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        SizedBox(height: 16),
        if (trip.messages.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBackground : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppTheme.borderColor.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 32,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppTheme.textSecondary.withValues(alpha: 0.3),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No messages yet',
                    style: AppFonts.textStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCardBackground : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppTheme.borderColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: trip.messages.asMap().entries.map((entry) {
                final index = entry.key;
                final message = entry.value;
                final isSystem = message.type == TripMessageType.system;
                final isLast = index == trip.messages.length - 1;

                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isSystem && message.senderName != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            message.senderName!,
                            style: AppFonts.textStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Text(
                        message.message,
                        style: AppFonts.textStyle(
                          fontSize: 14,
                          fontWeight: isSystem
                              ? FontWeight.w400
                              : FontWeight.w500,
                          color: isSystem
                              ? (isDark
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : AppTheme.textSecondary)
                              : (isDark
                                    ? Colors.white
                                    : AppTheme.textPrimary),
                        ).copyWith(
                          fontStyle: isSystem
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, h:mm a').format(message.createdAt),
                        style: AppFonts.textStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.4)
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  void _navigateToAddExpense() {
    QuickAddExpenseModal.show(context: context, tripId: widget.tripId).then((
      _,
    ) {
      // Refresh trip data after adding expense (if modal was closed after navigation)
      if (mounted) {
        ref.invalidate(tripProvider(widget.tripId));
        ref.invalidate(tripExpensesProvider(widget.tripId));
      }
    });
  }

  void _showTripOptions(TripEntity trip) {
    BottomSheetModal.show(
      context: context,
      title: trip.name,
      subtitle: 'Manage trip',
      borderRadius: 20,
      isScrollControlled: false,
      isScrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomSheetOptionTile(
            icon: Icons.share_rounded,
            label: 'Share Trip',
            color: AppTheme.primaryColor,
            onTap: () {
              Navigator.pop(context);
              _showShareTripModal(trip);
            },
          ),
          const BottomSheetOptionDivider(),
          BottomSheetOptionTile(
            icon: Icons.close_rounded,
            label: 'End Trip',
            color: AppTheme.errorColor,
            useColorForText: true,
            onTap: () {
              Navigator.pop(context);
              _showEndTripConfirmation(trip);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showExpenseSplitModal(ExpenseEntity expense, TripEntity trip) {
    BottomSheetModal.show(
      context: context,
      title: 'Expense Split',
      subtitle: 'Manage how this expense is split among participants',
      child: ExpenseSplitModal(tripId: trip.id, expense: expense, trip: trip),
    );
  }

  void _showEndTripConfirmation(TripEntity trip) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCardBackground : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'End Trip?',
          style: AppFonts.textStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'End this trip? You can\'t add more expenses after closing.',
          style: AppFonts.textStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppFonts.textStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _endTrip(trip);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'End Trip',
              style: AppFonts.textStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _endTrip(TripEntity trip) async {
    try {
      final tripService = ref.read(tripServiceProvider);
      await tripService.closeTrip(trip.id);

      // Invalidate all trip-related providers to refresh everywhere
      ref.invalidate(activeTripProvider);
      ref.invalidate(tripProvider(widget.tripId));
      ref.invalidate(tripsProvider(TripStatus.closed));
      ref.read(tripNotifierProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Trip closed successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to close trip: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showAddMessageModal(TripEntity trip) {
    BottomSheetModal.show(
      context: context,
      title: 'Add Message',
      subtitle: 'Add a contextual message to this trip',
      child: AddTripMessageModal(
        tripId: trip.id,
        onMessageAdded: () {
          ref.invalidate(tripProvider(widget.tripId));
        },
      ),
    );
  }

  void _showShareTripModal(TripEntity trip) {
    BottomSheetModal.show(
      context: context,
      title: 'Share Trip',
      subtitle: 'Invite participants to this trip',
      child: InviteParticipantModal(
        tripId: trip.id,
        onParticipantInvited: () {
          ref.invalidate(tripProvider(widget.tripId));
        },
      ),
    );
  }
}
