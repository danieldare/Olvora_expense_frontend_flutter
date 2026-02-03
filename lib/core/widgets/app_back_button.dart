import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../responsive/responsive_extensions.dart';

/// Reusable app bar back button with chevron-left icon.
/// Theme-aware; defaults to [Navigator.pop] when [onPressed] is null.
class AppBackButton extends StatelessWidget {
  /// Called when the button is tapped. Defaults to [Navigator.pop].
  final VoidCallback? onPressed;

  /// Icon size. Defaults to 26 scaled by context.
  final double? size;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconSize = size ?? 26.scaled(context);

    return IconButton(
      icon: Icon(
        Icons.chevron_left,
        color: isDark ? Colors.white : AppTheme.textPrimary,
        size: iconSize,
      ),
      onPressed: onPressed ?? () => Navigator.pop(context),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 52,
        minHeight: 52,
      ),
    );
  }
}
