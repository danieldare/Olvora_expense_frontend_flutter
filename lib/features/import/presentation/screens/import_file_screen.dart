import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import 'import_preview_screen.dart';

/// Clean, modern import screen with world-class UX
class ImportFileScreen extends ConsumerStatefulWidget {
  const ImportFileScreen({super.key});

  @override
  ConsumerState<ImportFileScreen> createState() => _ImportFileScreenState();
}

class _ImportFileScreenState extends ConsumerState<ImportFileScreen> {
  bool _isPicking = false;

  Future<void> _pickFile() async {
    setState(() => _isPicking = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.single;
        PlatformFile fileToUse = platformFile;

        if (platformFile.bytes == null && platformFile.path != null) {
          final file = File(platformFile.path!);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            fileToUse = PlatformFile(
              name: platformFile.name,
              size: platformFile.size,
              bytes: bytes,
              path: platformFile.path,
            );
          } else {
            throw Exception('File not accessible');
          }
        }

        if (fileToUse.bytes == null) {
          throw Exception('Unable to read file');
        }

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImportPreviewScreen(file: fileToUse),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.screenBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 16, 0),
                child: Row(
                  children: [
                    AppBackButton(),
                    Text(
                      'Import Data',
                      style: AppFonts.textStyle(
                        fontSize: 18.scaledText(context),
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Column(
                  children: [
                    const Spacer(flex: 1),

                    // Upload section
                    _UploadSection(
                      isPicking: _isPicking,
                      isDark: isDark,
                      onTap: _pickFile,
                    ),

                    const Spacer(flex: 1),

                    // Pro tips
                    _ProTipsSection(isDark: isDark),

                    SizedBox(height: AppSpacing.bottomNavPadding),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Upload section with icon and button
class _UploadSection extends StatelessWidget {
  final bool isPicking;
  final bool isDark;
  final VoidCallback onTap;

  const _UploadSection({
    required this.isPicking,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.file_upload_outlined,
            size: 32,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: 20),

        // Title
        Text(
          'Import from spreadsheet',
          style: AppFonts.textStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 6),

        // Subtitle
        Text(
          'We support Excel (.xlsx, .xls) and CSV files',
          style: AppFonts.textStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),

        // Upload button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isPicking ? null : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.6),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: isPicking
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Choose file',
                    style: AppFonts.textStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Pro tips section
class _ProTipsSection extends StatelessWidget {
  final bool isDark;

  const _ProTipsSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.darkCardBackground
            : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppTheme.borderColor.withValues(alpha: 0.3)
              : AppTheme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: AppTheme.warningColor,
              ),
              SizedBox(width: 8),
              Text(
                'Pro tips',
                style: AppFonts.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          _TipItem(
            text: 'Include date, amount, and category columns',
            isDark: isDark,
          ),
          SizedBox(height: 10),
          _TipItem(
            text: 'First row should contain column headers',
            isDark: isDark,
          ),
          SizedBox(height: 10),
          _TipItem(
            text: 'We auto-detect structure and map categories',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;
  final bool isDark;

  const _TipItem({
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppFonts.textStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
