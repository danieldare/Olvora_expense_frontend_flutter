import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/models/currency.dart';
import '../../domain/models/ora_message.dart';

/// Renders structured content in assistant messages
class OraStructuredContentWidget extends StatelessWidget {
  final OraStructuredContent content;
  final void Function(String)? onPromptTap; // Callback for prompt suggestions

  const OraStructuredContentWidget({
    required this.content,
    this.onPromptTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    switch (content.type) {
      case StructuredContentType.expenseCreated:
        return _ExpenseCreatedCard(expense: content.data);
      case StructuredContentType.expensesPending:
        // Don't render - expense details are already shown in the message text
        return const SizedBox.shrink();
      case StructuredContentType.receiptSummary:
        return _ReceiptSummaryCard(receiptData: content.data);
      case StructuredContentType.spendingSummary:
        return _SpendingSummaryCard(summary: content.data);
      case StructuredContentType.budgetStatus:
        return _BudgetStatusCard(status: content.data);
      case StructuredContentType.tripCreated:
        return _TripCreatedCard(trip: content.data);
      case StructuredContentType.capabilities:
        return _CapabilitiesGrid(capabilities: content.data);
      case StructuredContentType.error:
        return _ErrorCard(error: content.data);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ExpenseCreatedCard extends StatelessWidget {
  final Map<String, dynamic> expense;

  const _ExpenseCreatedCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    final amount = expense['amount'] as num?;
    final currency = expense['currency'] as String? ?? 'USD';
    final merchant = expense['merchant'] as String?;
    final category = expense['category'] as String?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppTheme.successColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (merchant != null)
                  Text(
                    merchant,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                if (amount != null)
                  Text(
                    CurrencyFormatter.format(
                      amount.toDouble(),
                      _getCurrency(currency),
                    ),
                    style: TextStyle(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                if (category != null)
                  Text(
                    category,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Receipt summary card - displays scanned receipt information in receipt style
class _ReceiptSummaryCard extends StatelessWidget {
  final Map<String, dynamic> receiptData;

  const _ReceiptSummaryCard({required this.receiptData});

  @override
  Widget build(BuildContext context) {
    final expenses = receiptData['expenses'] as List<dynamic>? ?? [];
    final receiptInfo =
        receiptData['receiptData'] as Map<String, dynamic>? ?? {};

    if (expenses.isEmpty) {
      return const SizedBox.shrink();
    }

    final firstExpense = expenses[0] as Map<String, dynamic>;
    final merchant =
        receiptInfo['merchant'] as String? ??
        firstExpense['merchant'] as String?;
    final totalAmount =
        receiptInfo['totalAmount'] as num? ?? firstExpense['amount'] as num?;
    final currency =
        receiptInfo['currency'] as String? ??
        firstExpense['currency'] as String? ??
        'USD';
    final date = receiptInfo['date'] as String?;
    final category =
        receiptInfo['category'] as String? ??
        firstExpense['category'] as String?;
    final lineItems = receiptInfo['lineItems'] as List<dynamic>?;
    final receiptNumber = receiptInfo['receiptNumber'] as String?;
    final address = receiptInfo['address'] as String?;

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Receipt header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
            ),
            child: Column(
              children: [
                // Merchant name (centered, bold)
                if (merchant != null)
                  Text(
                    merchant.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                if (address != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    address,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                // Dashed line
                CustomPaint(
                  size: const Size(double.infinity, 1),
                  painter: DashedLinePainter(),
                ),
              ],
            ),
          ),

          // Receipt body
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                // Date
                if (date != null) ...[
                  _buildReceiptLine('Date', _formatReceiptDate(date)),
                  const SizedBox(height: 8),
                ],

                // Receipt number
                if (receiptNumber != null) ...[
                  _buildReceiptLine('Receipt #', receiptNumber),
                  const SizedBox(height: 8),
                ],

                // Category
                if (category != null) ...[
                  _buildReceiptLine('Category', category),
                  const SizedBox(height: 8),
                ],

                // Items count
                if (lineItems != null && lineItems.isNotEmpty) ...[
                  _buildReceiptLine(
                    'Items',
                    '${lineItems.length} ${lineItems.length == 1 ? 'item' : 'items'}',
                  ),
                  const SizedBox(height: 12),
                  // Dashed line before total
                  CustomPaint(
                    size: const Size(double.infinity, 1),
                    painter: DashedLinePainter(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Total amount (highlighted)
                if (totalAmount != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(
                          totalAmount.toDouble(),
                          _getCurrency(currency),
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Receipt footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: AppTheme.successColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Scanned & Verified',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptLine(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatReceiptDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, y • h:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

/// Custom painter for dashed lines (receipt style)
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _SpendingSummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;

  const _SpendingSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final total = summary['total'] as num? ?? 0;
    final count = summary['count'] as int? ?? 0;
    final currency = summary['currency'] as String? ?? 'USD';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending Summary',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(total.toDouble(), _getCurrency(currency)),
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Across $count transaction(s)',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _BudgetStatusCard extends StatelessWidget {
  final Map<String, dynamic> status;

  const _BudgetStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    // Placeholder - implement based on budget data structure
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text('Budget status'),
    );
  }
}

class _TripCreatedCard extends StatelessWidget {
  final Map<String, dynamic> trip;

  const _TripCreatedCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final name = trip['name'] as String?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.flight_takeoff, color: AppTheme.successColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name != null ? 'Trip "$name" created' : 'Trip created',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Prompt suggestions widget - plain text, not clickable
/// Shown when user types off-topic queries (UNKNOWN intent)
class _CapabilitiesGrid extends StatelessWidget {
  final Map<String, dynamic> capabilities;

  const _CapabilitiesGrid({required this.capabilities});

  @override
  Widget build(BuildContext context) {
    final itemsList = capabilities['items'] as List<dynamic>? ?? [];

    if (itemsList.isEmpty) {
      // Fallback to default prompt suggestions
      return _buildDefaultSuggestions();
    }

    // Check if items have 'prompt' field (new format) or 'label' field (old format)
    final hasPrompts =
        itemsList.isNotEmpty &&
        (itemsList.first as Map<String, dynamic>).containsKey('prompt');

    if (hasPrompts) {
      // New format: prompt suggestions
      return _buildPromptSuggestions(itemsList);
    } else {
      // Old format: capabilities (for backward compatibility, but shouldn't be used)
      return const SizedBox.shrink();
    }
  }

  Widget _buildPromptSuggestions(List<dynamic> itemsList) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Try saying:',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...itemsList.map((item) {
            try {
              final suggestion = item as Map<String, dynamic>;
              final prompt = suggestion['prompt'] as String?;

              if (prompt == null || prompt.isEmpty) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _PromptSuggestionChip(prompt: prompt),
              );
            } catch (e) {
              debugPrint('Invalid prompt suggestion: $e');
              return const SizedBox.shrink();
            }
          }),
        ],
      ),
    );
  }

  Widget _buildDefaultSuggestions() {
    final defaultPrompts = [
      'Lunch at Starbucks, \$12.50',
      'How much did I spend on food this week?',
      'I spent 5000 naira on groceries',
      'Show me my expenses from last month',
    ];

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Try saying:',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...defaultPrompts.map(
            (prompt) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _PromptSuggestionChip(prompt: prompt),
            ),
          ),
        ],
      ),
    );
  }
}

/// Prompt suggestion - plain text, not clickable
class _PromptSuggestionChip extends StatelessWidget {
  final String prompt;

  const _PromptSuggestionChip({required this.prompt});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 16,
            color: AppTheme.primaryColor.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              prompt,
              style: TextStyle(
                color: isDark ? Colors.white.withValues(alpha: 0.9) : AppTheme.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final Map<String, dynamic> error;

  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    final message = error['message'] as String? ?? 'An error occurred';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.errorColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}

/// Helper function to get Currency object from currency code string
Currency _getCurrency(String? currencyCode) {
  if (currencyCode == null) {
    return Currency.defaultCurrency;
  }
  return Currency.findByCode(currencyCode.toUpperCase()) ??
      Currency.defaultCurrency;
}
