import '../../domain/entities/spending_forecast_entity.dart';

class SpendingForecastModel {
  final String budgetId;
  final String budgetName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double currentSpent;
  final double budgetAmount;
  final double projectedSpent;
  final double confidence;
  final double exceedProbability;
  final double dailyBurnRate;
  final double safeDailySpend;
  final int daysElapsed;
  final int daysRemaining;
  final SpendingTrend trend;
  final double? projectedOverage;
  final double? projectedUnderage;

  SpendingForecastModel({
    required this.budgetId,
    required this.budgetName,
    required this.periodStart,
    required this.periodEnd,
    required this.currentSpent,
    required this.budgetAmount,
    required this.projectedSpent,
    required this.confidence,
    required this.exceedProbability,
    required this.dailyBurnRate,
    required this.safeDailySpend,
    required this.daysElapsed,
    required this.daysRemaining,
    required this.trend,
    this.projectedOverage,
    this.projectedUnderage,
  });

  factory SpendingForecastModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic dateValue) {
      if (dateValue is String) return DateTime.parse(dateValue);
      if (dateValue is DateTime) return dateValue;
      throw FormatException('Invalid date format: $dateValue');
    }

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.parse(value);
      return 0.0;
    }

    SpendingTrend parseTrend(String? trend) {
      switch (trend?.toLowerCase()) {
        case 'accelerating':
          return SpendingTrend.accelerating;
        case 'decelerating':
          return SpendingTrend.decelerating;
        default:
          return SpendingTrend.steady;
      }
    }

    return SpendingForecastModel(
      budgetId: json['budgetId'] as String,
      budgetName: json['budgetName'] as String,
      periodStart: parseDate(json['periodStart']),
      periodEnd: parseDate(json['periodEnd']),
      currentSpent: parseDouble(json['currentSpent']),
      budgetAmount: parseDouble(json['budgetAmount']),
      projectedSpent: parseDouble(json['projectedSpent']),
      confidence: parseDouble(json['confidence']),
      exceedProbability: parseDouble(json['exceedProbability']),
      dailyBurnRate: parseDouble(json['dailyBurnRate']),
      safeDailySpend: parseDouble(json['safeDailySpend']),
      daysElapsed: json['daysElapsed'] as int,
      daysRemaining: json['daysRemaining'] as int,
      trend: parseTrend(json['trend']?.toString()),
      projectedOverage: json['projectedOverage'] != null
          ? parseDouble(json['projectedOverage'])
          : null,
      projectedUnderage: json['projectedUnderage'] != null
          ? parseDouble(json['projectedUnderage'])
          : null,
    );
  }

  SpendingForecastEntity toEntity() {
    return SpendingForecastEntity(
      budgetId: budgetId,
      budgetName: budgetName,
      periodStart: periodStart,
      periodEnd: periodEnd,
      currentSpent: currentSpent,
      budgetAmount: budgetAmount,
      projectedSpent: projectedSpent,
      confidence: confidence,
      exceedProbability: exceedProbability,
      dailyBurnRate: dailyBurnRate,
      safeDailySpend: safeDailySpend,
      daysElapsed: daysElapsed,
      daysRemaining: daysRemaining,
      trend: trend,
      projectedOverage: projectedOverage,
      projectedUnderage: projectedUnderage,
    );
  }
}
