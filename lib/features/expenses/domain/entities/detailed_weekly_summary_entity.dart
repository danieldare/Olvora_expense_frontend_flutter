import 'weekly_summary_entity.dart';

/// Daily breakdown for weekly summary
class DailyBreakdown {
  final DateTime date;
  final String dayName;
  final double totalSpent;
  final int transactionCount;
  final String? topCategory;
  final double? topCategoryAmount;
  final LargestExpense? largestExpense;
  final bool isAboveAverage;
  final bool isBelowAverage;

  DailyBreakdown({
    required this.date,
    required this.dayName,
    required this.totalSpent,
    required this.transactionCount,
    this.topCategory,
    this.topCategoryAmount,
    this.largestExpense,
    required this.isAboveAverage,
    required this.isBelowAverage,
  });

  factory DailyBreakdown.fromJson(Map<String, dynamic> json) {
    return DailyBreakdown(
      date: DateTime.parse(json['date'] as String),
      dayName: json['dayName'] as String,
      totalSpent: (json['totalSpent'] as num).toDouble(),
      transactionCount: json['transactionCount'] as int,
      topCategory: json['topCategory'] as String?,
      topCategoryAmount: json['topCategoryAmount'] != null
          ? (json['topCategoryAmount'] as num).toDouble()
          : null,
      largestExpense: json['largestExpense'] != null
          ? LargestExpense.fromJson(
              json['largestExpense'] as Map<String, dynamic>)
          : null,
      isAboveAverage: json['isAboveAverage'] as bool? ?? false,
      isBelowAverage: json['isBelowAverage'] as bool? ?? false,
    );
  }
}

class LargestExpense {
  final String title;
  final double amount;
  final String category;

  LargestExpense({
    required this.title,
    required this.amount,
    required this.category,
  });

  factory LargestExpense.fromJson(Map<String, dynamic> json) {
    return LargestExpense(
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
    );
  }
}

/// Category insight with change tracking
class CategoryInsight {
  final String category;
  final double amount;
  final double percentage;
  final double? changeVsLastWeek;
  final bool isUnusualIncrease;
  final bool exceededBudget;
  final double? budgetAmount;

  CategoryInsight({
    required this.category,
    required this.amount,
    required this.percentage,
    this.changeVsLastWeek,
    required this.isUnusualIncrease,
    required this.exceededBudget,
    this.budgetAmount,
  });

  factory CategoryInsight.fromJson(Map<String, dynamic> json) {
    return CategoryInsight(
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      changeVsLastWeek: json['changeVsLastWeek'] != null
          ? (json['changeVsLastWeek'] as num).toDouble()
          : null,
      isUnusualIncrease: json['isUnusualIncrease'] as bool? ?? false,
      exceededBudget: json['exceededBudget'] as bool? ?? false,
      budgetAmount: json['budgetAmount'] != null
          ? (json['budgetAmount'] as num).toDouble()
          : null,
    );
  }
}

/// Merchant insight
class MerchantInsight {
  final String merchant;
  final double amount;
  final int transactionCount;
  final double averageAmount;
  final String? category;

  MerchantInsight({
    required this.merchant,
    required this.amount,
    required this.transactionCount,
    required this.averageAmount,
    this.category,
  });

  factory MerchantInsight.fromJson(Map<String, dynamic> json) {
    return MerchantInsight(
      merchant: json['merchant'] as String,
      amount: (json['amount'] as num).toDouble(),
      transactionCount: json['transactionCount'] as int,
      averageAmount: (json['averageAmount'] as num).toDouble(),
      category: json['category'] as String?,
    );
  }
}

/// Habit pattern detection
class HabitPattern {
  final String pattern;
  final String? merchant;
  final String? category;
  final int frequency;
  final double totalAmount;
  final double? changeVsLastWeek;

  HabitPattern({
    required this.pattern,
    this.merchant,
    this.category,
    required this.frequency,
    required this.totalAmount,
    this.changeVsLastWeek,
  });

