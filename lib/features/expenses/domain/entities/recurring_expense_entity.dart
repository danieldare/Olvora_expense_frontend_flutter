enum RecurrenceFrequency {
  daily,
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly,
}

enum AmountType {
  fixed,
  variable,
}

class RecurringExpenseEntity {
  final String id;
  final String title;
  final String? description;
  final String? merchant;
  final double amount;
  final AmountType amountType;
  final String category;
  final RecurrenceFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final bool autoPost;
  final bool sendReminders;
  final int? reminderDaysBefore;
  final DateTime? lastPostedDate;
  final int totalOccurrences;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecurringExpenseEntity({
    required this.id,
    required this.title,
    this.description,
    this.merchant,
    required this.amount,
    required this.amountType,
    required this.category,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.autoPost = false,
    this.sendReminders = true,
    this.reminderDaysBefore,
    this.lastPostedDate,
    this.totalOccurrences = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecurringExpenseEntity.fromJson(Map<String, dynamic> json) {
    return RecurringExpenseEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      merchant: json['merchant'] as String?,
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount'] as String) ?? 0.0,
      amountType: AmountType.values.firstWhere(
        (e) => e.name == json['amountType'],
        orElse: () => AmountType.fixed,
      ),
      category: json['category'] as String,
      frequency: RecurrenceFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => RecurrenceFrequency.monthly,
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      autoPost: json['autoPost'] as bool? ?? false,
      sendReminders: json['sendReminders'] as bool? ?? true,
      reminderDaysBefore: json['reminderDaysBefore'] as int?,
      lastPostedDate: json['lastPostedDate'] != null
          ? DateTime.parse(json['lastPostedDate'] as String)
          : null,
      totalOccurrences: json['totalOccurrences'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (description != null) 'description': description,
      if (merchant != null) 'merchant': merchant,
      'amount': amount,
      'amountType': amountType.name,
      'category': category,
      'frequency': frequency.name,
      'startDate': startDate.toIso8601String().split('T')[0],
      if (endDate != null)
        'endDate': endDate!.toIso8601String().split('T')[0],
      'autoPost': autoPost,
      'sendReminders': sendReminders,
      if (reminderDaysBefore != null) 'reminderDaysBefore': reminderDaysBefore,
      'isActive': isActive,
    };
  }
}

