import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/ora_message.dart';

/// Action buttons for assistant messages
class OraActionButtons extends StatelessWidget {
  final List<OraActionButton> actions;
  final void Function(OraActionButton)? onPressed;

  const OraActionButtons({
    required this.actions,
    this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions.map((action) => _ActionButton(
        action: action,
        onPressed: onPressed != null ? () => onPressed!(action) : null,
      )).toList(),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final OraActionButton action;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.action,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = action.isPrimary;
    final isDestructive = action.actionType == OraActionType.cancel ||
        action.actionType == OraActionType.undo;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isPrimary
            ? AppTheme.primaryColor
            : (isDestructive
                ? AppTheme.errorColor.withOpacity(0.1)
                : AppTheme.surfaceColor),
        foregroundColor: isPrimary
            ? Colors.white
            : (isDestructive
                ? AppTheme.errorColor
                : AppTheme.primaryColor),
        side: BorderSide(
          color: isPrimary
              ? AppTheme.primaryColor
              : (isDestructive
                  ? AppTheme.errorColor.withOpacity(0.3)
                  : AppTheme.borderColor),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        action.label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
