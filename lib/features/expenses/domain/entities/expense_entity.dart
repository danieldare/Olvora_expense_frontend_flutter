enum ExpenseCategory {
  food,
  transport,
  entertainment,
  shopping,
  bills,
  health,
  education,
  debit,
  other,
}

enum EntryMode { manual, notification, scan, voice, clipboard }

class LineItem {
  final String description;
  final double amount;
  final int? quantity;
  final String? category;

  LineItem({
    required this.description,
    required this.amount,
    this.quantity,
    this.category,
  });

  factory LineItem.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic value) {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return LineItem(
      description: json['description'] as String,
      amount: parseAmount(json['amount']),
      quantity: json['quantity'] as int?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
      if (quantity != null) 'quantity': quantity,
      if (category != null) 'category': category,
    };
  }
}

class ExpenseEntity {
  final String id;
  final String title;
  final String? description;
  final String? merchant;
  final double amount;
  final String? currency; // ISO 4217 currency code (e.g., 'USD', 'NGN', 'EUR')
  final ExpenseCategory category;
  final DateTime date;
  final List<LineItem>? lineItems;
  final EntryMode entryMode;
  final String? attachmentUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpenseEntity({
    required this.id,
    required this.title,
    this.description,
    this.merchant,
    required this.amount,
    this.currency,
    required this.category,
    required this.date,
    this.lineItems,
    this.entryMode = EntryMode.manual,
    this.attachmentUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpenseEntity.fromJson(Map<String, dynamic> json) {
    // Handle amount as either String or num
    double parseAmount(dynamic value) {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    // Parse line items if present
    List<LineItem>? parseLineItems(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value
            .map((item) => LineItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return null;
    }

    return ExpenseEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      merchant: json['merchant'] as String? ?? json['store'] as String?,
      amount: parseAmount(json['amount']),
      currency: json['currency'] as String?,
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      date: DateTime.parse(json['date'] as String),
      lineItems: parseLineItems(json['lineItems']),
      entryMode: json['entryMode'] != null
          ? EntryMode.values.firstWhere(
              (e) => e.name == json['entryMode'],
              orElse: () => EntryMode.manual,
            )
          : EntryMode.manual,
      attachmentUrl: json['attachmentUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'merchant': merchant,
      'amount': amount,
      'category': category.name,
      'date': date.toIso8601String(),
      if (currency != null) 'currency': currency,
      if (lineItems != null)
        'lineItems': lineItems!.map((item) => item.toJson()).toList(),
      'entryMode': entryMode.name,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
