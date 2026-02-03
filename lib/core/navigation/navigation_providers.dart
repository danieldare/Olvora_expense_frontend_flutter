import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'nav_item.dart';

/// Provider for managing the current navigation item
final currentNavItemProvider = StateNotifierProvider<NavItemNotifier, NavItem>(
  (ref) => NavItemNotifier(),
);

/// Notifier for managing navigation state
class NavItemNotifier extends StateNotifier<NavItem> {
  NavItemNotifier() : super(NavItem.home);

  /// Navigate to a specific item
  void navigateTo(NavItem item) {
    if (state != item) {
      state = item;
    }
  }

  /// Reset to home
  void reset() {
    state = NavItem.home;
  }
}
