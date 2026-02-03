import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';

/// Beautiful empty state with onboarding tips
class EmptyStateWidget extends StatelessWidget {
  final bool isDark;

  const EmptyStateWidget({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.accentColor,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.mic_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 32),
            // Title
            Text(
              'Voice Expense',
              style: AppFonts.textStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 12),
            // Subtitle
            Text(
              'Speak naturally, I\'ll understand',
              style: AppFonts.textStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            // Tips
            _buildTipCard(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Example',
              description: '"Lunch at Chicken Republic, ₦4,500 yesterday"',
              isDark: isDark,
            ),
            SizedBox(height: 16),
            _buildTipCard(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Multi-turn',
              description: 'You can add details across multiple voice inputs',
              isDark: isDark,
            ),
            SizedBox(height: 16),
            _buildTipCard(
              icon: Icons.edit_outlined,
              title: 'Corrections',
              description: 'Say "actually make that ₦3,800" to fix anything',
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey[850]!.withOpacity(0.5)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: AppFonts.textStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
