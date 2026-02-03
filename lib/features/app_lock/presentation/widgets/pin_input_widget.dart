import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/responsive/responsive_extensions.dart';

/// Reusable PIN input widget with numeric keypad
///
/// Features:
/// - 4-6 digit PIN support
/// - Visual PIN dots indicator
/// - Animated feedback
/// - Delete and clear functionality
/// - Haptic feedback
class PinInputWidget extends StatefulWidget {
  /// Number of PIN digits (4-6)
  final int pinLength;

  /// Called when all digits are entered
  final ValueChanged<String> onPinComplete;

  /// Called when PIN changes
  final ValueChanged<String>? onPinChanged;

  /// Optional title text
  final String? title;

  /// Optional subtitle text
  final String? subtitle;

  /// Optional error message
  final String? errorMessage;

  /// Whether to show biometric button
  final bool showBiometricButton;

  /// Biometric button callback
  final VoidCallback? onBiometricPressed;

  /// Biometric button icon
  final IconData biometricIcon;

  /// Whether input is disabled
  final bool isDisabled;

  const PinInputWidget({
    super.key,
    this.pinLength = 4,
    required this.onPinComplete,
    this.onPinChanged,
    this.title,
    this.subtitle,
    this.errorMessage,
    this.showBiometricButton = false,
    this.onBiometricPressed,
    this.biometricIcon = Icons.fingerprint_rounded,
    this.isDisabled = false,
  }) : assert(pinLength >= 4 && pinLength <= 6);

  @override
  State<PinInputWidget> createState() => PinInputWidgetState();
}

class PinInputWidgetState extends State<PinInputWidget>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    if (widget.isDisabled || _enteredPin.length >= widget.pinLength) return;

    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin += number;
    });

    widget.onPinChanged?.call(_enteredPin);

    if (_enteredPin.length == widget.pinLength) {
      widget.onPinComplete(_enteredPin);
    }
  }

  void _onDeletePressed() {
    if (widget.isDisabled || _enteredPin.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
    widget.onPinChanged?.call(_enteredPin);
  }

  void _onBiometricPressed() {
    if (widget.isDisabled) return;
    HapticFeedback.mediumImpact();
    widget.onBiometricPressed?.call();
  }

  /// Clear the entered PIN (call externally when PIN is wrong)
  void clear() {
    setState(() {
      _enteredPin = '';
    });
  }

  /// Trigger shake animation for error feedback
  void shake() {
    _shakeController.forward().then((_) => _shakeController.reverse());
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: AppFonts.textStyle(
              fontSize: 24.scaledText(context),
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.scaled(context)),
        ],

        // Subtitle
        if (widget.subtitle != null) ...[
          Text(
            widget.subtitle!,
            style: AppFonts.textStyle(
              fontSize: 14.scaledText(context),
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.scaled(context)),
        ],

        // PIN dots
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: child,
            );
          },
          child: _buildPinDots(context, isDark),
        ),

        // Error message
        if (widget.errorMessage != null) ...[
          SizedBox(height: 16.scaled(context)),
          Text(
            widget.errorMessage!,
            style: AppFonts.textStyle(
              fontSize: 13.scaledText(context),
              fontWeight: FontWeight.w500,
              color: AppTheme.errorColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        SizedBox(height: 40.scaled(context)),

        // Keypad
        _buildKeypad(context, isDark),
      ],
    );
  }

  Widget _buildPinDots(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.pinLength, (index) {
        final isFilled = index < _enteredPin.length;
        final hasError = widget.errorMessage != null;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.symmetric(horizontal: 8.scaled(context)),
          width: 16.scaled(context),
          height: 16.scaled(context),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? (hasError ? AppTheme.errorColor : AppTheme.primaryColor)
                : Colors.transparent,
            border: Border.all(
              color: hasError
                  ? AppTheme.errorColor
                  : (isFilled
                      ? AppTheme.primaryColor
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : AppTheme.borderColor)),
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad(BuildContext context, bool isDark) {
    final buttonSize = 72.scaled(context);
    final spacing = 16.scaled(context);

    return Column(
      children: [
        // Row 1: 1, 2, 3
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadButton(context, '1', buttonSize, isDark),
            SizedBox(width: spacing),
            _buildKeypadButton(context, '2', buttonSize, isDark),
            SizedBox(width: spacing),
            _buildKeypadButton(context, '3', buttonSize, isDark),
          ],
        ),
        SizedBox(height: spacing),

        // Row 2: 4, 5, 6
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadButton(context, '4', buttonSize, isDark),
            SizedBox(width: spacing),
            _buildKeypadButton(context, '5', buttonSize, isDark),
            SizedBox(width: spacing),
            _buildKeypadButton(context, '6', buttonSize, isDark),
          ],
        ),
        SizedBox(height: spacing),

        // Row 3: 7, 8, 9
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKeypadButton(context, '7', buttonSize, isDark),
            SizedBox(width: spacing),
            _buildKeypadButton(context, '8', buttonSize, isDark),
            SizedBox(width: spacing),
            _buildKeypadButton(context, '9', buttonSize, isDark),
          ],
        ),
        SizedBox(height: spacing),

        // Row 4: Biometric/empty, 0, Delete
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Biometric or empty
            if (widget.showBiometricButton)
              _buildIconButton(
                context,
                widget.biometricIcon,
                buttonSize,
                isDark,
                onPressed: _onBiometricPressed,
              )
            else
              SizedBox(width: buttonSize),
            SizedBox(width: spacing),
            _buildKeypadButton(context, '0', buttonSize, isDark),
            SizedBox(width: spacing),
            _buildIconButton(
              context,
              Icons.backspace_outlined,
              buttonSize,
              isDark,
              onPressed: _onDeletePressed,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(
    BuildContext context,
    String number,
    double size,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.isDisabled ? null : () => _onNumberPressed(number),
        borderRadius: BorderRadius.circular(size / 2),
        splashColor: AppTheme.primaryColor.withValues(alpha: 0.2),
        highlightColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.1),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: AppFonts.textStyle(
              fontSize: 28.scaledText(context),
              fontWeight: FontWeight.w600,
              color: widget.isDisabled
                  ? (isDark ? Colors.white38 : Colors.grey)
                  : (isDark ? Colors.white : AppTheme.textPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    IconData icon,
    double size,
    bool isDark, {
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.isDisabled ? null : onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        splashColor: AppTheme.primaryColor.withValues(alpha: 0.2),
        highlightColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 28.scaled(context),
            color: widget.isDisabled
                ? (isDark ? Colors.white38 : Colors.grey)
                : (isDark ? Colors.white : AppTheme.textPrimary),
          ),
        ),
      ),
    );
  }
}
