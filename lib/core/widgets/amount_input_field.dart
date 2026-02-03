import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/currency_providers.dart';
import '../models/currency.dart';
import '../responsive/responsive_extensions.dart';

/// A reusable centered amount input field with currency symbol
///
/// This widget displays a large, centered amount input field with:
/// - Currency symbol prefix (always visible)
/// - Transparent background that blends with screen
/// - Large, bold text (32px)
/// - Centered alignment
/// - Placeholder hidden on focus
class AmountInputField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final double? fontSize;
  final double? maxWidth;
  final Color? textColor;
  final bool enabled;
  final String? label;

  const AmountInputField({
    super.key,
    required this.controller,
    this.placeholder = '0.00',
    this.onChanged,
    this.keyboardType,
    this.fontSize = 28,
    this.maxWidth = 350,
    this.textColor,
    this.enabled = true,
    this.label,
  });

  @override
  ConsumerState<AmountInputField> createState() => _AmountInputFieldState();
}

class _AmountInputFieldState extends ConsumerState<AmountInputField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
    final currency =
        selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;
    // Ensure proper contrast: dark text on light background, light text on dark background
    final defaultTextColor = widget.textColor ?? 
        (isDark 
          ? Colors.white.withValues(alpha: 0.95) // Light text on dark background
          : AppTheme.textPrimary.withValues(alpha: 0.95)); // Dark text on light background

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppFonts.textStyle(
              fontSize: 13.scaledText(context),
              fontWeight: FontWeight.w600,
              color: isDark
                  ? defaultTextColor.withValues(alpha: 0.7)
                  : AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 8.scaled(context)),
        ],
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.screenWidth * 0.9,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 20.scaled(context),
                vertical: 18.scaledVertical(context),
              ),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16.scaled(context)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Currency symbol - always visible, very close to amount
                  Padding(
                    padding: EdgeInsets.only(right: 2.scaled(context)),
                    child: Text(
                      currency.symbol,
                      style: AppFonts.textStyle(
                        fontSize: (widget.fontSize ?? 32).scaledText(context),
                        fontWeight: FontWeight.w700,
                        color: defaultTextColor, // Use same color as amount for consistency
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  // Amount input field - expands as needed but with max constraint
                  Flexible(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      autofocus: false,
                      enabled: widget.enabled,
                      textAlign: TextAlign.left,
                      style: AppFonts.textStyle(
                        fontSize: (widget.fontSize ?? 32).scaledText(context),
                        fontWeight: FontWeight.w700,
                        color: defaultTextColor,
                        letterSpacing: -0.5,
                      ),
                      keyboardType: widget.keyboardType ?? TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                        _AmountInputFormatter(),
                      ],
                      onChanged: widget.onChanged,
                      scrollPadding: EdgeInsets.zero,
                      decoration: InputDecoration(
                        hintText: _isFocused
                            ? null
                            : (widget.placeholder ?? '0.00'),
                        hintStyle: AppFonts.textStyle(
                          fontSize: (widget.fontSize ?? 32).scaledText(context),
                          fontWeight: FontWeight.w400,
                          color: defaultTextColor.withValues(alpha: 0.3),
                          letterSpacing: -0.5,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        filled: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Text input formatter for amount with thousand separators
class _AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Get the cursor position in the original text
    final originalCursorPosition = newValue.selection.baseOffset;
    
    // Remove all non-digit characters except decimal point
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');

    // Allow only one decimal point
    if (digitsOnly.split('.').length > 2) {
      return oldValue;
    }

    // Limit to 2 decimal places
    if (digitsOnly.contains('.')) {
      final parts = digitsOnly.split('.');
      if (parts.length == 2 && parts[1].length > 2) {
        digitsOnly = '${parts[0]}.${parts[1].substring(0, 2)}';
      }
    }

    // Parse the number
    final number = double.tryParse(digitsOnly);
    if (number == null && digitsOnly.isNotEmpty) {
      return oldValue;
    }

    // Format with thousand separators
    String formatted;
    if (digitsOnly.isEmpty) {
      formatted = '';
    } else if (digitsOnly.contains('.')) {
      final parts = digitsOnly.split('.');
      final integerPart = int.tryParse(parts[0]) ?? 0;
      formatted = '${NumberFormat('#,##0').format(integerPart)}.${parts[1]}';
    } else {
      final integerPart = int.tryParse(digitsOnly) ?? 0;
      formatted = NumberFormat('#,##0').format(integerPart);
    }

    // Calculate correct cursor position
    // Count how many digits/decimal points are before the cursor in the original text
    int digitsBeforeCursor = 0;
    for (int i = 0; i < originalCursorPosition && i < newValue.text.length; i++) {
      final char = newValue.text[i];
      if (RegExp(r'[\d.]').hasMatch(char)) {
        digitsBeforeCursor++;
      }
    }

    // Find the position in the formatted text that corresponds to the same number of digits
    int formattedCursorPosition = 0;
    int digitsCounted = 0;
    for (int i = 0; i < formatted.length && digitsCounted < digitsBeforeCursor; i++) {
      final char = formatted[i];
      if (RegExp(r'[\d.]').hasMatch(char)) {
        digitsCounted++;
      }
      formattedCursorPosition = i + 1;
    }

    // If we're at the end, place cursor at the end
    if (digitsCounted < digitsBeforeCursor || formattedCursorPosition > formatted.length) {
      formattedCursorPosition = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formattedCursorPosition.clamp(0, formatted.length),
      ),
    );
  }
}
