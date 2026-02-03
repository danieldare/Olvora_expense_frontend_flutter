import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/ora_message.dart';
import 'ora_action_buttons.dart';
import 'ora_structured_content.dart';

/// Message bubble widget for Ora chat
class OraMessageBubble extends StatelessWidget {
  final OraMessage message;
  final OraMessage? previousMessage;
  final void Function(OraActionButton)? onActionPressed;
  final bool
  isOnlyMessage; // True if this is the only message (empty conversation)
  final void Function(String)? onPromptTap; // Callback for prompt suggestions

  const OraMessageBubble({
    required this.message,
    this.previousMessage,
    this.onActionPressed,
    this.isOnlyMessage = false,
    this.onPromptTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (message is UserMessage) {
      return _UserBubble(
        message: message as UserMessage,
        previousMessage: previousMessage,
      );
    } else if (message is AssistantMessage) {
      return _AssistantBubble(
        message: message as AssistantMessage,
        previousMessage: previousMessage,
        onActionPressed: onActionPressed,
        isOnlyMessage: isOnlyMessage,
        onPromptTap: onPromptTap,
      );
    } else if (message is SystemMessage) {
      // Only show system messages for errors/info, not typing
      if ((message as SystemMessage).type != OraSystemMessageType.typing) {
        return _SystemBubble(message: message as SystemMessage);
      }
      // Typing is now handled as AssistantMessage
      return const SizedBox.shrink();
    }
    return const SizedBox.shrink();
  }
}

class _UserBubble extends StatelessWidget {
  final UserMessage message;
  final OraMessage? previousMessage;

  const _UserBubble({required this.message, this.previousMessage});

