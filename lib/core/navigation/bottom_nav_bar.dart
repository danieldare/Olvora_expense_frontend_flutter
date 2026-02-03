import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_fonts.dart';
import '../theme/app_theme.dart';
import 'nav_item.dart';
import 'navigation_config.dart';
import 'navigation_providers.dart';

/// World-class bottom navigation bar implementation
///
/// Features:
/// - Type-safe navigation using enums
/// - Riverpod state management
/// - Configurable styling
/// - Accessibility support
/// - Smooth animations
/// - Scalable architecture
class BottomNavBar extends ConsumerWidget {
  /// Configuration for styling
  final NavigationConfig config;

  /// List of navigation items to display
  /// If null, displays all items from NavItem enum
  final List<NavItem>? items;

  BottomNavBar({super.key, NavigationConfig? config, this.items})
    : config = config ?? defaultNavigationConfig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentItem = ref.watch(currentNavItemProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get items to display (default to all if not specified)
    final itemsToShow = items ?? NavItem.values;
    final bgColor = config.backgroundColor(isDark);
    final shadow = config.boxShadow ?? NavigationConfig.defaultShadow;
    final border = config.border(isDark);

    return SafeArea(
      child: Container(
        margin: config.margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(config.containerBorderRadius),
          border: border,
          boxShadow: shadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(config.containerBorderRadius),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(
                config.containerBorderRadius,
              ),
              border: border,
            ),
            constraints: BoxConstraints(minHeight: config.minHeight),
            padding: config.padding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: itemsToShow.map((item) {
                return Expanded(
                  child: _NavItem(
                    item: item,
                    isSelected: currentItem == item,
                    config: config,
                    onTap: () {
                      ref
                          .read(currentNavItemProvider.notifier)
                          .navigateTo(item);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual navigation item widget
class _NavItem extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final NavigationConfig config;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.config,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use theme's text secondary color for inactive items
    final inactiveColor = AppTheme.textSecondary;
    // Use theme's navigation active color - automatically handles Purple Night yellow
    final activeColor = AppTheme.navigationActiveColor;

    return Semantics(
      label: item.semanticLabel,
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              color: isSelected ? activeColor : inactiveColor,
              size: isSelected
                  ? config.selectedIconSize
                  : config.unselectedIconSize,
            ),
            SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.label,
                style: AppFonts.textStyle(
                  fontSize: config.labelFontSize,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
