import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/ora_conversation_state.dart';
import 'ora_voice_button.dart';

/// Input bar for Ora chat - WhatsApp-style
class OraInputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isProcessing;
  final OraInputState inputState;
  final VoidCallback onSendText;
  final void Function(File) onSendVoice;
  final VoidCallback onAttachImage;
  final void Function(bool)? onRecordingStateChanged;

  const OraInputBar({
    required this.controller,
    required this.focusNode,
    required this.isProcessing,
    required this.inputState,
    required this.onSendText,
    required this.onSendVoice,
    required this.onAttachImage,
    this.onRecordingStateChanged,
    super.key,
  });

  @override
  State<OraInputBar> createState() => _OraInputBarState();
}

class _OraInputBarState extends State<OraInputBar> {
  bool _hasText = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _startRecording() {
    setState(() => _isRecording = true);
    widget.onRecordingStateChanged?.call(true);
  }

  void _stopRecording() {
    setState(() => _isRecording = false);
    widget.onRecordingStateChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: bottomPadding + 8,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _isRecording ? _buildRecordingMode() : _buildNormalMode(),
      ),
    );
  }

  /// Normal input mode - text field with attachment and voice buttons
  Widget _buildNormalMode() {
    return Row(
      key: const ValueKey('normal_mode'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Attachment button
        _buildAttachmentButton(),
        const SizedBox(width: 8),

        // Text input field
        Expanded(child: _buildTextField()),
        const SizedBox(width: 8),

        // Send or Voice button
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: _hasText
              ? _SendButton(
                  key: const ValueKey('send'),
                  onPressed: widget.isProcessing ? null : widget.onSendText,
                )
              : OraVoiceMicButton(
                  key: const ValueKey('mic'),
                  isProcessing: widget.isProcessing,
                  onTap: _startRecording,
                ),
        ),
      ],
    );
  }

  /// Recording mode - WhatsApp-style recording controls
  Widget _buildRecordingMode() {
    return OraRecordingBar(
      key: const ValueKey('recording_mode'),
      onCancel: _stopRecording,
      onSend: (file) {
        _stopRecording();
        widget.onSendVoice(file);
      },
    );
  }

  Widget _buildAttachmentButton() {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      child: IconButton(
        icon: const Icon(
          Icons.add_photo_alternate_outlined,
          size: 24,
        ),
        onPressed: widget.isProcessing ? null : widget.onAttachImage,
        tooltip: 'Scan receipt',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        enabled: !widget.isProcessing,
        maxLines: null,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: 'Message Ora...',
          hintStyle: AppFonts.textStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppTheme.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: AppFonts.textStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppTheme.textPrimary,
        ),
        onSubmitted: (_) => widget.onSendText(),
      ),
    );
  }
}

/// Send button
class _SendButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _SendButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_upward,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
