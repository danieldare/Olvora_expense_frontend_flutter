enum HealthGrade {
  a,
  b,
  c,
  d,
  f,
}

enum HealthTrend {
  improving,
  stable,
  worsening,
}

class BudgetHealthScoreEntity {
  final String budgetId;
  final String budgetName;
  final double score; // 0-100
  final HealthGrade grade;
  final double utilizationRate; // Percentage
  final double consistency; // 0-1
  final HealthTrend trend;
  final double forecastAccuracy; // 0-1
  final HealthFactors factors;
  final List<String> insights;
  final List<String> recommendations;

  BudgetHealthScoreEntity({
    required this.budgetId,
    required this.budgetName,
    required this.score,
    required this.grade,
    required this.utilizationRate,
    required this.consistency,
    required this.trend,
    required this.forecastAccuracy,
    required this.factors,
    required this.insights,
    required this.recommendations,
  });

  bool get isGood => grade == HealthGrade.a || grade == HealthGrade.b;
  bool get needsAttention => grade == HealthGrade.d || grade == HealthGrade.f;
}

class HealthFactors {
  final double utilization; // 0-1
  final double consistency; // 0-1
  final double trend; // 0-1
  final double forecastAccuracy; // 0-1

  HealthFactors({
    required this.utilization,
    required this.consistency,
    required this.trend,
    required this.forecastAccuracy,
  });
}

class OverallHealthScoreEntity {
  final double score; // 0-100
  final HealthGrade grade;
  final double budgetCoverage; // Percentage
  final double averageBudgetScore;
  final double spendingDiscipline; // 0-1
  final double forecastReliability; // 0-1
  final OverallHealthFactors factors;
  final List<String> insights;
  final List<String> recommendations;
  final List<BudgetHealthScoreEntity> budgetScores;

  OverallHealthScoreEntity({
    required this.score,
    required this.grade,
    required this.budgetCoverage,
    required this.averageBudgetScore,
    required this.spendingDiscipline,
    required this.forecastReliability,
    required this.factors,
    required this.insights,
    required this.recommendations,
    required this.budgetScores,
  });

  bool get isGood => grade == HealthGrade.a || grade == HealthGrade.b;
}

class OverallHealthFactors {
  final double budgetCoverage; // 0-1
  final double budgetPerformance; // 0-1
  final double spendingDiscipline; // 0-1
  final double forecastReliability; // 0-1

  OverallHealthFactors({
    required this.budgetCoverage,
    required this.budgetPerformance,
    required this.spendingDiscipline,
    required this.forecastReliability,
  });
}
