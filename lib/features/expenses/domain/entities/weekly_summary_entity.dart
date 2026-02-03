enum SummaryType {
  goodWeek,
  overspendWeek,
  neutralWeek,
  firstWeek,
  noTransactions,
}

enum SummaryStatus {
  generated,
  sent,
  viewed,
}

class WeeklySummaryEntity {
  final String id;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final SummaryType type;
  final double totalSpent;
  final String? topCategory;
  final double? topCategoryAmount;
  final double? weekOverWeekChange;
  final double? previousWeekTotal;
  final String headline;
  final String? insightText;
  final String? suggestedAction;
  final double? budgetAmount;
  final double? budgetSpent;
  final bool isWithinBudget;
  final double confidenceScore;
  final bool hasIncompleteData;
  final SummaryStatus status;
  final DateTime? sentAt;
  final DateTime? viewedAt;
  final int transactionCount;
  final Map<String, double> categoryBreakdown;
  final DateTime createdAt;

  WeeklySummaryEntity({
    required this.id,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.type,
    required this.totalSpent,
    this.topCategory,
    this.topCategoryAmount,
    this.weekOverWeekChange,
    this.previousWeekTotal,
    required this.headline,
    this.insightText,
    this.suggestedAction,
    this.budgetAmount,
    this.budgetSpent,
    required this.isWithinBudget,
    required this.confidenceScore,
    required this.hasIncompleteData,
    required this.status,
    this.sentAt,
    this.viewedAt,
    required this.transactionCount,
    required this.categoryBreakdown,
    required this.createdAt,
  });

  factory WeeklySummaryEntity.fromJson(Map<String, dynamic> json) {
    SummaryType parseType(String type) {
      switch (type) {
        case 'good_week':
          return SummaryType.goodWeek;
        case 'overspend_week':
          return SummaryType.overspendWeek;
        case 'neutral_week':
          return SummaryType.neutralWeek;
        case 'first_week':
          return SummaryType.firstWeek;
        case 'no_transactions':
          return SummaryType.noTransactions;
        default:
          return SummaryType.neutralWeek;
      }
    }

    SummaryStatus parseStatus(String status) {
      switch (status) {
        case 'generated':
          return SummaryStatus.generated;
        case 'sent':
          return SummaryStatus.sent;
        case 'viewed':
          return SummaryStatus.viewed;
        default:
          return SummaryStatus.generated;
      }
    }

    Map<String, double> parseCategoryBreakdown(dynamic breakdown) {
      if (breakdown == null) return {};
      if (breakdown is Map) {
        return breakdown.map((key, value) => MapEntry(
              key.toString(),
              (value is num) ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0,
            ));
      }
      return {};
    }

    return WeeklySummaryEntity(
      id: json['id'] as String,
      weekStartDate: DateTime.parse(json['weekStartDate'] as String),
      weekEndDate: DateTime.parse(json['weekEndDate'] as String),
      type: parseType(json['type'] as String),
      totalSpent: (json['totalSpent'] as num).toDouble(),
      topCategory: json['topCategory'] as String?,
      topCategoryAmount: json['topCategoryAmount'] != null
          ? (json['topCategoryAmount'] as num).toDouble()
          : null,
      weekOverWeekChange: json['weekOverWeekChange'] != null
          ? (json['weekOverWeekChange'] as num).toDouble()
          : null,
      previousWeekTotal: json['previousWeekTotal'] != null
          ? (json['previousWeekTotal'] as num).toDouble()
          : null,
      headline: json['headline'] as String,
      insightText: json['insightText'] as String?,
      suggestedAction: json['suggestedAction'] as String?,
      budgetAmount: json['budgetAmount'] != null
          ? (json['budgetAmount'] as num).toDouble()
          : null,
      budgetSpent: json['budgetSpent'] != null
          ? (json['budgetSpent'] as num).toDouble()
          : null,
      isWithinBudget: json['isWithinBudget'] as bool,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      hasIncompleteData: json['hasIncompleteData'] as bool,
      status: parseStatus(json['status'] as String),
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt'] as String) : null,
      viewedAt: json['viewedAt'] != null ? DateTime.parse(json['viewedAt'] as String) : null,
      transactionCount: json['transactionCount'] as int,
      categoryBreakdown: parseCategoryBreakdown(json['categoryBreakdown']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weekStartDate': weekStartDate.toIso8601String(),
      'weekEndDate': weekEndDate.toIso8601String(),
      'type': type.toString().split('.').last,
      'totalSpent': totalSpent,
      'topCategory': topCategory,
      'topCategoryAmount': topCategoryAmount,
      'weekOverWeekChange': weekOverWeekChange,
      'previousWeekTotal': previousWeekTotal,
      'headline': headline,
      'insightText': insightText,
      'suggestedAction': suggestedAction,
      'budgetAmount': budgetAmount,
      'budgetSpent': budgetSpent,
      'isWithinBudget': isWithinBudget,
      'confidenceScore': confidenceScore,
      'hasIncompleteData': hasIncompleteData,
      'status': status.toString().split('.').last,
      'sentAt': sentAt?.toIso8601String(),
      'viewedAt': viewedAt?.toIso8601String(),
      'transactionCount': transactionCount,
      'categoryBreakdown': categoryBreakdown,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

