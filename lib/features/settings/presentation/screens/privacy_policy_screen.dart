import 'package:flutter/material.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_spacing.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                      'Privacy Policy',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    Text(
                      'Last Updated: ${_getFormattedDate()}',
                      style: AppFonts.textStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildSection(
                      context: context,
                      title: '1. Introduction',
                      content:
                          'Olvora ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
                    ),
                    SizedBox(height: 20),
                    _buildSection(
                      context: context,
                      title: '2. Information We Collect',
                      content:
                          'We collect information that you provide directly to us, including:\n\n'
                          '• Expense data (amounts, categories, dates, notes)\n'
                          '• Budget information\n'
                          '• Category preferences\n'
                          '• App settings and preferences\n\n'
                          'All data is stored locally on your device. We do not collect personal information such as your name, email address, or phone number unless you explicitly provide it.',
                    ),
                    SizedBox(height: 20),
                    _buildSection(
                      context: context,
                      title: '3. How We Use Your Information',
                      content:
                          'We use the information we collect to:\n\n'
                          '• Provide and maintain the app\'s functionality\n'
                          '• Generate reports and analytics\n'
                          '• Improve our services\n'
                          '• Personalize your experience\n'
                          '• Respond to your requests and support needs',
                    ),
                    SizedBox(height: 20),
                    _buildSection(
                      context: context,
                      title: '4. Data Storage and Security',
                      content:
                          'Your data is stored locally on your device. We implement appropriate technical and organizational measures to protect your information. However, no method of transmission over the internet or electronic storage is 100% secure.',
                    ),
                    SizedBox(height: 20),
                    _buildSection(
                      context: context,
                      title: '5. Data Sharing',
                      content:
                          'We do not sell, trade, or rent your personal information to third parties. Your expense data remains on your device and is not transmitted to our servers unless you explicitly choose to use backup or sync features.',
                    ),
                    SizedBox(height: 20),
                    _buildSection(
                      context: context,
                      title: '6. Backup and Sync',
                      content:
                          'If you choose to use backup or sync features, your data may be stored on cloud services. You can manage these settings in the app\'s settings menu. We recommend reviewing the privacy policies of any third-party cloud services you use.',
                    ),
                    SizedBox(height: 20),
                    _buildSection(
                      context: context,
                      title: '7. Your Rights',
                      content:
                          'You have the right to:\n\n'
                          '• Access your data at any time\n'
                          '• Export your data\n'
                          '• Delete your data\n'
                          '• Modify or update your information\n\n'
                          'You can exercise these rights directly through the app\'s features.',
                    ),
                    SizedBox(height: 20),
                    _buildSection(
                      context: context,
                      title: '8. Children\'s Privacy',
                      content:
                          'Our app is not intended for children under the age of 13. We do not knowingly collect personal information from children under 13.',
                    ),
                    SizedBox(height: 20),
                    _buildSection(
                      context: context,
                      title: '9. Changes to This Privacy Policy',
                      content:
                          'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
                    ),
                    SizedBox(height: 20),
                    _buildSection(
                      context: context,
                      title: '10. Contact Us',
                      content:
                          'If you have any questions about this Privacy Policy, please contact us through the "Request Feature" option in the app\'s settings menu.',
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
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

  static String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

