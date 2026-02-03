enum SpendingTrend {
  accelerating,
  steady,
  decelerating,
}

class SpendingForecastEntity {
  final String budgetId;
  final String budgetName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double currentSpent;
  final double budgetAmount;
  final double projectedSpent;
  final double confidence; // 0-1
  final double exceedProbability; // 0-1
  final double dailyBurnRate;
  final double safeDailySpend;
  final int daysElapsed;
  final int daysRemaining;
  final SpendingTrend trend;
  final double? projectedOverage;
  final double? projectedUnderage;

  SpendingForecastEntity({
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

  double get utilizationPercent =>
      budgetAmount > 0 ? (currentSpent / budgetAmount) * 100 : 0;
  double get projectedUtilizationPercent =>
      budgetAmount > 0 ? (projectedSpent / budgetAmount) * 100 : 0;
  bool get isProjectedToExceed => projectedSpent > budgetAmount;
  bool get hasExceeded => currentSpent >= budgetAmount;
}
