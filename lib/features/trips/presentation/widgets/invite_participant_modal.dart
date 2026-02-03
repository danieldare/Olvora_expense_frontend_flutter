import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/trip_providers.dart';

/// Invite Participant Modal
///
/// Allows trip owner to invite participants by user ID
class InviteParticipantModal extends ConsumerStatefulWidget {
  final String tripId;
  final VoidCallback? onParticipantInvited;

  const InviteParticipantModal({
    super.key,
    required this.tripId,
    this.onParticipantInvited,
  });

  @override
  ConsumerState<InviteParticipantModal> createState() =>
      _InviteParticipantModalState();
}

class _InviteParticipantModalState
    extends ConsumerState<InviteParticipantModal> {
  final TextEditingController _userIdController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _inviteParticipant() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final tripService = ref.read(tripServiceProvider);
      await tripService.inviteParticipant(
        tripId: widget.tripId,
        userId: userId,
      );

      // Refresh trip data
      ref.invalidate(tripProvider(widget.tripId));

      if (mounted) {
        Navigator.pop(context);
        if (widget.onParticipantInvited != null) {
          widget.onParticipantInvited!();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Participant invited successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to invite participant: $e'),
            backgroundColor: AppTheme.errorColor,
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
    return Container(
      padding: EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _userIdController,
            label: 'User ID',
            hintText: 'Enter user ID to invite',
            enabled: !_isSubmitting,
            keyboardType: TextInputType.text,
          ),
          SizedBox(height: 8),
          Text(
            'Enter the UUID of the user you want to invite',
            style: AppFonts.textStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.6)
                  : AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _inviteParticipant,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Invite Participant',
                      style: AppFonts.textStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
