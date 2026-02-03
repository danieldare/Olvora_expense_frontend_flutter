import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Reusable Ora AI avatar widget
/// Displays the circular "O" icon with gradient background
class OraAvatarWidget extends StatelessWidget {
  final double size;
  final double fontSize;

  const OraAvatarWidget({
    super.key,
    this.size = 28,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'O',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}
