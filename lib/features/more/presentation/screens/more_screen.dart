import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/bottom_sheet_modal.dart';
import '../../../../core/widgets/action_card.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/models/currency.dart';
import '../../../../core/services/export_service.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../trips/presentation/screens/trips_list_screen.dart';
import '../../../expenses/presentation/screens/planned_expenses_screen.dart';
import '../../../expenses/presentation/screens/transactions_list_screen.dart';
import '../../../categories/presentation/screens/manage_categories_screen.dart';
import '../../../settings/presentation/screens/about_screen.dart';
import '../../../settings/presentation/screens/privacy_policy_screen.dart';
import '../../../feature_requests/presentation/widgets/feature_request_modal.dart';
import '../../../expenses/presentation/providers/expenses_providers.dart';
import '../../../import/presentation/screens/import_file_screen.dart';
import '../../../report/presentation/providers/export_providers.dart';
import '../../../report/presentation/widgets/export_date_range_dialog.dart';

/// Enhanced color system with pleasant, muted colors
/// Uses softer, more professional palettes that are easier on the eyes
class _EnhancedCardColors {
  /// Transaction History - Soft purple-blue gradient
  static List<Color> getTransactionHistoryGradient(bool isDark) {
    if (isDark) {
      return [
        const Color(0xFF6366F1), // Indigo-500
        const Color(0xFF818CF8), // Indigo-400
      ];
    }
    return [
      const Color(0xFF7C3AED), // Violet-600
      const Color(0xFF8B5CF6), // Violet-500
    ];
  }

  /// Planned Expenses - Soft blue gradient
  static List<Color> getPlannedExpensesGradient(bool isDark) {
    if (isDark) {
      return [
        const Color(0xFF3B82F6), // Blue-500
        const Color(0xFF60A5FA), // Blue-400
      ];
    }
    return [
      const Color(0xFF2563EB), // Blue-600
      const Color(0xFF3B82F6), // Blue-500
    ];
  }

  /// Trips - Soft teal-green gradient
  static List<Color> getTripsGradient(bool isDark) {
    if (isDark) {
      return [
        const Color(0xFF14B8A6), // Teal-500
        const Color(0xFF2DD4BF), // Teal-400
      ];
    }
    return [
      const Color(0xFF0D9488), // Teal-600
      const Color(0xFF14B8A6), // Teal-500
    ];
  }

