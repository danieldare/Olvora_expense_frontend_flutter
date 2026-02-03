import '../../../expenses/domain/entities/expense_entity.dart';

class ParsedReceipt {
  final String? merchant;
  final DateTime? date;
  final double? totalAmount;
  final double? tax;
  final String? currency;
  final String? suggestedCategory;
  final List<LineItem>? lineItems;
  final String? rawText;
  final String? address;
  final String? receiptNumber;
  final String? telephone;
  final String? description; // Description containing narration and remark if present
  final bool isDebitAlert; // Flag to indicate if this is a debit alert (no line items)

  ParsedReceipt({
    this.merchant,
    this.date,
    this.totalAmount,
    this.tax,
    this.currency,
    this.suggestedCategory,
    this.lineItems,
    this.rawText,
    this.address,
    this.receiptNumber,
    this.telephone,
    this.description,
    this.isDebitAlert = false,
  });

  factory ParsedReceipt.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null) return null;
      try {
        // Parse the date string - could be ISO string with time or date-only
        final parsed = DateTime.parse(dateStr);
        
        // If the date string was date-only (no time), use current time
        // Check if the original string was date-only format (YYYY-MM-DD)
        if (dateStr.length <= 10 && !dateStr.contains('T') && !dateStr.contains(' ')) {
          // Date-only string - use current time
          final now = DateTime.now();
          return DateTime(
            parsed.year,
            parsed.month,
            parsed.day,
            now.hour,
            now.minute,
            now.second,
          );
        }
        
        return parsed;
      } catch (e) {
        return null;
      }
    }

    List<LineItem>? parseLineItems(dynamic items) {
      if (items == null) return null;
      if (items is List) {
        return items
            .map((item) => LineItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return null;
    }

    return ParsedReceipt(
      merchant: json['merchant'] as String?,
      date: parseDate(json['date'] as String?),
      totalAmount: json['totalAmount'] != null
          ? (json['totalAmount'] as num).toDouble()
          : null,
      tax: json['tax'] != null ? (json['tax'] as num).toDouble() : null,
      currency: json['currency'] as String?,
      suggestedCategory: json['suggestedCategory'] as String?,
      lineItems: parseLineItems(json['lineItems']),
      rawText: json['rawText'] as String?,
      address: json['address'] as String?,
      receiptNumber: json['receiptNumber'] as String? ?? json['receipt_number'] as String?,
      telephone: json['telephone'] as String? ?? json['phone'] as String?,
      description: json['description'] as String?, // Description containing narration and remark
      isDebitAlert: json['isDebitAlert'] as bool? ?? false, // Flag to indicate if this is a debit alert
    );
  }
}
