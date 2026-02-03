import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';
import '../theme/app_theme.dart';

/// World-class Selection Pill Widget
///
/// A flexible, reusable pill/chip widget for selections with optional icons,
/// text labels, and descriptions. Supports both compact pills (for Wrap layouts)
/// and expanded cards (for Row layouts).
///
/// Features:
/// - Optional icon support
/// - Selected/unselected states with smooth animations
/// - Compact and expanded variants
/// - World-class design with proper theming
/// - Accessible and touch-friendly
class SelectionPill extends StatelessWidget {
  /// The text label to display
  final String label;

  /// Optional icon to display before the label
  final IconData? icon;

  /// Optional description text (shown below label in expanded mode)
  final String? description;

  /// Whether this pill is selected
  final bool isSelected;

  /// Callback when the pill is tapped
  final VoidCallback onTap;

  /// Whether to use expanded layout (for Row layouts with descriptions)
  final bool isExpanded;

  /// Custom selected color (defaults to AppTheme.primaryColor)
  final Color? selectedColor;

  /// Custom icon size (defaults to 18)
  final double? iconSize;

  /// Whether the pill is disabled
  final bool isDisabled;

  const SelectionPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.description,
    this.isExpanded = false,
    this.selectedColor,
    this.iconSize,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveSelectedColor = selectedColor ?? AppTheme.primaryColor;
    final effectiveIconSize = iconSize ?? 18.0;

    if (isExpanded && description != null) {
      return _buildExpandedPill(isDark, effectiveSelectedColor, effectiveIconSize);
    } else {
      return _buildCompactPill(isDark, effectiveSelectedColor, effectiveIconSize);
    }
  }

  /// Compact pill for Wrap layouts (frequency, priority, etc.)
  Widget _buildCompactPill(
    bool isDark,
    Color effectiveSelectedColor,
    double effectiveIconSize,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: icon != null ? 14 : 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? effectiveSelectedColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? effectiveSelectedColor
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : AppTheme.borderColor),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: effectiveSelectedColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: effectiveIconSize,
                  color: isSelected
                      ? effectiveSelectedColor
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppTheme.textSecondary),
                ),
                SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppFonts.textStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isDisabled
                      ? (isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : AppTheme.textSecondary.withValues(alpha: 0.3))
                      : (isSelected
                          ? effectiveSelectedColor
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppTheme.textPrimary)),
                  letterSpacing: isSelected ? 0.2 : 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Expanded pill for Row layouts (amount type, date flexibility, etc.)
  Widget _buildExpandedPill(
    bool isDark,
    Color effectiveSelectedColor,
    double effectiveIconSize,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? effectiveSelectedColor.withValues(alpha: 0.12)
                : (isDark
                    ? AppTheme.darkCardBackground
                    : Colors.white.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? effectiveSelectedColor
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppTheme.borderColor),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: effectiveSelectedColor.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: effectiveIconSize,
                      color: isSelected
                          ? effectiveSelectedColor
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.6)
                              : AppTheme.textSecondary),
                    ),
                    SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: AppFonts.textStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isDisabled
                            ? (isDark
                                ? Colors.white.withValues(alpha: 0.3)
                                : AppTheme.textSecondary.withValues(alpha: 0.3))
                            : (isSelected
                                ? effectiveSelectedColor
                                : (isDark
                                    ? Colors.white
                                    : AppTheme.textPrimary)),
                        letterSpacing: isSelected ? 0.1 : 0,
                      ),
                    ),
                  ),
                ],
              ),
              if (description != null) ...[
                SizedBox(height: 6),
                Text(
                  description!,
                  style: AppFonts.textStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDisabled
                        ? (isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppTheme.textSecondary.withValues(alpha: 0.2))
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : AppTheme.textSecondary),
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper widget for building a group of selection pills with a label
///
/// This widget provides a consistent layout for selection groups across
/// all expense screens, with proper spacing and theming.
class SelectionPillGroup extends StatelessWidget {
  /// The label/title for the group
  final String label;

  /// Optional help icon callback
  final VoidCallback? onHelpTap;

  /// The pills to display
  final List<Widget> children;

  /// Whether to use Wrap layout (for compact pills) or Row layout (for expanded pills)
  final bool useWrap;

  /// Spacing between pills (defaults to 8 for Wrap, 8 for Row)
  final double spacing;

  const SelectionPillGroup({
    super.key,
    required this.label,
    required this.children,
    this.onHelpTap,
    this.useWrap = true,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.textSecondary,
              ),
            ),
            if (onHelpTap != null) ...[
              SizedBox(width: 6),
              GestureDetector(
                onTap: onHelpTap,
                child: Icon(
                  Icons.help_outline_rounded,
                  size: 16,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 12),
        if (useWrap)
          Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: children,
          )
        else
          Row(
            children: children.asMap().entries.map((entry) {
              final index = entry.key;
              final child = entry.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < children.length - 1 ? spacing : 0,
                  ),
                  child: child,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

