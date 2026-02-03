import 'package:flutter/material.dart';
import '../../../../core/widgets/app_back_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/bottom_sheet_modal.dart';
import '../../../../core/widgets/bottom_sheet_option_tile.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/models/currency.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/trip_entity.dart';
import '../providers/trip_providers.dart';
import '../widgets/create_trip_prompt_modal.dart';
import 'trip_details_screen.dart';

/// Trips List Screen
///
/// Shows all trips (active and closed) with ability to:
/// - View trip details
/// - Create new trips
/// - End active trips
class TripsListScreen extends ConsumerStatefulWidget {
  const TripsListScreen({super.key});

  @override
  ConsumerState<TripsListScreen> createState() => _TripsListScreenState();
}

class _TripsListScreenState extends ConsumerState<TripsListScreen> {
  @override
  Widget build(BuildContext context) {
    final activeTripAsync = ref.watch(activeTripProvider);
    final closedTripsAsync = ref.watch(tripsProvider(TripStatus.closed));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.screenBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(),
        title: Text(
          'Trips',
          style: AppFonts.textStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: AppTheme.primaryColor),
            onPressed: () => _showCreateTripModal(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeTripProvider);
          ref.invalidate(tripsProvider(TripStatus.closed));
          ref.read(tripNotifierProvider.notifier).refresh();
        },
        child: _buildBody(activeTripAsync, closedTripsAsync, isDark),
      ),
    );
  }

  /// Single empty state when no trips at all; two sections (Active + Past) when there are any trips.
  Widget _buildBody(
    AsyncValue<TripEntity?> activeTripAsync,
    AsyncValue<List<TripEntity>> closedTripsAsync,
    bool isDark,
  ) {
    if (activeTripAsync.isLoading || closedTripsAsync.isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.screenHorizontal),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      );
    }
    if (activeTripAsync.hasError) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.screenHorizontal),
          child: _buildErrorState(activeTripAsync.error!, isDark),
        ),
      );
    }
    if (closedTripsAsync.hasError) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.screenHorizontal),
          child: _buildErrorState(closedTripsAsync.error!, isDark),
        ),
      );
    }

    final activeTrip = activeTripAsync.valueOrNull;
    final closedTrips = closedTripsAsync.valueOrNull ?? [];
    final noTripsAtAll = activeTrip == null && closedTrips.isEmpty;

    if (noTripsAtAll) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: SizedBox.expand(
              child: Center(
                child: _buildEnhancedEmptyState(isDark),
              ),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Active Trip Section
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Trip',
                  style: AppFonts.textStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 12),
                activeTrip == null
                    ? _buildNoActiveTripState(isDark)
                    : _buildActiveTripCard(
                        activeTrip,
                        isDark,
                        ref.read(currentSessionProvider)?.userId ==
                            activeTrip.ownerId,
                      ),
              ],
            ),
          ),
        ),
        // Past Trips Section
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Past Trips',
                  style: AppFonts.textStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 12),
                closedTrips.isEmpty
                    ? _buildEmptyState(
                        'No past trips',
                        'Closed trips will appear here',
                        isDark,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _groupTripsByDate(closedTrips)
                            .asMap()
                            .entries
                            .map((entry) {
                          final index = entry.key;
                          final group = entry.value;
                          final date = group['date'] as DateTime;
                          final dateTrips =
                              group['trips'] as List<TripEntity>;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: 12,
                              top: index > 0 ? 16 : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    _formatTripDateHeader(date),
                                    style: AppFonts.textStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : AppTheme.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                _buildPastTripsCard(dateTrips, isDark),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.bottomNavPadding),
        ),
      ],
    );
  }

  /// Build active trip card with gradient styling (like selected budget card)
  Widget _buildActiveTripCard(TripEntity trip, bool isDark, bool isOwner) {
    final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
    final currency =
        selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;

    // Use dynamic theme colors for elegant blend
    final gradientColors = AppTheme.walletGradient;
    final primaryColor = AppTheme.primaryColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(bottom: 12),
      height: 130,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors.length >= 2
              ? [gradientColors[0], gradientColors[1]]
              : [primaryColor, primaryColor],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTripOptionsModal(trip, true, isDark),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.name,
                            style: AppFonts.textStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Started: ${DateFormat('MMM d, h:mm a').format(trip.startTime)}',
                            style: AppFonts.textStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        // Delete button (only for owners)
                        if (isOwner)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _showDeleteTripConfirmation(trip);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ),
                        if (isOwner) SizedBox(width: 8),
                        // More options button
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.more_vert_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppTheme.successColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Active',
                            style: AppFonts.textStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${trip.expenseCount} expense${trip.expenseCount != 1 ? 's' : ''} • ${CurrencyFormatter.format(trip.totalSpent, currency)}',
                      style: AppFonts.textStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Group closed trips by date (end date or start date). Most recent first.
  List<Map<String, dynamic>> _groupTripsByDate(List<TripEntity> trips) {
    final map = <DateTime, List<TripEntity>>{};
    for (final trip in trips) {
      final d = trip.endTime != null
          ? DateTime(trip.endTime!.year, trip.endTime!.month, trip.endTime!.day)
          : DateTime(trip.startTime.year, trip.startTime.month, trip.startTime.day);
      map.putIfAbsent(d, () => []).add(trip);
    }
    final sortedDates = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return sortedDates
        .map((date) => {'date': date, 'trips': map[date]!})
        .toList();
  }

  String _formatTripDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (now.difference(dateOnly).inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }

  /// Card containing past trip rows for one date group (like transaction list card).
  Widget _buildPastTripsCard(List<TripEntity> trips, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
        children: trips.asMap().entries.map((entry) {
          final index = entry.key;
          final trip = entry.value;
          final isLast = index == trips.length - 1;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPastTripRow(trip, isDark),
              if (!isLast) const BottomSheetOptionDivider(),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Simple past-trip row (Manage Categories style): divider-separated list.
  Widget _buildPastTripRow(TripEntity trip, bool isDark) {
    final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
    final currency =
        selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;
    const itemPadding = 12.0;
    const iconSize = 20.0;
    const iconBoxWidth = 28.0;
    const titleFontSize = 14.0;
    const subtitleFontSize = 11.0;
    const horizontalGap = 10.0;

    // Time and expense count only (date is in the section header); amount shown prominently on the right
    final timeText = trip.endTime != null
        ? '${DateFormat('h:mm a').format(trip.startTime)} - ${DateFormat('h:mm a').format(trip.endTime!)}'
        : DateFormat('h:mm a').format(trip.startTime);
    final subtitle =
        '$timeText • ${trip.expenseCount} expense${trip.expenseCount != 1 ? 's' : ''}';
    final amountText = CurrencyFormatter.format(trip.totalSpent, currency);
    final amountColor = isDark
        ? Colors.white.withValues(alpha: 0.9)
        : AppTheme.textPrimary;

    return InkWell(
      onTap: () => _showTripOptionsModal(trip, false, isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: itemPadding),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: iconBoxWidth,
              child: Icon(
                Icons.luggage_rounded,
                color: AppTheme.primaryColor,
                size: iconSize,
              ),
            ),
            SizedBox(width: horizontalGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trip.name,
                    style: AppFonts.textStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: AppFonts.textStyle(
                      fontSize: subtitleFontSize,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: horizontalGap),
            Text(
              amountText,
              style: AppFonts.textStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: amountColor,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// Compact state for "no active trip" section (shown when there are past trips)
  Widget _buildNoActiveTripState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppTheme.borderColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor.withValues(alpha: 0.5),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.flight_takeoff_rounded,
                  size: 22,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready for your next adventure?',
                      style: AppFonts.textStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Start a trip to track expenses together',
                      style: AppFonts.textStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCreateTripModal(),
              icon: Icon(Icons.add_rounded, size: 18),
              label: Text(
                'Start Trip',
                style: AppFonts.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, bool isDark) {
    return Container(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.luggage_rounded,
              size: 48,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: AppFonts.textStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: AppFonts.textStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : AppTheme.textSecondary.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Enhanced empty state with visual explanation for first-time users
  Widget _buildEnhancedEmptyState(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hero illustration
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.15),
                  AppTheme.accentColor.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.flight_takeoff_rounded,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 24),

          // Title
          Text(
            'Track Expenses by Trip',
            style: AppFonts.textStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),

          // Subtitle
          Text(
            'Group related expenses together and see exactly how much you spent on each trip or event.',
            style: AppFonts.textStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : AppTheme.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 28),

          // Use case examples
          _buildUseCaseExamples(isDark),
          SizedBox(height: 28),

          // CTA Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCreateTripModal(),
              icon: Icon(Icons.add_rounded, size: 20),
              label: Text(
                'Start Your First Trip',
                style: AppFonts.textStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Visual use case examples showing when to use trips
  Widget _buildUseCaseExamples(bool isDark) {
    final examples = [
      _TripExample(
        icon: Icons.beach_access_rounded,
        title: 'Vacation',
        example: '"Summer trip to Paris"',
        color: AppTheme.accentColor,
      ),
      _TripExample(
        icon: Icons.business_center_rounded,
        title: 'Business',
        example: '"Conference 2024"',
        color: AppTheme.primaryColor,
      ),
      _TripExample(
        icon: Icons.celebration_rounded,
        title: 'Event',
        example: '"Birthday weekend"',
        color: AppTheme.warningColor,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppTheme.borderColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 16,
                color: AppTheme.warningColor,
              ),
              SizedBox(width: 8),
              Text(
                'Perfect for',
                style: AppFonts.textStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Row(
            children: examples.map((e) => Expanded(
              child: _buildExampleChip(e, isDark),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleChip(_TripExample example, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: example.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            example.icon,
            size: 22,
            color: example.color,
          ),
          SizedBox(height: 6),
          Text(
            example.title,
            style: AppFonts.textStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 2),
          Text(
            example.example,
            style: AppFonts.textStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error, bool isDark) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.screenHorizontal),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppTheme.errorColor,
            ),
            SizedBox(height: 12),
            Text(
              'Failed to load trips',
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTripModal() {
    BottomSheetModal.show(
      context: context,
      title: 'Start a New Trip',
      subtitle: 'Track expenses for your vacation, business trip, or event',
      child: CreateTripPromptModal(
        onCreated: () {
          ref.invalidate(activeTripProvider);
          ref.read(tripNotifierProvider.notifier).refresh();
        },
      ),
    );
  }

  void _showTripOptionsModal(TripEntity trip, bool isActive, bool isDark) {
    // Get current user ID to check if they're the owner
    final currentSession = ref.read(currentSessionProvider);
    final isOwner = currentSession?.userId == trip.ownerId;

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
            icon: Icons.visibility_rounded,
            label: 'View Details',
            color: AppTheme.primaryColor,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TripDetailsScreen(tripId: trip.id),
                ),
              );
            },
          ),
          if (isActive) ...[
            const BottomSheetOptionDivider(),
            BottomSheetOptionTile(
              icon: Icons.flag_rounded,
              label: 'End Trip',
              color: AppTheme.errorColor,
              useColorForText: true,
              onTap: () {
                Navigator.pop(context);
                _showEndTripConfirmation(trip);
              },
            ),
          ] else ...[
            const BottomSheetOptionDivider(),
            BottomSheetOptionTile(
              icon: Icons.summarize_rounded,
              label: 'View Summary',
              color: AppTheme.accentColor,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TripDetailsScreen(tripId: trip.id),
                  ),
                );
              },
            ),
          ],
          if (isOwner) ...[
            const BottomSheetOptionDivider(),
            BottomSheetOptionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete Trip',
              color: AppTheme.errorColor,
              useColorForText: true,
              onTap: () {
                Navigator.pop(context);
                _showDeleteTripConfirmation(trip);
              },
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
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
      ref.invalidate(tripsProvider(TripStatus.closed));
      ref.invalidate(tripProvider(trip.id));
      ref.read(tripNotifierProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Trip closed successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
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

  void _showDeleteTripConfirmation(TripEntity trip) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCardBackground : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Trip?',
          style: AppFonts.textStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'This action cannot be undone. All expenses linked to this trip will be unlinked.',
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
              await _deleteTrip(trip);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Delete',
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

  Future<void> _deleteTrip(TripEntity trip) async {
    try {
      final tripService = ref.read(tripServiceProvider);
      await tripService.deleteTrip(trip.id);

      // Refresh trips list
      ref.invalidate(activeTripProvider);
      ref.invalidate(tripsProvider(TripStatus.closed));
      ref.read(tripNotifierProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Trip deleted successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete trip: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

/// Helper class for trip examples
class _TripExample {
  final IconData icon;
  final String title;
  final String example;
  final Color color;

  const _TripExample({
    required this.icon,
    required this.title,
    required this.example,
    required this.color,
  });
}