  /// Manage Categories - Soft amber-orange gradient
  static List<Color> getManageCategoriesGradient(bool isDark) {
    if (isDark) {
      return [
        const Color(0xFFF59E0B), // Amber-500
        const Color(0xFFFBBF24), // Amber-400
      ];
    }
    return [
      const Color(0xFFD97706), // Amber-600
      const Color(0xFFF59E0B), // Amber-500
    ];
  }
}

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.screenBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Hero Streak Section (compact)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.spacingMedium,
                  AppSpacing.screenHorizontal,
                  AppSpacing.spacingSmall,
                ),
                child: _buildHeroStreakCard(context, isDark, ref),
              ),
            ),

            // Quick Access Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.spacingMedium,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: _buildSectionHeader(
                  context,
                  'QUICK ACCESS',
                  isDark,
                  icon: Icons.flash_on_rounded,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.spacingSmall,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: _buildQuickAccessCards(context, isDark),
              ),
            ),

            // App Tools Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.spacingLarge,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: _buildSectionHeader(
                  context,
                  'APP TOOLS',
                  isDark,
                  icon: Icons.apps_rounded,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.spacingSmall,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: _buildAppToolsGrid(context, ref, isDark),
              ),
            ),

            // Legal & Info Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.spacingLarge,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: _buildSectionHeader(
                  context,
                  'LEGAL & INFO',
                  isDark,
                  icon: Icons.info_outline_rounded,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.spacingSmall,
                  AppSpacing.screenHorizontal,
                  AppSpacing.spacingSmall,
                ),
                child: _buildLegalInfoGrid(context, isDark),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.bottomNavPadding),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    bool isDark, {
    IconData? icon,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: EdgeInsets.all(5.scaled(context)),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(
                alpha: isDark ? 0.2 : 0.1,
              ),
              borderRadius: BorderRadius.circular(6.scaled(context)),
            ),
            child: Icon(
              icon,
              size: 12.scaled(context),
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(width: 6.scaled(context)),
        ],
        Text(
          title,
          style: AppFonts.textStyle(
            fontSize: 11.scaledText(context),
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.grey[300] : AppTheme.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroStreakCard(
    BuildContext context,
    bool isDark,
    WidgetRef ref,
  ) {
    final expensesAsync = ref.watch(expensesProvider);

    return expensesAsync.when(
      data: (expenses) {
        int streak = 0;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final expensesByDate = <DateTime, int>{};
        for (final expense in expenses) {
          final expenseDate = DateTime(
            expense.date.year,
            expense.date.month,
            expense.date.day,
          );
          expensesByDate[expenseDate] = (expensesByDate[expenseDate] ?? 0) + 1;
        }

        DateTime checkDate = today;
        while (expensesByDate.containsKey(checkDate) &&
            expensesByDate[checkDate]! > 0) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        }

        final maxDays = 30;
        final progress = (streak / maxDays).clamp(0.0, 1.0);

        return Container(
          height: 108.scaledVertical(context),
          padding: EdgeInsets.all(16.scaled(context)),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardBackground : Colors.white,
            borderRadius: BorderRadius.circular(20.scaled(context)),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: AppShadows.cardAlphaLight,
                      ),
                      blurRadius: AppShadows.cardElevatedBlur.scaled(context),
                      offset: Offset(
                        0,
                        AppShadows.cardElevatedOffsetY.scaled(context),
                      ),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: AppShadows.cardLiftAlphaLight,
                      ),
                      blurRadius: AppShadows.cardLiftBlur.scaled(context),
                      offset: Offset(0, AppShadows.cardLiftOffsetY.scaled(context)),
                      spreadRadius: AppShadows.cardLiftSpread,
                    ),
                  ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.scaled(context),
                            vertical: 4.scaled(context),
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              8.scaled(context),
                            ),
                          ),
                          child: Text(
                            'STREAK',
                            style: AppFonts.textStyle(
                              fontSize: 9.scaledText(context),
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.scaled(context)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$streak',
                          style: AppFonts.textStyle(
                            fontSize: 28.scaledText(context),
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppTheme.textPrimary,
                            letterSpacing: -1.5,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(width: 5.scaled(context)),
                        Text(
                          streak == 1 ? 'day' : 'days',
                          style: AppFonts.textStyle(
                            fontSize: 13.scaledText(context),
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.8)
                                : AppTheme.textPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.scaled(context)),
                    Text(
                      'Daily expense tracking',
                      style: AppFonts.textStyle(
                        fontSize: 11.scaledText(context),
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.scaled(context)),
              // Circular progress with fire icon (compact)
              Container(
                width: 68.scaled(context),
                height: 68.scaled(context),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.15 : 0.1),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6.scaled(context),
                            offset: Offset(0, 3.scaled(context)),
                          ),
                        ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 68.scaled(context),
                      height: 68.scaled(context),
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6.scaled(context),
                        backgroundColor: AppTheme.primaryColor.withValues(
                          alpha: 0.15,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Container(
                      width: 40.scaled(context),
                      height: 40.scaled(context),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.25 : 0.2),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4.scaled(context),
                                  offset: Offset(0, 2.scaled(context)),
                                ),
                              ],
                      ),
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: AppTheme.primaryColor,
                        size: 20.scaled(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 108.scaledVertical(context),
        padding: EdgeInsets.all(16.scaled(context)),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardBackground : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20.scaled(context)),
        ),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildQuickAccessCards(BuildContext context, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 6.scaled(context)),
                child: ActionFeatureCard(
                  icon: Icons.history_rounded,
                  label: 'Transaction History',
                  subtitle: 'View all past transactions',
                  gradient: _EnhancedCardColors.getTransactionHistoryGradient(
                    isDark,
                  ),
                  onTap: () {
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
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 6.scaled(context)),
                child: ActionFeatureCard(
                  icon: Icons.calendar_today_rounded,
                  label: 'Planned Expenses',
                  subtitle: 'Upcoming one-time expenses',
                  gradient: _EnhancedCardColors.getPlannedExpensesGradient(
                    isDark,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlannedExpensesScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.scaled(context)),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 6.scaled(context)),
                child: ActionFeatureCard(
                  icon: Icons.card_travel_rounded,
                  label: 'Trips',
                  subtitle: 'Manage trips and expense sessions',
                  gradient: _EnhancedCardColors.getTripsGradient(isDark),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TripsListScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 6.scaled(context)),
                child: ActionFeatureCard(
                  icon: Icons.grid_view_rounded,
                  label: 'Manage Categories',
                  subtitle: 'Edit expense categories',
                  gradient: _EnhancedCardColors.getManageCategoriesGradient(
                    isDark,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageCategoriesScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAppToolsGrid(BuildContext context, WidgetRef ref, bool isDark) {
    final cardHeight = 72.0.scaledVertical(context); // compact height
    final crossSpacing = 8.scaled(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - 2 * crossSpacing) / 3;
        final childAspectRatio = cellWidth / cardHeight;
        return GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8.scaled(context),
          crossAxisSpacing: crossSpacing,
          childAspectRatio: childAspectRatio,
          children: [
            ActionCard(
              icon: Icons.settings_rounded,
              label: 'Settings',
              color: AppTheme.primaryColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            ActionCard(
              icon: Icons.download_rounded,
              label: 'Export Data',
              color: const Color(0xFF10B981),
              onTap: () {
                _showExportOptions(context, ref);
              },
            ),
            ActionCard(
              icon: Icons.upload_rounded,
              label: 'Import Data',
              color: const Color(0xFF3B82F6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImportFileScreen(),
                  ),
                );
              },
            ),
            ActionCard(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              color: const Color(0xFFF59E0B),
              onTap: () {
                // TODO: Implement help & support
              },
            ),
            ActionCard(
              icon: Icons.lightbulb_outline_rounded,
              label: 'Request Feature',
              color: AppTheme.accentColor,
              onTap: () {
                BottomSheetModal.show(
                  context: context,
                  maxHeightFraction: 0.7,
                  showCloseButton: false,
                  child: const FeatureRequestModal(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegalInfoGrid(BuildContext context, bool isDark) {
    final cardHeight = 72.0.scaledVertical(context); // compact height
    final crossSpacing = 8.scaled(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - 2 * crossSpacing) / 3;
        final childAspectRatio = cellWidth / cardHeight;
        return GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8.scaled(context),
          crossAxisSpacing: crossSpacing,
          childAspectRatio: childAspectRatio,
          children: [
            ActionCard(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              color: const Color(0xFF6366F1),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),
            ActionCard(
              icon: Icons.info_outline_rounded,
              label: 'About',
              color: const Color(0xFF6B7280),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showExportOptions(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    BottomSheetModal.show(
      context: context,
      title: 'Export Data',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ExportOption(
            icon: Icons.table_chart_rounded,
            title: 'Export as XLS',
            subtitle: 'Excel spreadsheet with expenses and summary',
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              _showExportDateRangeDialog(context, ref, 'xls');
            },
          ),
          SizedBox(height: 8),
          _ExportOption(
            icon: Icons.description_rounded,
            title: 'Export as CSV',
            subtitle: 'Comma-separated values file',
            isDark: isDark,
            onTap: () {
              Navigator.pop(context);
              _showExportDateRangeDialog(context, ref, 'csv');
            },
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showExportDateRangeDialog(
    BuildContext context,
    WidgetRef ref,
    String format,
  ) {
    BottomSheetModal.show(
      context: context,
      title: 'Select Date Range',
      child: ExportDateRangeDialog(
        currentPeriod: null, // No current period in more screen
        onConfirm: (startDate, endDate) {
          _handleExport(context, ref, format, startDate, endDate);
        },
        onBack: () {
          Navigator.pop(context);
          _showExportOptions(context, ref);
        },
      ),
    );
  }

  Future<void> _handleExport(
    BuildContext context,
    WidgetRef ref,
    String format,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkCardBackground
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LoadingSpinner.medium(color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text(
                'Preparing export...',
                style: AppFonts.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    bool dialogClosed = false;

    try {
      final currencyAsync = ref.read(selectedCurrencyProvider);
      final currency = currencyAsync.valueOrNull ?? Currency.defaultCurrency;

      // Fetch data
      final dateRange = {'start': startDate, 'end': endDate};
      final expensesAsync = await ref.read(
        exportExpensesProvider(dateRange).future,
      );
      final reportSummaryAsync = await ref.read(
        exportReportSummaryProvider(dateRange).future,
      );
      final categoryBreakdownAsync = await ref.read(
        exportCategoryBreakdownProvider(dateRange).future,
      );

      if (expensesAsync.isEmpty) {
        if (context.mounted && !dialogClosed) {
          Navigator.pop(context);
          dialogClosed = true;
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No data to export for the selected period'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        }
        return;
      }

      // Generate file
      final exportService = ExportService();
      final file = format == 'xls'
          ? await exportService.exportReportToXLS(
              expenses: expensesAsync,
              reportSummary: reportSummaryAsync,
              categoryBreakdown: categoryBreakdownAsync,
              startDate: startDate,
              endDate: endDate,
              currency: currency,
            )
          : await exportService.exportReportToCSV(
              expenses: expensesAsync,
              reportSummary: reportSummaryAsync,
              categoryBreakdown: categoryBreakdownAsync,
              startDate: startDate,
              endDate: endDate,
              currency: currency,
            );

      // Close loading dialog before showing share sheet
      if (context.mounted && !dialogClosed) {
        Navigator.pop(context);
        dialogClosed = true;
      }

      // Share file
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Expense Report Export');

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export completed successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted && !dialogClosed) {
        Navigator.pop(context);
        dialogClosed = true;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      // Ensure dialog is closed even if something unexpected happens
      if (context.mounted && !dialogClosed) {
        Navigator.pop(context);
      }
    }
  }

}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark
          ? AppTheme.borderColor.withValues(alpha: 0.1)
          : AppTheme.borderColor.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(
                    alpha: isDark ? 0.35 : 0.25,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(
                        alpha: isDark ? 0.2 : 0.15,
                      ),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(icon, size: 18, color: AppTheme.primaryColor),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.textStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppFonts.textStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
