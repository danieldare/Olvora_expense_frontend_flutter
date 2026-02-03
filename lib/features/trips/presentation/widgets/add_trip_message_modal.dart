import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/trip_providers.dart';

/// Add Trip Message Modal
///
/// Allows users to add contextual messages to a trip
class AddTripMessageModal extends ConsumerStatefulWidget {
  final String tripId;
  final VoidCallback? onMessageAdded;

  const AddTripMessageModal({
    super.key,
    required this.tripId,
    this.onMessageAdded,
  });

  @override
  ConsumerState<AddTripMessageModal> createState() =>
      _AddTripMessageModalState();
}

class _AddTripMessageModalState extends ConsumerState<AddTripMessageModal> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final tripService = ref.read(tripServiceProvider);
      await tripService.addMessage(
        tripId: widget.tripId,
        message: message,
      );

      // Refresh trip data
      ref.invalidate(tripProvider(widget.tripId));

      if (mounted) {
        Navigator.pop(context);
        if (widget.onMessageAdded != null) {
          widget.onMessageAdded!();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Message added successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add message: $e'),
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
            controller: _messageController,
            label: 'Message',
            hintText: 'Add a contextual message...',
            maxLines: 4,
            enabled: !_isSubmitting,
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitMessage,
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
                      'Add Message',
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
