import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/models/ora_message.dart';
import 'ora_message_bubble.dart';

/// Scrollable list of Ora messages (optimized for scalability)
class OraMessageList extends StatefulWidget {
  final List<OraMessage> messages;
  final ScrollController scrollController;
  final void Function(OraActionButton)? onActionPressed;
  final VoidCallback? onLoadMore;
  final void Function(String)?
  onSuggestionTap; // Callback when user taps a suggestion

  const OraMessageList({
    required this.messages,
    required this.scrollController,
    this.onActionPressed,
    this.onLoadMore,
    this.onSuggestionTap,
    super.key,
  });

  @override
  State<OraMessageList> createState() => _OraMessageListState();
}

class _OraMessageListState extends State<OraMessageList> {
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.scrollController.hasClients ||
        _isLoadingMore ||
        widget.onLoadMore == null) {
      return;
    }

    final position = widget.scrollController.position;
    // Only load more when the list is actually scrollable (enough content)
    // so we don't show a spinner when there are few messages (e.g. keyboard open / typing)
    final isScrollable = position.maxScrollExtent > position.viewportDimension + 50;
    final isNearTop = position.pixels < 200;
    if (isScrollable && isNearTop) {
      setState(() => _isLoadingMore = true);
      widget.onLoadMore?.call();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _isLoadingMore = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while initializing (prevents flicker)
    // This check would need to be passed from parent, but for now we'll handle empty state
    if (widget.messages.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      controller: widget.scrollController,
      reverse: false, // Top to bottom: oldest at top, newest at bottom
      padding: EdgeInsets.fromLTRB(8, 8, 8, AppSpacing.bottomNavPadding),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      cacheExtent: 600,
      itemCount: widget.messages.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at top when loading more
        if (_isLoadingMore && index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Adjust index if loading indicator is shown
        final messageIndex = _isLoadingMore ? index - 1 : index;
        final message = widget.messages[messageIndex];
        final previousMessage = messageIndex > 0
            ? widget.messages[messageIndex - 1]
            : null;

        // Check if conversation is empty (only has welcome message, no user messages)
        final hasUserMessages = widget.messages.any((m) => m is UserMessage);
        final isOnlyMessage = widget.messages.length == 1 && !hasUserMessages;

        return OraMessageBubble(
          key: ValueKey(message.id), // Key for efficient rebuilds
          message: message,
          previousMessage: previousMessage,
          onActionPressed: widget.onActionPressed,
          isOnlyMessage: isOnlyMessage && messageIndex == 0,
          onPromptTap: widget.onSuggestionTap,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    // Default prompt suggestions (can be made configurable later)
    final suggestions = [
      'Lunch at Starbucks, \$12.50',
      'How much did I spend on food this week?',
      'I spent 5000 naira on groceries',
      'Show me my expenses from last month',
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, 12, 8, AppSpacing.bottomNavPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message at top - styled as a chat bubble
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
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
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi! I\'m Ora',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your expense assistant. What would you like to do today?',
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 14,
                              color: AppTheme.textSecondary.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'You can also scan a receipt using the camera icon below',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textSecondary.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 12,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Try saying:',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...suggestions.map(
              (suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _buildSuggestionChip(suggestion),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    // Non-clickable, display only
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 14,
            color: AppTheme.textSecondary.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
