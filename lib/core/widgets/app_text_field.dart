import 'package:flutter/material.dart';
import '../theme/app_fonts.dart';
import '../theme/app_theme.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<String>? autofillHints;
  final bool autofocus;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;
  final bool showLabel;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? hintColor;
  final Color? labelColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final double? borderWidth;
  final bool useDarkStyle;
  final BorderRadius? borderRadius;
  final String? helperText;
  final String? errorText;
  final bool showCounter;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.autofocus = false,
    this.suffixIcon,
    this.prefixIcon,
    this.onChanged,
    this.onTap,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.textInputAction,
    this.onFieldSubmitted,
    this.focusNode,
    this.contentPadding,
    this.showLabel = true,
    this.backgroundColor,
    this.textColor,
    this.hintColor,
    this.labelColor,
    this.borderColor,
    this.focusedBorderColor,
    this.borderWidth,
    this.useDarkStyle = false,
    this.borderRadius,
    this.helperText,
    this.errorText,
    this.showCounter = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  String? _errorText;
  final GlobalKey<FormFieldState<String>> _fieldKey =
      GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    if (widget.autofocus) {
      _isFocused = true;
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    // Validation now happens only when the form is submitted (button clicked)
  }

  String? _validateAndGetError(String? value) {
    final error = widget.validator?.call(value);
    setState(() {
      _errorText = error ?? widget.errorText;
    });
    // Return the error for Form validation, but we'll suppress display inside
    return error;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use card background with soft, complementary tones
    // In light mode: light slate-grey for a clean, modern look
    // In dark mode: slightly lighter than card background
    final baseCardColor = isDark
        ? AppTheme.darkCardBackground
        : AppTheme.cardBackground;
    final effectiveBackgroundColor = widget.backgroundColor ??
        (isDark
            ? Color.lerp(baseCardColor, Colors.white, 0.08) ?? baseCardColor
            : const Color(0xFFE2E8F0)); // Soft slate-200 - clean and complementary

    final effectiveTextColor =
        widget.textColor ?? (isDark ? Colors.white : AppTheme.textPrimary);

    final effectiveHintColor =
        widget.hintColor ??
        (isDark ? Colors.white.withValues(alpha: 0.6) : AppTheme.textSecondary);

    final effectiveLabelColor =
        widget.labelColor ?? (isDark ? Colors.white : AppTheme.textPrimary);

    // Focus: same as amount type / selection pills (AppTheme.primaryColor) for consistency
    final effectiveFocusedBorderColor =
        widget.focusedBorderColor ?? AppTheme.primaryColor;

    final effectiveBorderRadius =
        widget.borderRadius ?? BorderRadius.circular(12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: effectiveBackgroundColor,
            borderRadius: effectiveBorderRadius,
            border: _isFocused
                ? Border.all(
                    color: effectiveFocusedBorderColor,
                    width: 1.3,
                  )
                : null,
          ),
          child: TextFormField(
            key: _fieldKey,
            controller: widget.controller,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            autofillHints: widget.autofillHints,
            autofocus: widget.autofocus,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onFieldSubmitted,
            focusNode: _focusNode,
            onChanged: (value) {
              widget.onChanged?.call(value);
              // Clear error when user types
              if (_errorText != null) {
                setState(() {
                  _errorText = null;
                });
              }
            },
            onTap: widget.onTap,
            validator: _validateAndGetError,
            style: AppFonts.textStyle(fontSize: 17, color: effectiveTextColor),
            decoration: InputDecoration(
              labelText: widget.showLabel ? widget.label : null,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              labelStyle: AppFonts.textStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: effectiveLabelColor,
              ),
              floatingLabelStyle: AppFonts.textStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _isFocused ? effectiveFocusedBorderColor : effectiveLabelColor,
              ),
              hintText: widget.hintText,
              hintStyle: AppFonts.textStyle(
                fontSize: 16,
                color: effectiveHintColor.withValues(alpha: 0.3),
              ),
              filled: false,
              suffixIcon: widget.suffixIcon,
              prefixIcon: widget.prefixIcon,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorText: '',
              errorStyle: const TextStyle(height: 0, fontSize: 0),
              isDense: true,
              contentPadding:
                  widget.contentPadding ??
                  const EdgeInsets.fromLTRB(16, 8, 16, 2),
              helperText: widget.helperText,
              helperStyle: AppFonts.textStyle(
                fontSize: 12,
                color: effectiveLabelColor.withValues(alpha: 0.7),
              ),
              counterText: widget.showCounter && widget.maxLength != null
                  ? null
                  : '',
              counterStyle: AppFonts.textStyle(
                fontSize: 12,
                color: effectiveLabelColor.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
        if (_errorText != null || widget.errorText != null) ...[
          SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              _errorText ?? widget.errorText ?? '',
              style: AppFonts.textStyle(
                fontSize: 14,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
