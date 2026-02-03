import 'package:flutter/material.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';

enum NavItem { home, budget, report, more }

class BottomNavBar extends StatelessWidget {
  final NavItem currentItem;
  final Function(NavItem) onItemSelected;

  const BottomNavBar({
    super.key,
    required this.currentItem,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use theme card background for consistency
    final bgColor = isDark
        ? AppTheme.darkCardBackground
        : AppTheme.cardBackground;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : AppTheme.primaryColor.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: currentItem == NavItem.home,
                  onTap: () => onItemSelected(NavItem.home),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Budget',
                  isSelected: currentItem == NavItem.budget,
                  onTap: () => onItemSelected(NavItem.budget),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Report',
                  isSelected: currentItem == NavItem.report,
                  onTap: () => onItemSelected(NavItem.report),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'More',
                  isSelected: currentItem == NavItem.more,
                  onTap: () => onItemSelected(NavItem.more),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use complementary color for selected items to create visual interest
    final selectedColor = AppTheme.complementaryColor;
    final unselectedColor = isDark ? Colors.grey[500] : Colors.grey[600];

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? selectedColor : unselectedColor,
            size: isSelected ? 24 : 22,
          ),
          SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AppFonts.textStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? selectedColor : unselectedColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
