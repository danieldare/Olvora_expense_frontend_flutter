import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../domain/models/voice_expense_session.dart';

class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isDark;
  final bool showTypingAnimation;
  final ChatMessage? previousMessage; // For grouping

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isDark,
    this.showTypingAnimation = false,
    this.previousMessage,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.message.isUser ? 0.5 : -0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _shouldShowAvatar() {
    if (widget.message.isUser) return false;
    if (widget.previousMessage == null) return true;
    if (widget.previousMessage!.isUser) return true;
    // Show avatar if more than 1 minute passed (more compact)
    final timeDiff = widget.message.timestamp
        .difference(widget.previousMessage!.timestamp);
    return timeDiff.inMinutes > 1;
  }

  bool _shouldShowTimestamp() {
    if (widget.previousMessage == null) return true;
    final timeDiff = widget.message.timestamp
        .difference(widget.previousMessage!.timestamp);
    // Show timestamp if more than 3 minutes passed (more compact)
    return timeDiff.inMinutes > 3;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timestamp - Compact design
        if (_shouldShowTimestamp())
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? Colors.grey[800]!.withOpacity(0.4)
                      : Colors.grey[200]!.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _formatTimestamp(widget.message.timestamp),
                  style: AppFonts.textStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ),
        // Message
        FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Align(
                alignment: widget.message.isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  margin: EdgeInsets.only(
                    bottom: _shouldShowAvatar() ? 2 : 0,
                  ),
                  child: widget.message.isUser
                      ? _buildUserBubble()
                      : _buildAssistantBubble(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.accentColor,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic_rounded,
            size: 14,
            color: Colors.white.withOpacity(0.95),
          ),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.message.content,
              style: AppFonts.textStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.45,
                letterSpacing: 0.05,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantBubble() {
    final bgColor = _getBackgroundColor();
    final icon = _getIcon();
    final showAvatar = _shouldShowAvatar();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar - Compact size
        if (showAvatar)
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.accentColor,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.25),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: Colors.white,
            ),
          )
        else
          SizedBox(width: 36),
        // Message bubble - Compact design
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(
                color: _getBorderColor(),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  icon,
                  SizedBox(height: 10),
                ],
                if (widget.showTypingAnimation)
                  _buildTypingIndicator()
                else
                  _buildFormattedContent(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget? _getIcon() {
    switch (widget.message.type) {
      case MessageType.success:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: AppTheme.successColor,
                size: 16,
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Success',
              style: AppFonts.textStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.successColor,
              ),
            ),
          ],
        );
      case MessageType.error:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: AppTheme.errorColor,
                size: 16,
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Oops',
              style: AppFonts.textStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.errorColor,
              ),
            ),
          ],
        );
      case MessageType.summary:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                color: AppTheme.primaryColor,
                size: 16,
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Summary',
              style: AppFonts.textStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        );
      default:
        return null;
    }
  }

  Color _getBackgroundColor() {
    switch (widget.message.type) {
      case MessageType.success:
        return AppTheme.successColor.withOpacity(0.12);
      case MessageType.error:
        return AppTheme.errorColor.withOpacity(0.12);
      case MessageType.summary:
        return AppTheme.primaryColor.withOpacity(0.08);
      default:
        return widget.isDark ? Colors.grey[850]! : Colors.grey[100]!;
    }
  }

  Color _getBorderColor() {
    switch (widget.message.type) {
      case MessageType.success:
        return AppTheme.successColor.withOpacity(0.3);
      case MessageType.error:
        return AppTheme.errorColor.withOpacity(0.3);
      case MessageType.summary:
        return AppTheme.primaryColor.withOpacity(0.25);
      default:
        return Colors.transparent;
    }
  }

  Widget _buildFormattedContent() {
    final content = widget.message.content;

    // Parse markdown-style bold text
    final parts = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(content)) {
      if (match.start > lastEnd) {
        parts.add(TextSpan(text: content.substring(lastEnd, match.start)));
      }
      parts.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: widget.message.type == MessageType.summary
              ? AppTheme.primaryColor
              : null,
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < content.length) {
      parts.add(TextSpan(text: content.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: AppFonts.textStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: widget.isDark ? Colors.white : AppTheme.textPrimary,
          height: 1.5,
          letterSpacing: 0.05,
        ),
        children: parts.isEmpty ? [TextSpan(text: content)] : parts,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + (index * 200)),
          builder: (context, value, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(
                  0.3 + (0.7 * ((value + (index * 0.2)) % 1.0)),
                ),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (date == today) {
      return DateFormat('h:mm a').format(timestamp);
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${DateFormat('h:mm a').format(timestamp)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }
}
