import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:image/image.dart' as img;
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_option_row.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/currency_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/models/currency.dart';
import '../../../../core/responsive/responsive_extensions.dart';
import '../../domain/entities/expense_entity.dart';

class TransactionDetailsScreen extends ConsumerStatefulWidget {
  final ExpenseEntity transaction;
  final bool showShareModal;

  const TransactionDetailsScreen({
    super.key,
    required this.transaction,
    this.showShareModal = false,
  });

  @override
  ConsumerState<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState
    extends ConsumerState<TransactionDetailsScreen> {
  bool _lineItemsExpanded = false;
  bool _isSharing = false;
  final ScreenshotController _screenshotController = ScreenshotController();
  final GlobalKey _shareButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Show share modal if requested
    if (widget.showShareModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showShareOptions();
        }
      });
    }
  }

  String _getCategoryName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.bills:
        return 'Bills';
      case ExpenseCategory.health:
        return 'Health';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.debit:
        return 'Debit';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  String _toSentenceCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  String _getEntryModeLabel(EntryMode entryMode) {
    switch (entryMode) {
      case EntryMode.manual:
        return 'Manual';
      case EntryMode.notification:
        return 'Notification';
      case EntryMode.scan:
        return 'Scan';
      case EntryMode.voice:
        return 'Voice';
      case EntryMode.clipboard:
        return 'Clipboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppTheme.screenBackgroundColor;
    final selectedCurrencyAsync = ref.watch(selectedCurrencyProvider);
    final currency =
        selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;

    final categoryName = _getCategoryName(widget.transaction.category);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(),
        title: Text(
          'Transaction Details',
          style: AppFonts.textStyle(
            fontSize: 20.scaledText(context),
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (_isSharing)
            Padding(
              padding: EdgeInsets.all(16.0.scaled(context)),
              child: SizedBox(
                width: 20.scaled(context),
                height: 20.scaled(context),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              key: _shareButtonKey,
              icon: Icon(
                Icons.share_rounded,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
              onPressed: _isSharing ? null : () => _showShareOptions(),
            ),
        ],
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: Container(
          color: bgColor,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: AppSpacing.sectionMedium,
                    bottom: AppSpacing.sectionMedium,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 360.scaled(context),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Receipt header: OLVORA
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sectionLarge,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'OLVORA',
                                      style: AppFonts.textStyle(
                                        fontSize: 22.scaledText(context),
                                        fontWeight: FontWeight.w900,
                                        color: isDark
                                            ? Colors.white
                                            : AppTheme.textPrimary,
                                        letterSpacing: 2.0,
                                        height: 1.0,
                                      ),
                                    ),
                                    Text(
                                      'expense',
                                      style: AppFonts.textStyle(
                                        fontSize: 16.scaledText(context),
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.warningColor,
                                        letterSpacing: 0.5,
                                        height: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _receiptDivider(isDark),

                            // Store / title (receipt-style first line)
                            if (widget.transaction.merchant != null ||
                                widget.transaction.title.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 12.scaledVertical(context),
                                ),
                                child: Text(
                                  _toSentenceCase(
                                    widget.transaction.merchant ??
                                        widget.transaction.title,
                                  ),
                                  style: AppFonts.textStyle(
                                    fontSize: 17.scaledText(context),
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            if (widget.transaction.merchant != null ||
                                widget.transaction.title.isNotEmpty)
                              _receiptDivider(isDark),

                            // Date
                            _buildReceiptRow(
                              context,
                              'DATE',
                              DateFormat('MMM d, y • h:mm a')
                                  .format(widget.transaction.date),
                              isDark,
                            ),
                            _receiptDivider(isDark),

                            // Line items (if any)
                            if (widget.transaction.lineItems != null &&
                                widget.transaction.lineItems!.isNotEmpty) ...[
                              _buildReceiptLineItemsSection(
                                widget.transaction.lineItems!,
                                currency,
                                isDark,
                              ),
                              _receiptDivider(isDark),
                            ],

                            // Total (emphasized)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 14.scaledVertical(context),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'TOTAL',
                                    style: AppFonts.textStyle(
                                      fontSize: 13.scaledText(context),
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.7)
                                          : AppTheme.textSecondary,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(
                                      widget.transaction.amount,
                                      currency,
                                    ),
                                    style: AppFonts.textStyle(
                                      fontSize: 20.scaledText(context),
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.warningColor,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _receiptDivider(isDark),

                            // Category (with icon)
                            _buildCategoryRow(
                              context,
                              categoryName,
                              widget.transaction.category,
                              isDark,
                            ),

                            // Description (if any)
                            if (widget.transaction.description != null &&
                                widget.transaction
                                    .description!.isNotEmpty) ...[
                              _receiptDivider(isDark),
                              _buildReceiptDescription(
                                context,
                                widget.transaction.description!,
                                isDark,
                              ),
                            ],

                            _receiptDivider(isDark),

                            // Footer: entry mode, id, created, updated
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 8.scaledVertical(context),
                              ).copyWith(bottom: 24.scaledVertical(context)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildReceiptFooterRow(
                                    context,
                                    'Entry',
                                    _getEntryModeLabel(
                                        widget.transaction.entryMode),
                                    isDark,
                                  ),
                                  SizedBox(
                                      height: 6.scaledVertical(context)),
                                  _buildReceiptFooterRow(
                                    context,
                                    'ID',
                                    widget.transaction.id.length > 8
                                        ? widget.transaction.id
                                            .substring(0, 8)
                                            .toUpperCase()
                                        : widget.transaction.id.toUpperCase(),
                                    isDark,
                                  ),
                                  SizedBox(
                                      height: 6.scaledVertical(context)),
                                  _buildReceiptFooterRow(
                                    context,
                                    'Created',
                                    DateFormat('MMM d, y • h:mm a')
                                        .format(widget.transaction.createdAt),
                                    isDark,
                                  ),
                                  if (widget.transaction.updatedAt !=
                                      widget.transaction.createdAt) ...[
                                    SizedBox(
                                        height: 6.scaledVertical(context)),
                                    _buildReceiptFooterRow(
                                      context,
                                      'Updated',
                                      DateFormat('MMM d, y • h:mm a')
                                          .format(
                                              widget.transaction.updatedAt),
                                      isDark,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_car_rounded;
      case ExpenseCategory.entertainment:
        return Icons.movie_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.bills:
        return Icons.receipt_rounded;
      case ExpenseCategory.health:
        return Icons.medical_services_rounded;
      case ExpenseCategory.education:
        return Icons.school_rounded;
      case ExpenseCategory.debit:
        return Icons.account_balance_wallet_rounded;
      case ExpenseCategory.other:
        return Icons.category_rounded;
    }
  }

  Widget _buildCategoryRow(
    BuildContext context,
    String categoryName,
    ExpenseCategory category,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 10.scaledVertical(context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'CATEGORY',
            style: AppFonts.textStyle(
              fontSize: 11.scaledText(context),
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.55)
                  : AppTheme.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getCategoryIcon(category),
                size: 18.scaled(context),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppTheme.textPrimary,
              ),
              SizedBox(width: 8.scaled(context)),
              Text(
                _toSentenceCase(categoryName),
                style: AppFonts.textStyle(
                  fontSize: 14.scaledText(context),
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _receiptDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : AppTheme.borderColor.withValues(alpha: 0.6),
    );
  }

  Widget _buildReceiptRow(
    BuildContext context,
    String label,
    String value,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 10.scaledVertical(context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: AppFonts.textStyle(
              fontSize: 11.scaledText(context),
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.55)
                  : AppTheme.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppFonts.textStyle(
                fontSize: 14.scaledText(context),
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptDescription(
    BuildContext context,
    String description,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 12.scaledVertical(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NOTES',
            style: AppFonts.textStyle(
              fontSize: 10.scaledText(context),
              fontWeight: FontWeight.w700,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : AppTheme.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          SizedBox(height: 6.scaledVertical(context)),
          Text(
            description,
            style: AppFonts.textStyle(
              fontSize: 13.scaledText(context),
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : AppTheme.textPrimary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptFooterRow(
    BuildContext context,
    String label,
    String value,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 4.scaledVertical(context),
        horizontal: 4.scaled(context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: AppFonts.textStyle(
              fontSize: 10.scaledText(context),
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.45)
                  : AppTheme.textSecondary.withValues(alpha: 0.9),
              letterSpacing: 0.5,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppFonts.textStyle(
                fontSize: 11.scaledText(context),
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.textPrimary.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptLineItemsSection(
    List<LineItem> lineItems,
    Currency currency,
    bool isDark,
  ) {
    const maxItemsToShow = 5;
    final shouldShowExpand = lineItems.length > maxItemsToShow;
    final itemsToShow = _lineItemsExpanded || !shouldShowExpand
        ? lineItems
        : lineItems.take(maxItemsToShow).toList();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.scaledVertical(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.scaledVertical(context)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ITEM',
                  style: AppFonts.textStyle(
                    fontSize: 10.scaledText(context),
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppTheme.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(
                  width: 72.scaled(context),
                  child: Text(
                    'AMOUNT',
                    textAlign: TextAlign.right,
                    style: AppFonts.textStyle(
                      fontSize: 10.scaledText(context),
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : AppTheme.textSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.scaledVertical(context)),
          ...itemsToShow.asMap().entries.map((entry) {
            final item = entry.value;
            final isLast =
                entry.key == itemsToShow.length - 1 &&
                (!shouldShowExpand || _lineItemsExpanded);
            return Column(
              key: ValueKey('lineitem-${entry.key}'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.scaledVertical(context)),
                  child: _buildReceiptLineItemRow(item, currency, isDark),
                ),
                if (!isLast) _receiptDivider(isDark),
              ],
            );
          }),
          if (itemsToShow.isNotEmpty) ...[
            _receiptDivider(isDark),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.scaledVertical(context)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SUBTOTAL',
                    style: AppFonts.textStyle(
                      fontSize: 11.scaledText(context),
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(
                      lineItems.fold<double>(
                        0.0,
                        (sum, item) =>
                            sum + (item.amount * (item.quantity ?? 1)),
                      ),
                      currency,
                    ),
                    style: AppFonts.textStyle(
                      fontSize: 14.scaledText(context),
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (shouldShowExpand)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _lineItemsExpanded = !_lineItemsExpanded;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 12.scaledVertical(context),
                  ),
                  child: Center(
                    child: Text(
                      _lineItemsExpanded ? 'Show less' : 'Show all',
                      style: AppFonts.textStyle(
                        fontSize: 12.scaledText(context),
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReceiptLineItemRow(
    LineItem item,
    Currency currency,
    bool isDark,
  ) {
    final totalAmount = item.amount * (item.quantity ?? 1);
    final unitPrice = item.amount;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.scaledVertical(context)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _toSentenceCase(item.description),
                  style: AppFonts.textStyle(
                    fontSize: 14.scaledText(context),
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                if (item.quantity != null && item.quantity! > 1)
                  Padding(
                    padding: EdgeInsets.only(top: 2.scaledVertical(context)),
                    child: Text(
                      '${item.quantity}x ${CurrencyFormatter.format(unitPrice, currency)}',
                      style: AppFonts.textStyle(
                        fontSize: 12.scaledText(context),
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 72.scaled(context),
            child: Text(
              CurrencyFormatter.format(totalAmount, currency),
              textAlign: TextAlign.right,
              style: AppFonts.textStyle(
                fontSize: 14.scaledText(context),
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showShareOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final viewPadding = MediaQuery.of(context).viewPadding;
    final safeMaxHeight = (screenHeight - viewPadding.top) * 0.45;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          constraints: BoxConstraints(maxHeight: safeMaxHeight),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardBackground : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: AppTheme.textPrimary.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, -2),
                      spreadRadius: 0,
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppTheme.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Share Transaction',
                            style: AppFonts.textStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Choose format',
                            style: AppFonts.textStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: isDark
                            ? Colors.white
                            : AppTheme.textPrimary,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppOptionRow(
                          icon: Icons.image_rounded,
                          title: 'Share as Image',
                          subtitle: 'PNG format',
                          color: AppTheme.primaryColor,
                          onTap: () {
                            Navigator.pop(context);
                            _shareAsImage();
                          },
                          dense: true,
                        ),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppTheme.borderColor.withValues(alpha: 0.3),
                        ),
                        AppOptionRow(
                          icon: Icons.picture_as_pdf_rounded,
                          title: 'Share as PDF',
                          subtitle: 'Professional format',
                          color: AppTheme.errorColor,
                          onTap: () {
                            Navigator.pop(context);
                            _shareAsPdf();
                          },
                          dense: true,
                        ),
                        SizedBox(
                          height: 24 + MediaQuery.of(context).viewPadding.bottom,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareAsPdf() async {
    if (_isSharing || !mounted) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final selectedCurrencyAsync = ref.read(selectedCurrencyProvider);
      final currency =
          selectedCurrencyAsync.valueOrNull ?? Currency.defaultCurrency;

      // Generate PDF
      final pdf = await _generatePdf(currency);

      if (!mounted) return;

      // Save PDF to temporary file
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final transactionId = widget.transaction.id.length > 8
          ? widget.transaction.id.substring(0, 8).toUpperCase()
          : widget.transaction.id.toUpperCase();
      final pdfPath =
          '${directory.path}/transaction_${transactionId}_$timestamp.pdf';
      final pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(await pdf.save());

      if (!mounted) return;

      // Get share position for iOS
      Rect? sharePositionOrigin;
      if (Platform.isIOS && mounted) {
        await Future.delayed(const Duration(milliseconds: 50));
        if (mounted) {
          final BuildContext? buttonContext = _shareButtonKey.currentContext;
          if (buttonContext != null) {
            final RenderBox? renderBox =
                buttonContext.findRenderObject() as RenderBox?;
            if (renderBox != null && renderBox.hasSize) {
              final position = renderBox.localToGlobal(Offset.zero);
              final size = renderBox.size;
              if (position.dx >= 0 &&
                  position.dy >= 0 &&
                  size.width > 0 &&
                  size.height > 0) {
                final screenSize = MediaQuery.of(context).size;
                if (position.dx < screenSize.width &&
                    position.dy < screenSize.height) {
                  sharePositionOrigin = Rect.fromLTWH(
                    position.dx,
                    position.dy,
                    size.width,
                    size.height,
                  );
                }
              }
            }
          }
        }
        if (sharePositionOrigin == null && mounted) {
          final screenSize = MediaQuery.of(context).size;
          final statusBarHeight = MediaQuery.of(context).padding.top;
          final buttonSize = 48.0;
          final x = (screenSize.width - buttonSize - 8).clamp(
            8.0,
            screenSize.width - 8,
          );
          final y = (statusBarHeight + 8).clamp(
            8.0,
            screenSize.height - buttonSize - 8,
          );
          sharePositionOrigin = Rect.fromLTWH(x, y, buttonSize, buttonSize);
        }
      }

      // Share the PDF
      final result = await Share.shareXFiles(
        [XFile(pdfPath, mimeType: 'application/pdf')],
        text: widget.transaction.title.isNotEmpty
            ? 'Transaction Details - ${widget.transaction.title}'
            : 'Transaction Details',
        subject: 'Transaction Details',
        sharePositionOrigin: sharePositionOrigin,
      );

      if (mounted && result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction details shared successfully'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share PDF: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _shareAsPdf(),
            ),
          ),
        );
      }
      debugPrint('Error sharing PDF: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<pw.Document> _generatePdf(Currency currency) async {
    final pdf = pw.Document();
    final categoryName = _getCategoryName(widget.transaction.category);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header with Olvora branding (stacked like splash screen)
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 20),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColor.fromHex('#8B5CF6'),
                    width: 1.5,
                  ),
                ),
              ),
              child: pw.Center(
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      'OLVORA',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1F2937'),
                        letterSpacing: 2.0,
                      ),
                    ),
                    pw.Text(
                      'expense',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#FFC000'),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 30),

            // Transaction Title
            if (widget.transaction.title.isNotEmpty)
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 20),
                child: pw.Text(
                    _toSentenceCase(widget.transaction.title),
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1F2937'), // Match textPrimary
                  ),
                ),
              ),

            // Total Amount (highlighted)
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F5F3FF'),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(
                  color: PdfColor.fromHex('#8B5CF6'),
                  width: 1,
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Amount',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    CurrencyFormatter.format(
                      widget.transaction.amount,
                      currency,
                    ),
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#FFC000'),
                  ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Transaction Details
            _buildPdfDetailRow('Category', _toSentenceCase(categoryName)),
            _buildPdfDetailRow(
              'Date',
              DateFormat('MMM d, y • h:mm a').format(widget.transaction.date),
            ),
            if (widget.transaction.merchant != null)
              _buildPdfDetailRow(
                'Merchant',
                _toSentenceCase(widget.transaction.merchant!),
              ),
            _buildPdfDetailRow(
              'Entry Mode',
              _getEntryModeLabel(widget.transaction.entryMode),
            ),
            _buildPdfDetailRow(
              'Transaction ID',
              widget.transaction.id.length > 8
                  ? widget.transaction.id.substring(0, 8).toUpperCase()
                  : widget.transaction.id.toUpperCase(),
            ),

            // Description
            if (widget.transaction.description != null &&
                widget.transaction.description!.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F5F3FF'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Description',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#8B5CF6'),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      widget.transaction.description!,
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],

            // Line Items
            if (widget.transaction.lineItems != null &&
                widget.transaction.lineItems!.isNotEmpty) ...[
              pw.SizedBox(height: 30),
              pw.Text(
                'Line Items',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  // Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F5F3FF'),
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Item',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Quantity',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Amount',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Items
                  ...widget.transaction.lineItems!.map((item) {
                    final total = item.amount * (item.quantity ?? 1);
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            _toSentenceCase(item.description),
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${item.quantity ?? 1}',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            CurrencyFormatter.format(total, currency),
                            textAlign: pw.TextAlign.right,
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],

            // Footer
            pw.Spacer(),
            pw.Divider(color: PdfColor.fromHex('#E5E7EB')),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated by Olvora',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColor.fromHex('#6B7280'),
                  ),
                ),
                pw.Text(
                  DateFormat('MMM d, y • h:mm a').format(DateTime.now()),
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColor.fromHex('#6B7280'),
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPdfDetailRow(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1F2937'), // Match textPrimary
            ),
          ),
        ],
      ),
    );
  }

  /// Optimize image for sharing: resize if needed and compress as JPEG
  /// Returns optimized image bytes or null if optimization fails
  Future<Uint8List?> _optimizeImage(Uint8List rawBytes) async {
    try {
      // Decode the image
      final decodedImage = img.decodeImage(rawBytes);
      if (decodedImage == null) {
        debugPrint('❌ Failed to decode image');
        return null;
      }

      // Target dimensions for optimal file size (maintains quality while reducing size)
      const maxWidth = 1920;
      const maxHeight = 2560;

      // Resize if image is larger than target dimensions
      img.Image? processedImage = decodedImage;
      if (decodedImage.width > maxWidth || decodedImage.height > maxHeight) {
        // Calculate new dimensions maintaining aspect ratio
        final aspectRatio = decodedImage.width / decodedImage.height;
        int newWidth = decodedImage.width;
        int newHeight = decodedImage.height;

        if (newWidth > maxWidth) {
          newWidth = maxWidth;
          newHeight = (maxWidth / aspectRatio).round();
        }
        if (newHeight > maxHeight) {
          newHeight = maxHeight;
          newWidth = (maxHeight * aspectRatio).round();
        }

        // Resize with high-quality algorithm
        processedImage = img.copyResize(
          decodedImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.cubic,
        );

        if (kDebugMode) {
          debugPrint(
            '📐 Image resized: ${decodedImage.width}x${decodedImage.height} → ${newWidth}x$newHeight',
          );
        }
      }

      // Encode as JPEG with quality compression
      // Start with 85% quality (good balance of quality and file size)
      int quality = 85;
      Uint8List optimizedBytes = Uint8List.fromList(
        img.encodeJpg(processedImage, quality: quality),
      );

      // If file is still too large (>2MB), reduce quality further
      const maxFileSizeBytes = 2 * 1024 * 1024; // 2MB
      if (optimizedBytes.length > maxFileSizeBytes) {
        quality = 75; // Reduce quality for very large images
        optimizedBytes = Uint8List.fromList(
          img.encodeJpg(processedImage, quality: quality),
        );

        if (kDebugMode) {
          debugPrint('⚠️ Image still large, reduced quality to $quality%');
        }
      }

      if (kDebugMode) {
        final originalSize = (rawBytes.length / 1024).toStringAsFixed(1);
        final optimizedSize = (optimizedBytes.length / 1024).toStringAsFixed(1);
        final sizeInMB = (optimizedBytes.length / (1024 * 1024))
            .toStringAsFixed(2);
        final reduction = ((1 - optimizedBytes.length / rawBytes.length) * 100)
            .toStringAsFixed(1);
        debugPrint(
          '✅ Image optimized: ${originalSize}KB → ${optimizedSize}KB ($sizeInMB MB, $reduction% reduction, quality: $quality%)',
        );
      }

      return optimizedBytes;
    } catch (e, stackTrace) {
      debugPrint('❌ Error optimizing image: $e');
      debugPrint('Stack trace: $stackTrace');
      // Return original bytes if optimization fails
      return rawBytes;
    }
  }

  Future<void> _shareAsImage() async {
    if (_isSharing || !mounted) return;

    // Get the share button position for iOS BEFORE changing state
    // (button gets replaced with loading indicator, so key won't be available)
    Rect? sharePositionOrigin;
    if (Platform.isIOS && mounted) {
      // Small delay to ensure button is rendered
      await Future.delayed(const Duration(milliseconds: 50));

      if (mounted) {
        final BuildContext? buttonContext = _shareButtonKey.currentContext;
        if (buttonContext != null) {
          final RenderBox? renderBox =
              buttonContext.findRenderObject() as RenderBox?;
          if (renderBox != null && renderBox.hasSize) {
            final position = renderBox.localToGlobal(Offset.zero);
            final size = renderBox.size;

            // Validate that position and size are valid (non-zero and within screen)
            if (position.dx >= 0 &&
                position.dy >= 0 &&
                size.width > 0 &&
                size.height > 0) {
              final screenSize = MediaQuery.of(context).size;
              // Ensure the rect is within screen bounds
              if (position.dx < screenSize.width &&
                  position.dy < screenSize.height) {
                sharePositionOrigin = Rect.fromLTWH(
                  position.dx,
                  position.dy,
                  size.width,
                  size.height,
                );
              }
            }
          }
        }
      }

      // Fallback: Always use top-right corner of screen if button position unavailable
      if (sharePositionOrigin == null && mounted) {
        final screenSize = MediaQuery.of(context).size;
        final statusBarHeight = MediaQuery.of(context).padding.top;

        // Simple fallback: top-right corner with safe margins
        // Ensure we have a valid, non-zero rect
        final buttonSize = 48.0;
        final x = (screenSize.width - buttonSize - 8).clamp(
          8.0,
          screenSize.width - 8,
        );
        final y = (statusBarHeight + 8).clamp(
          8.0,
          screenSize.height - buttonSize - 8,
        );

        sharePositionOrigin = Rect.fromLTWH(x, y, buttonSize, buttonSize);
      }
    }

    setState(() {
      _isSharing = true;
    });

    try {
      // Small delay to ensure UI is fully rendered
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      // Capture screenshot with optimized settings
      final Uint8List? rawImageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 200),
        pixelRatio: 1.5,
      );

      if (rawImageBytes == null || rawImageBytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to capture screenshot. Please try again.'),
              backgroundColor: AppTheme.errorColor,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      // Optimize image: decode, resize if needed, compress as JPEG
      final optimizedBytes = await _optimizeImage(rawImageBytes);

      if (optimizedBytes == null || optimizedBytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to optimize image. Please try again.'),
              backgroundColor: AppTheme.errorColor,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      // Save optimized image as JPEG (smaller file size)
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final transactionId = widget.transaction.id.length > 8
          ? widget.transaction.id.substring(0, 8).toUpperCase()
          : widget.transaction.id.toUpperCase();
      final imagePath =
          '${directory.path}/transaction_${transactionId}_$timestamp.jpg';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(optimizedBytes);

      // Log file size for monitoring (debug only)
      if (kDebugMode) {
        final fileSize = await imageFile.length();
        final sizeInKB = (fileSize / 1024).toStringAsFixed(1);
        debugPrint('📸 Optimized image size: ${sizeInKB}KB');
      }

      if (!mounted) return;

      // Share the optimized image
      final result = await Share.shareXFiles(
        [XFile(imagePath, mimeType: 'image/jpeg')],
        text: widget.transaction.title.isNotEmpty
            ? 'Transaction Details - ${widget.transaction.title}'
            : 'Transaction Details',
        subject: 'Transaction Details',
        sharePositionOrigin: sharePositionOrigin,
      );

      // Show success message if sharing was successful
      if (mounted && result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction details shared successfully'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to share transaction details: ${e.toString()}',
            ),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _shareAsImage(),
            ),
          ),
        );
      }
      // Log error for debugging
      debugPrint('Error sharing transaction details: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

}

