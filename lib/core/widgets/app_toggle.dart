import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

/// Reusable toggle switch component with theme-aware colors
///
/// Features:
/// - Theme-aware enabled/disabled colors
/// - Purple shade for enabled state (white thumb on purple track)
/// - Dark blue-grey shade for disabled state (white thumb on dark blue-grey track)
/// - Supports both Material and Cupertino styles
class AppToggle extends StatelessWidget {
  /// Current value of the toggle
  final bool value;

  /// Callback when the toggle is changed
  final ValueChanged<bool>? onChanged;

  /// Whether to use Cupertino (iOS) style or Material style
  /// Defaults to Material style
  final bool useCupertinoStyle;

  /// Custom enabled color (optional, defaults to AppTheme.primaryColor)
  final Color? enabledColor;

  /// Custom disabled color (optional, defaults to grey based on theme)
  final Color? disabledColor;

  const AppToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.useCupertinoStyle = false,
    this.enabledColor,
    this.disabledColor,
  });

  /// Get the enabled color based on theme
  Color _getEnabledColor(BuildContext context) {
    if (enabledColor != null) return enabledColor!;
    return AppTheme.primaryColor; // Purple shade
  }

  /// Get the disabled track color based on theme
  /// Dark blue-grey for disabled state (matching reference image)
  Color _getDisabledTrackColor(BuildContext context) {
    if (disabledColor != null) return disabledColor!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Dark blue-grey shade for disabled track (matching reference)
    return isDark
        ? const Color(0xFF475569) // Dark blue-grey for dark mode
        : const Color(0xFF94A3B8); // Lighter blue-grey for light mode
  }

  @override
  Widget build(BuildContext context) {
    if (useCupertinoStyle) {
      return CupertinoSwitch(
        value: value,
        activeTrackColor: _getEnabledColor(context),
        onChanged: onChanged,
      );
    }

    // Material Switch - matching reference images
    final enabledColor = _getEnabledColor(context);
    final disabledTrackColor = _getDisabledTrackColor(context);
    
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: enabledColor, // Purple track when enabled
      activeTrackColor: enabledColor, // Purple track when enabled
      thumbColor: WidgetStateProperty.resolveWith((states) {
        // White thumb for both enabled and disabled states (matching reference)
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return enabledColor; // Purple when enabled
        }
        return disabledTrackColor; // Dark blue-grey when disabled
      }),
    );
  }
}

