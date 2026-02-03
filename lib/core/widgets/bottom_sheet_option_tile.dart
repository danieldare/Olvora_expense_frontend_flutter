import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';
import '../theme/app_theme.dart';

/// Unified action tile for bottom sheet option modals (edit, delete, view, etc.).
/// Matches the budget screen / category budget options style for consistency.
class BottomSheetOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  /// When true, uses [color] for both icon and text (e.g. delete = error color).
  /// When false, uses [color] for icon only and theme text color for label.
  final bool useColorForText;

  const BottomSheetOptionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.useColorForText = false,
  });

  /// Standard padding for option tiles (horizontal: 16, vertical: 12)
  static const EdgeInsets tilePadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  /// Icon size used in option tiles
  static const double iconSize = 20;

  /// Gap between icon and label
  static const double iconLabelGap = 12;

  /// Label font size
  static const double labelFontSize = 14;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = useColorForText
        ? color
        : (isDark ? Colors.white : AppTheme.textPrimary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: tilePadding,
          child: Row(
            children: [
              Icon(icon, size: iconSize, color: color),
              const SizedBox(width: iconLabelGap),
              Expanded(
                child: Text(
                  label,
                  style: AppFonts.textStyle(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w600,
                    color: textColor,
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

/// Divider between option tiles. Use between actions for consistent styling.
class BottomSheetOptionDivider extends StatelessWidget {
  const BottomSheetOptionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : AppTheme.borderColor,
      ),
    );
  }
}