  factory HabitPattern.fromJson(Map<String, dynamic> json) {
    return HabitPattern(
      pattern: json['pattern'] as String,
      merchant: json['merchant'] as String?,
      category: json['category'] as String?,
      frequency: json['frequency'] as int,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      changeVsLastWeek: json['changeVsLastWeek'] != null
          ? (json['changeVsLastWeek'] as num).toDouble()
          : null,
    );
  }
}

/// Smart insight with confidence scoring
class SmartInsight {
  final String type;
  final String text;
  final double confidence;
  final String priority;

  SmartInsight({
    required this.type,
    required this.text,
    required this.confidence,
    required this.priority,
  });

  factory SmartInsight.fromJson(Map<String, dynamic> json) {
    return SmartInsight(
      type: json['type'] as String,
      text: json['text'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      priority: json['priority'] as String,
    );
  }
}

/// Actionable recommendation
class ActionableRecommendation {
  final String type;
  final String title;
  final String description;
  final String actionLabel;
  final String? category;
  final double? threshold;

  ActionableRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.actionLabel,
    this.category,
    this.threshold,
  });

  factory ActionableRecommendation.fromJson(Map<String, dynamic> json) {
    return ActionableRecommendation(
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      actionLabel: json['actionLabel'] as String,
      category: json['category'] as String?,
      threshold: json['threshold'] != null
          ? (json['threshold'] as num).toDouble()
          : null,
    );
  }
}

/// Week overview with comparisons
class WeekOverview {
  final double totalSpent;
  final double dailyAverage;
  final HighestSpendingDay? highestSpendingDay;
  final LowestSpendingDay? lowestSpendingDay;
  final ComparisonWithPreviousWeek? comparisonWithPreviousWeek;
  final ComparisonWithBudget? comparisonWithBudget;

  WeekOverview({
    required this.totalSpent,
    required this.dailyAverage,
    this.highestSpendingDay,
    this.lowestSpendingDay,
    this.comparisonWithPreviousWeek,
    this.comparisonWithBudget,
  });

  factory WeekOverview.fromJson(Map<String, dynamic> json) {
    return WeekOverview(
      totalSpent: (json['totalSpent'] as num).toDouble(),
      dailyAverage: (json['dailyAverage'] as num).toDouble(),
      highestSpendingDay: json['highestSpendingDay'] != null
          ? HighestSpendingDay.fromJson(
              json['highestSpendingDay'] as Map<String, dynamic>)
          : null,
      lowestSpendingDay: json['lowestSpendingDay'] != null
          ? LowestSpendingDay.fromJson(
              json['lowestSpendingDay'] as Map<String, dynamic>)
          : null,
      comparisonWithPreviousWeek: json['comparisonWithPreviousWeek'] != null
          ? ComparisonWithPreviousWeek.fromJson(
              json['comparisonWithPreviousWeek'] as Map<String, dynamic>)
          : null,
      comparisonWithBudget: json['comparisonWithBudget'] != null
          ? ComparisonWithBudget.fromJson(
              json['comparisonWithBudget'] as Map<String, dynamic>)
          : null,
    );
  }
}

class HighestSpendingDay {
  final DateTime date;
  final String dayName;
  final double amount;

  HighestSpendingDay({
    required this.date,
    required this.dayName,
    required this.amount,
  });

