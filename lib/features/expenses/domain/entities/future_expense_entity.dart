enum FutureExpensePriority {
  low,
  medium,
  high,
  critical,
}

enum AmountCertainty {
  exact,
  range,
  estimate,
}

enum DateFlexibility {
  fixed,
  flexible,
}

class FutureExpenseEntity {
  final String id;
  final String title;
  final String? description;
  final String? merchant;
  final double expectedAmount;
  final double? minAmount;
  final double? maxAmount;
  final AmountCertainty amountCertainty;
  final String category;
  final DateTime expectedDate;
  final DateFlexibility dateFlexibility;
  final int? dateWindowDays;
  final FutureExpensePriority priority;
  final String? note;
  final bool isConverted;
  final String? convertedToExpenseId;
  final DateTime createdAt;
  final DateTime updatedAt;

  FutureExpenseEntity({
    required this.id,
    required this.title,
    this.description,
    this.merchant,
    required this.expectedAmount,
    this.minAmount,
    this.maxAmount,
    required this.amountCertainty,
    required this.category,
    required this.expectedDate,
    required this.dateFlexibility,
    this.dateWindowDays,
    this.priority = FutureExpensePriority.medium,
    this.note,
    this.isConverted = false,
    this.convertedToExpenseId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FutureExpenseEntity.fromJson(Map<String, dynamic> json) {
    return FutureExpenseEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      merchant: json['merchant'] as String?,
      expectedAmount: (json['expectedAmount'] is num)
          ? (json['expectedAmount'] as num).toDouble()
          : double.tryParse(json['expectedAmount'] as String) ?? 0.0,
      minAmount: json['minAmount'] != null
          ? ((json['minAmount'] is num)
              ? (json['minAmount'] as num).toDouble()
              : double.tryParse(json['minAmount'] as String))
          : null,
      maxAmount: json['maxAmount'] != null
          ? ((json['maxAmount'] is num)
              ? (json['maxAmount'] as num).toDouble()
              : double.tryParse(json['maxAmount'] as String))
          : null,
      amountCertainty: AmountCertainty.values.firstWhere(
        (e) => e.name == json['amountCertainty'],
        orElse: () => AmountCertainty.estimate,
      ),
      category: json['category'] as String,
      expectedDate: DateTime.parse(json['expectedDate'] as String),
      dateFlexibility: DateFlexibility.values.firstWhere(
        (e) => e.name == json['dateFlexibility'],
        orElse: () => DateFlexibility.flexible,
      ),
      dateWindowDays: json['dateWindowDays'] as int?,
      priority: FutureExpensePriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => FutureExpensePriority.medium,
      ),
      note: json['note'] as String?,
      isConverted: json['isConverted'] as bool? ?? false,
      convertedToExpenseId: json['convertedToExpenseId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (description != null) 'description': description,
      if (merchant != null) 'merchant': merchant,
      'expectedAmount': expectedAmount,
      if (minAmount != null) 'minAmount': minAmount,
      if (maxAmount != null) 'maxAmount': maxAmount,
      'amountCertainty': amountCertainty.name,
      'category': category,
      'expectedDate': expectedDate.toIso8601String().split('T')[0],
      'dateFlexibility': dateFlexibility.name,
      if (dateWindowDays != null) 'dateWindowDays': dateWindowDays,
      'priority': priority.name,
      if (note != null) 'note': note,
    };
  }
}

