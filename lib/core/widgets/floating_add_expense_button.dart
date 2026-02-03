import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../navigation/navigation_config.dart';
import '../../features/expenses/presentation/widgets/quick_add_expense_modal.dart';

/// Floating Add Expense Button
///
/// A small button positioned at the top center of the bottom navigation bar
/// that allows users to quickly add expenses from anywhere in the app.
/// Uses theme-aware colors that adapt to the selected color theme.
class FloatingAddExpenseButton extends StatelessWidget {
  const FloatingAddExpenseButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use wallet gradient for theme consistency, or create theme-aware gradient
    final gradientColors = _getThemeAwareGradient(isDark);
    const buttonSize = 40.0; // Reduced size for more compact look
    const iconSize = 20.0; // Reduced icon size

    // Center the button on the top edge of the nav bar: half inside bar, half outside.
    // Use same config as BottomNavBar so positioning stays in sync.R
    final config = defaultNavigationConfig;
    final contentHeight =
        config.minHeight + config.padding.top + config.padding.bottom;
    // Top of visible bar from SafeArea inner bottom = bottom margin + content height
    final topOfBarFromSafeAreaBottom = config.margin.bottom + contentHeight;
    final padding = MediaQuery.viewPaddingOf(context);
    // Place button center on bar top edge. Nudge down so it visibly sits on the bar (half in, half out, no gap).
    const nudgeDown = 12.0;
    final bottomPosition =
        padding.bottom +
        topOfBarFromSafeAreaBottom -
        (buttonSize / 2) -
        nudgeDown;

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomPosition,
      child: Center(
        child: Material(
          color: Colors.transparent,
          elevation: 0,
          child: InkWell(
            onTap: () => _showAddExpenseModal(context),
            borderRadius: BorderRadius.circular(buttonSize / 2),
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(
                      alpha: isDark ? 0.6 : 0.5,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Get theme-aware gradient colors that align with the current theme
  /// Uses wallet gradient if available, otherwise creates harmonious gradient
  List<Color> _getThemeAwareGradient(bool isDark) {
    final walletGradient = AppTheme.walletGradient;

    // If wallet gradient has colors, use them (they're already theme-aware)
    if (walletGradient.isNotEmpty && walletGradient.length >= 2) {
      return walletGradient;
    }

    // Fallback: Create theme-aware gradient from primary colors
    final primary = AppTheme.primaryColor;
    final secondary = AppTheme.secondaryColor;
    final accent = AppTheme.accentColor;

    // Create darker, more vibrant variations for better visual impact
    return [primary, secondary, accent];
  }

  void _showAddExpenseModal(BuildContext context) {
    QuickAddExpenseModal.show(context: context);
  }
}