  factory HighestSpendingDay.fromJson(Map<String, dynamic> json) {
    return HighestSpendingDay(
      date: DateTime.parse(json['date'] as String),
      dayName: json['dayName'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

class LowestSpendingDay {
  final DateTime date;
  final String dayName;
  final double amount;

  LowestSpendingDay({
    required this.date,
    required this.dayName,
    required this.amount,
  });

  factory LowestSpendingDay.fromJson(Map<String, dynamic> json) {
    return LowestSpendingDay(
      date: DateTime.parse(json['date'] as String),
      dayName: json['dayName'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

class ComparisonWithPreviousWeek {
  final double change;
  final double previousTotal;
  final double currentTotal;

  ComparisonWithPreviousWeek({
    required this.change,
    required this.previousTotal,
    required this.currentTotal,
  });

  factory ComparisonWithPreviousWeek.fromJson(Map<String, dynamic> json) {
    return ComparisonWithPreviousWeek(
      change: (json['change'] as num).toDouble(),
      previousTotal: (json['previousTotal'] as num).toDouble(),
      currentTotal: (json['currentTotal'] as num).toDouble(),
    );
  }
}

class ComparisonWithBudget {
  final double budgetAmount;
  final double spent;
  final double remaining;
  final double percentageUsed;
  final bool isWithinBudget;

  ComparisonWithBudget({
    required this.budgetAmount,
    required this.spent,
    required this.remaining,
    required this.percentageUsed,
    required this.isWithinBudget,
  });

  factory ComparisonWithBudget.fromJson(Map<String, dynamic> json) {
    return ComparisonWithBudget(
      budgetAmount: (json['budgetAmount'] as num).toDouble(),
      spent: (json['spent'] as num).toDouble(),
      remaining: (json['remaining'] as num).toDouble(),
      percentageUsed: (json['percentageUsed'] as num).toDouble(),
      isWithinBudget: json['isWithinBudget'] as bool,
    );
  }
}

/// Enhanced Detailed Weekly Summary Entity
///
/// Includes all analytics for a world-class weekly summary experience
class DetailedWeeklySummaryEntity {
  // Basic summary info
  final String id;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final SummaryType type;
  final SummaryStatus status;
  final DateTime createdAt;

  // Week Overview
  final WeekOverview overview;

  // Day-by-day breakdown
  final List<DailyBreakdown> dailyBreakdown;

  // Category Intelligence
  final List<CategoryInsight> categoryInsights;

  // Merchant & Habit Insights
  final List<MerchantInsight> topMerchants;
  final List<HabitPattern> habitPatterns;

  // Smart Insights
  final List<SmartInsight> insights;

  // Actionable Recommendations
  final List<ActionableRecommendation> recommendations;

  // Original summary fields (for backward compatibility)
  final String headline;
  final String? insightText;
  final String? suggestedAction;
  final double confidenceScore;
  final bool hasIncompleteData;
  final int transactionCount;

  DetailedWeeklySummaryEntity({
    required this.id,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.overview,
    required this.dailyBreakdown,
    required this.categoryInsights,
    required this.topMerchants,
    required this.habitPatterns,
    required this.insights,
    required this.recommendations,
    required this.headline,
    this.insightText,
    this.suggestedAction,
    required this.confidenceScore,
    required this.hasIncompleteData,
    required this.transactionCount,
  });

  factory DetailedWeeklySummaryEntity.fromJson(Map<String, dynamic> json) {
    return DetailedWeeklySummaryEntity(
      id: json['id'] as String,
      weekStartDate: DateTime.parse(json['weekStartDate'] as String),
      weekEndDate: DateTime.parse(json['weekEndDate'] as String),
      type: SummaryType.values.firstWhere(
        (e) => e.name == json['type'] as String,
        orElse: () => SummaryType.neutralWeek,
      ),
      status: SummaryStatus.values.firstWhere(
        (e) => e.name == json['status'] as String,
        orElse: () => SummaryStatus.generated,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      overview: WeekOverview.fromJson(
          json['overview'] as Map<String, dynamic>),
      dailyBreakdown: (json['dailyBreakdown'] as List<dynamic>)
          .map((e) => DailyBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(),
      categoryInsights: (json['categoryInsights'] as List<dynamic>)
          .map((e) => CategoryInsight.fromJson(e as Map<String, dynamic>))
          .toList(),
      topMerchants: (json['topMerchants'] as List<dynamic>)
          .map((e) => MerchantInsight.fromJson(e as Map<String, dynamic>))
          .toList(),
      habitPatterns: (json['habitPatterns'] as List<dynamic>)
          .map((e) => HabitPattern.fromJson(e as Map<String, dynamic>))
          .toList(),
      insights: (json['insights'] as List<dynamic>)
          .map((e) => SmartInsight.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendations: (json['recommendations'] as List<dynamic>)
          .map((e) =>
              ActionableRecommendation.fromJson(e as Map<String, dynamic>))
          .toList(),
      headline: json['headline'] as String,
      insightText: json['insightText'] as String?,
      suggestedAction: json['suggestedAction'] as String?,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      hasIncompleteData: json['hasIncompleteData'] as bool? ?? false,
      transactionCount: json['transactionCount'] as int,
    );
  }
}

