import 'package:flutter/material.dart';

/// Navigation item enum for type-safe navigation
enum NavItem {
  home,
  budget,
  report,
  more;

  /// Get the display label for the navigation item
  String get label {
    switch (this) {
      case NavItem.home:
        return 'Home';
      case NavItem.budget:
        return 'Budget';
      case NavItem.report:
        return 'Report';
      case NavItem.more:
        return 'More';
    }
  }

  /// Get the icon for the navigation item
  IconData get icon {
    switch (this) {
      case NavItem.home:
        return Icons.home_rounded;
      case NavItem.budget:
        return Icons.account_balance_wallet_rounded;
      case NavItem.report:
        return Icons.bar_chart_rounded;
      case NavItem.more:
        return Icons.grid_view_rounded;
    }
  }

  /// Get the semantic label for accessibility
  String get semanticLabel {
    switch (this) {
      case NavItem.home:
        return 'Navigate to home screen';
      case NavItem.budget:
        return 'Navigate to budget screen';
      case NavItem.report:
        return 'Navigate to report screen';
      case NavItem.more:
        return 'Navigate to more screen';
    }
  }
}