  bool _shouldShowTimestamp() {
    if (previousMessage == null) return true;
    final timeDiff = message.timestamp.difference(previousMessage!.timestamp);
    return timeDiff.inMinutes > 3;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate spacing based on message grouping
    // Group messages from same sender if within 2 minutes
    final isSameSender =
        previousMessage is UserMessage &&
        previousMessage != null &&
        message.timestamp.difference(previousMessage!.timestamp).inMinutes < 2;
    final spacing = isSameSender ? 2.0 : 8.0;

    return Padding(
      padding: EdgeInsets.only(
        left: 40, // Reduced from 48 for better space utilization
        right: 8, // Reduced from 12
        top: spacing,
        bottom: 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_shouldShowTimestamp())
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Center(
                child: Text(
                  DateFormat('EEE, h:mm a').format(message.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * 0.85,
                      ),
                      child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: const Radius.circular(16),
                        bottomRight: Radius.circular(isSameSender ? 16 : 4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Attachments (non-audio only - audio shows as badge below)
                        if (message.attachments != null)
                          ...message.attachments!
                              .where((a) => a.type != AttachmentType.audio)
                              .map(
                                (a) => _AttachmentPreview(
                                  attachment: a,
                                  isUser: true,
                                ),
                              ),
                        // Text
                        Text(
                          message.text,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4, // Better line height for readability
                          ),
                        ),
                        // Voice message indicator (persistent - metadata or audio attachment)
                        if (message.isVoice ||
                            (message.attachments?.any(
                                  (a) => a.type == AttachmentType.audio,
                                ) ??
                                false))
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.mic_rounded,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Voice message',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  final AssistantMessage message;
  final OraMessage? previousMessage;
  final void Function(OraActionButton)? onActionPressed;
  final bool isOnlyMessage;
  final void Function(String)? onPromptTap;

  const _AssistantBubble({
    required this.message,
    required this.previousMessage,
    this.onActionPressed,
    this.isOnlyMessage = false,
    this.onPromptTap,
  });

  bool _shouldShowTimestamp() {
    if (previousMessage == null) return true;
    final timeDiff = message.timestamp.difference(previousMessage!.timestamp);
    return timeDiff.inMinutes > 3;
  }

  bool _shouldShowAvatar() {
    if (previousMessage == null) return true;
    if (previousMessage is! AssistantMessage) return true;
    final timeDiff = message.timestamp.difference(previousMessage!.timestamp);
    return timeDiff.inMinutes > 5;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Light mode: use a distinct grey so left (assistant) messages have clear contrast vs background
    final bubbleColor = isDark
        ? AppTheme.darkCardBackground
        : const Color(0xFFE8EAED); // light grey, distinct from white/off-white screen
    final textColor = isDark
        ? AppTheme.textPrimary
        : const Color(0xFF1F2937); // darker grey for stronger contrast in light mode

    // Calculate spacing based on message grouping
    final isSameSender =
        previousMessage is AssistantMessage &&
        previousMessage != null &&
        message.timestamp.difference(previousMessage!.timestamp).inMinutes < 2;
    final spacing = isSameSender ? 2.0 : 8.0;

    return Padding(
      padding: EdgeInsets.only(
        left: 8,
        right: 40,
        top: spacing,
        bottom: 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_shouldShowTimestamp())
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Center(
                child: Text(
                  DateFormat('EEE, h:mm a').format(message.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fixed-width slot so bubble width stays consistent (avoids wide/compact jump when avatar toggles)
              SizedBox(
                width: 36, // 28 avatar + 8 spacing
                child: _shouldShowAvatar()
                    ? _OraAvatar()
                    : const SizedBox.shrink(),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message container
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(isSameSender ? 16 : 4),
                          topRight: const Radius.circular(16),
                          bottomLeft: const Radius.circular(16),
                          bottomRight: const Radius.circular(16),
                        ),
                        border: isDark
                            ? null
                            : Border.all(
                                color: AppTheme.borderColor.withValues(alpha: 0.5),
                                width: 1,
                              ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text content (show even when empty for streaming)
                          if (message.text.isNotEmpty || message.isStreaming)
                            SelectableText(
                              message.text.isEmpty && message.isStreaming
                                  ? ''
                                  : message.text,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 15,
                                height:
                                    1.4, // Better line height for readability
                              ),
                            ),
                          // Streaming indicator (show when streaming, especially if text is empty)
                          if (message.isStreaming)
                            Padding(
                              padding: EdgeInsets.only(
                                top: message.text.isNotEmpty ? 8 : 0,
                              ),
                              child: const _StreamingIndicator(),
                            ),
                          // Structured content
                          if (message.structuredContent != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: OraStructuredContentWidget(
                                content: message.structuredContent!,
                                onPromptTap: onPromptTap,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Action buttons
                    if (message.actions != null && message.actions!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: OraActionButtons(
                          actions: message.actions!,
                          onPressed: onActionPressed,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SystemBubble extends StatelessWidget {
  final SystemMessage message;

  const _SystemBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.type == OraSystemMessageType.typing) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: _StreamingIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: message.type == OraSystemMessageType.error
                ? AppTheme.errorColor.withOpacity(0.1)
                : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: message.type == OraSystemMessageType.error
                  ? AppTheme.errorColor
                  : AppTheme.textPrimary,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _OraAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Text(
          'O',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _StreamingIndicator extends StatelessWidget {
  const _StreamingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(delay: 0),
        const SizedBox(width: 4),
        _Dot(delay: 200),
        const SizedBox(width: 4),
        _Dot(delay: 400),
      ],
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;

  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppTheme.textSecondary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  final OraAttachment attachment;
  final bool isUser;

  const _AttachmentPreview({required this.attachment, required this.isUser});

  @override
  Widget build(BuildContext context) {
    // Image attachment
    if (attachment.type == AttachmentType.image &&
        attachment.localPath != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(attachment.localPath!),
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Audio attachment - show player if file exists, otherwise just badge
    if (attachment.type == AttachmentType.audio) {
      // If localPath exists and file exists, show audio player
      if (attachment.localPath != null) {
        final file = File(attachment.localPath!);
        // Check synchronously if file exists for immediate UI
        if (file.existsSync()) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _VoiceMessagePlayer(
              audioPath: attachment.localPath!,
              isUser: isUser,
            ),
          );
        }
      }

      // File doesn't exist (deleted after confirm) - show just the badge
      return _VoiceMessageBadge(isUser: isUser);
    }

    return const SizedBox.shrink();
  }
}

/// Audio player for voice messages (before confirmation)
class _VoiceMessagePlayer extends StatefulWidget {
  final String audioPath;
  final bool isUser;

  const _VoiceMessagePlayer({required this.audioPath, required this.isUser});

  @override
  State<_VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<_VoiceMessagePlayer> {
  bool _isPlaying = false;
  // We'll use just_audio for playback

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isUser
            ? Colors.white.withValues(alpha: 0.15)
            : AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: () {
              // TODO: Implement actual playback with just_audio
              setState(() => _isPlaying = !_isPlaying);
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isUser
                    ? Colors.white.withValues(alpha: 0.25)
                    : AppTheme.primaryColor.withValues(alpha: 0.15),
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 18,
                color: widget.isUser ? Colors.white : AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Waveform placeholder
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(12, (index) {
              final height = 8.0 + (index % 3) * 6.0;
              return Container(
                width: 3,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: widget.isUser
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppTheme.primaryColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          // Voice message label
          Icon(
            Icons.mic_rounded,
            size: 14,
            color: widget.isUser
                ? Colors.white.withValues(alpha: 0.7)
                : AppTheme.primaryColor.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }
}

/// Badge shown after audio is deleted (expense confirmed)
class _VoiceMessageBadge extends StatelessWidget {
  final bool isUser;

  const _VoiceMessageBadge({required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.white.withValues(alpha: 0.2)
              : AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic_rounded,
              size: 14,
              color: isUser ? Colors.white : AppTheme.primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              'Voice message',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isUser
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
