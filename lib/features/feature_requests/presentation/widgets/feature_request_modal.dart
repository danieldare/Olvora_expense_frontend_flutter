import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/dynamic_theme_colors.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../data/dto/create_feature_request_dto.dart';
import '../providers/feature_request_providers.dart';

class FeatureRequestModal extends ConsumerStatefulWidget {
  const FeatureRequestModal({super.key});

  @override
  ConsumerState<FeatureRequestModal> createState() =>
      _FeatureRequestModalState();
}

class _FeatureRequestModalState extends ConsumerState<FeatureRequestModal> {
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;

  void _onFocusChange() => setState(() {});

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitFeatureRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final dto = CreateFeatureRequestDto(
        description: _descriptionController.text.trim(),
      );

      await ref.read(createFeatureRequestProvider(dto).future);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Feature request submitted successfully!',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.toString().replaceAll('Exception: ', ''),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Align with app color theme: primary for accents, theme borders and text
    final titleColor = AppTheme.textPrimary;
    final subtitleColor = AppTheme.textSecondary;
    final labelColor = AppTheme.textPrimary;
    final helperTextColor = AppTheme.textSecondary;
    final inputBgColor = AppTheme.surfaceColor;
    final inputBorderColor = AppTheme.borderColor;
    final textColor = AppTheme.textPrimary;
    final hintColor = AppTheme.textSecondary;
    final closeIconColor = AppTheme.textSecondary;
    final primary = AppTheme.primaryColor;
    final secondary = AppTheme.secondaryColor;
    final onPrimary = colorScheme.onPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Custom icon header with close button
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.lightbulb_rounded,
                color: onPrimary,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Feature',
                    style: AppFonts.textStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                      letterSpacing: -0.8,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Share your ideas with us',
                    style: AppFonts.textStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: closeIconColor,
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
            // Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Describe your feature request',
                    style: AppFonts.textStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: inputBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _focusNode.hasFocus ? primary : inputBorderColor,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: DynamicThemeColors.isDark ? 0.1 : 0.05,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      focusNode: _focusNode,
                      controller: _descriptionController,
                      maxLines: 8,
                      maxLength: 500,
                      style: AppFonts.textStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'E.g., I would like to see a dark mode toggle in the settings...',
                        hintStyle: AppFonts.textStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: hintColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                        counterStyle: AppFonts.textStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: helperTextColor,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please describe your feature request';
                        }
                        if (value.trim().length < 10) {
                          return 'Description must be at least 10 characters';
                        }
                        if (value.trim().length > 500) {
                          return 'Description must not exceed 500 characters';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Minimum 10 characters, maximum 500 characters',
                    style: AppFonts.textStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: helperTextColor,
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeatureRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: primary,
                  foregroundColor: onPrimary,
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? SizedBox(
                        child: LoadingSpinnerVariants.white(
                          size: 20,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Submit',
                        style: AppFonts.textStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: onPrimary,
                        ),
                      ),
              ),
            ),
        SizedBox(height: 24),
      ],
    );
  }
}
