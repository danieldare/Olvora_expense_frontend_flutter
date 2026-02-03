import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import '../../../user_preferences/presentation/providers/user_preferences_providers.dart';
import '../../domain/entities/weekly_summary_entity.dart';
import '../providers/weekly_summary_providers.dart';
import 'weekly_summary_screen.dart';

/// History screen showing past weeks' summaries
///
/// Allows users to view summaries from previous weeks
class WeeklySummaryHistoryScreen extends ConsumerStatefulWidget {
  const WeeklySummaryHistoryScreen({super.key});

  @override
  ConsumerState<WeeklySummaryHistoryScreen> createState() =>
      _WeeklySummaryHistoryScreenState();
}

class _WeeklySummaryHistoryScreenState
    extends ConsumerState<WeeklySummaryHistoryScreen> {
  final List<DateTime> _weeksToLoad = [];

  @override
  void initState() {
    super.initState();
    _loadWeeks();
  }

  Future<void> _loadWeeks() async {
    // Load last 12 weeks (3 months)
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final weekStart = await _getWeekStart(now.subtract(Duration(days: i * 7)), ref);
      if (!_weeksToLoad.contains(weekStart)) {
        _weeksToLoad.add(weekStart);
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<DateTime> _getWeekStart(DateTime date, WidgetRef ref) async {
    // Get user's week start day preference from backend
    int weekStartDay = 0; // Default to Sunday
    try {
      final preferences = await ref.read(userPreferencesProvider.future);
      weekStartDay = preferences.weekStartDay.toNumber();
    } catch (e) {
      weekStartDay = 0; // Default to Sunday
    }
    
    final d = DateTime(date.year, date.month, date.day);
    final dayOfWeek = d.weekday; // Monday = 1, Sunday = 7
    int daysToSubtract;
    if (weekStartDay == 0) {
      // Week starts on Sunday
      daysToSubtract = dayOfWeek == 7 ? 0 : dayOfWeek;
    } else {
      // Week starts on Monday
      daysToSubtract = dayOfWeek == 7 ? 6 : dayOfWeek - 1;
    }
    return d.subtract(Duration(days: daysToSubtract));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : AppTheme.backgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(),
        title: Text(
          'Weekly Summary History',
          style: AppFonts.textStyle(
            fontSize: 17.scaledText(context),
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, 10, AppSpacing.screenHorizontal, AppSpacing.bottomNavPadding),
          itemCount: _weeksToLoad.length,
          itemBuilder: (context, index) {
            final weekStart = _weeksToLoad[index];
            return _WeekSummaryCard(weekStart: weekStart);
          },
        ),
      ),
    );
  }
}

class _WeekSummaryCard extends ConsumerWidget {
  final DateTime weekStart;

  const _WeekSummaryCard({required this.weekStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCardBackground : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtitleColor = isDark ? Colors.grey[400] : AppTheme.textSecondary;

    // Format week period
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekStartStr = DateFormat('MMM d').format(weekStart);
    final weekEndStr = DateFormat('MMM d, yyyy').format(weekEnd);
    final weekPeriod = '$weekStartStr - $weekEndStr';

    // Load summary for this week
    final summaryAsync = FutureProvider<WeeklySummaryEntity?>((ref) async {
      final service = ref.watch(weeklySummaryServiceProvider);
      return service.getWeekSummary(weekStart);
    });

    return Consumer(
      builder: (context, ref, child) {
        final summary = ref.watch(summaryAsync);

        return summary.when(
          data: (summaryData) {
            if (summaryData == null) {
              // No summary for this week
              return Container(
                margin: EdgeInsets.only(bottom: 8.scaledVertical(context)),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppTheme.borderColor,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: 18,
                      color: subtitleColor,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            weekPeriod,
                            style: AppFonts.textStyle(
                              fontSize: 13.scaledText(context),
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'No summary available',
                            style: AppFonts.textStyle(
                              fontSize: 11.scaledText(context),
                              fontWeight: FontWeight.w400,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Summary exists - show preview
            return GestureDetector(
              onTap: () {
                // Navigate to full summary view
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeeklySummaryDetailScreen(
                      weekStart: weekStart,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppTheme.borderColor,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          weekPeriod,
                          style: AppFonts.textStyle(
                            fontSize: 14.scaledText(context),
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14.scaled(context),
                          color: subtitleColor,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      summaryData.headline,
                      style: AppFonts.textStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        _StatBadge(
                          label: 'Total',
                          value: NumberFormat.currency(
                            symbol: '₦',
                            decimalDigits: 0,
                          ).format(summaryData.totalSpent),
                          isDark: isDark,
                        ),
                        if (summaryData.topCategory != null) ...[
                          SizedBox(width: 10),
                          _StatBadge(
                            label: 'Top',
                            value: summaryData.topCategory!,
                            isDark: isDark,
                          ),
                        ],
                        if (summaryData.weekOverWeekChange != null) ...[
                          SizedBox(width: 10),
                          _StatBadge(
                            label: 'Change',
                            value:
                                '${summaryData.weekOverWeekChange! > 0 ? '+' : ''}${summaryData.weekOverWeekChange!.toStringAsFixed(1)}%',
                            isDark: isDark,
                            isPositive: summaryData.weekOverWeekChange! < 0,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('Loading...', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool isPositive;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.isDark,
    this.isPositive = false,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleColor = isDark ? Colors.grey[400] : AppTheme.textSecondary;
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isPositive
            ? AppTheme.successColor.withValues(alpha: 0.15)
            : (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppTheme.borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppFonts.textStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
          ),
          SizedBox(height: 1),
          Text(
            value,
            style: AppFonts.textStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isPositive ? AppTheme.successColor : textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Detail screen for a specific week's summary
/// 
/// Note: This reuses WeeklySummaryScreen but could be enhanced
/// to show a specific week's summary instead of current week
class WeeklySummaryDetailScreen extends StatelessWidget {
  final DateTime weekStart;

  const WeeklySummaryDetailScreen({
    super.key,
    required this.weekStart,
  });

  @override
  Widget build(BuildContext context) {
    // For now, navigate to main summary screen
    // Future enhancement: Pass weekStart to show specific week
    return const WeeklySummaryScreen();
  }
}

