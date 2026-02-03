import 'package:flutter/material.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_spacing.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // App version - can be updated manually or via build scripts
  static const String _appVersion = '1.0.0';
  static const String _buildNumber = '1';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppTheme.screenBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, 14, AppSpacing.screenHorizontal, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'About',
                      style: AppFonts.textStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, 16, AppSpacing.screenHorizontal, AppSpacing.bottomNavPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 16),
                    // App Icon/Logo
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.accentColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20),
                    // App Name
                    Text(
                      'TrackSpend',
                      style: AppFonts.textStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 6),
                    // App Version
                    Text(
                      'Version $_appVersion (Build $_buildNumber)',
                      style: AppFonts.textStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: 32),
                    // Description Card
                    _buildInfoCard(
                      context: context,
                      title: 'About TrackSpend',
                      content:
                          'TrackSpend is a powerful expense tracking app designed to help you manage your finances effortlessly. Track your spending, set budgets, analyze trends, and take control of your financial future.',
                    ),
                    SizedBox(height: 12),
                    // Features Card
                    _buildInfoCard(
                      context: context,
                      title: 'Key Features',
                      content: '• Track expenses with ease\n'
                          '• Set and manage budgets\n'
                          '• View spending trends and reports\n'
                          '• Categorize your expenses\n'
                          '• Export your data\n'
                          '• Secure and private',
                    ),
                    SizedBox(height: 12),
                    // Developer Info Card
                    _buildInfoCard(
                      context: context,
                      title: 'Developer Information',
                      content: 'Olvora is developed with ❤️ to help you manage your finances better.\n\n'
                          'For support, feature requests, or feedback, please use the "Request Feature" option in Settings.',
                    ),
                    SizedBox(height: 12),
                    // Copyright
                    Text(
                      '© ${DateTime.now().year} Olvora. All rights reserved.',
                      style: AppFonts.textStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.textStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          Text(
            content,
            style: AppFonts.textStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

