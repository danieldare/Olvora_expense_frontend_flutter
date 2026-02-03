import 'package:flutter/material.dart' hide showModalBottomSheet, showDialog;
import 'package:flutter/material.dart' as material show showModalBottomSheet, showDialog;

/// Global navigator key for accessing Navigator from anywhere
/// This is essential for showing modals/dialogs from services or background tasks
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Service to access Navigator and show modals from anywhere
class NavigatorService {
  static BuildContext? get context => navigatorKey.currentContext;

  static NavigatorState? get navigator => navigatorKey.currentState;

  /// Check if Navigator is available
  static bool get isAvailable => navigator != null && context != null;

  /// Show a modal bottom sheet using the global navigator
  static Future<T?>? showModalBottomSheet<T>({
    required WidgetBuilder builder,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    Color? barrierColor,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
    bool useSafeArea = false,
    String? barrierLabel,
    Duration? transitionDuration,
    Curve? transitionCurve,
  }) {
    if (!isAvailable) {
      debugPrint('⚠️ Navigator not available. Modal cannot be shown.');
      return null;
    }

    return material.showModalBottomSheet<T>(
      context: context!,
      builder: builder,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      barrierColor: barrierColor,
      isScrollControlled: isScrollControlled,
      useRootNavigator: useRootNavigator,
      useSafeArea: useSafeArea,
      barrierLabel: barrierLabel,
    );
  }

  /// Show a dialog using the global navigator
  static Future<T?>? showDialog<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    Offset? anchorPoint,
  }) {
    if (!isAvailable) {
      debugPrint('⚠️ Navigator not available. Dialog cannot be shown.');
      return null;
    }

    return material.showDialog<T>(
      context: context!,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      anchorPoint: anchorPoint,
    );
  }

  /// Push a route using the global navigator
  static Future<T?>? push<T extends Object?>(
    Route<T> route, {
    bool useRootNavigator = false,
  }) {
    if (!isAvailable) {
      debugPrint('⚠️ Navigator not available. Cannot push route.');
      return null;
    }

    return navigator!.push<T>(route);
  }

  /// Pop the current route
  static void pop<T extends Object?>([T? result]) {
    if (!isAvailable) {
      debugPrint('⚠️ Navigator not available. Cannot pop route.');
      return;
    }

    navigator!.pop<T>(result);
  }
}

