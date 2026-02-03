enum AlertType {
  warning,
  critical,
  exceeded,
}

enum AlertStatus {
  active,
  dismissed,
  resolved,
}

class BudgetAlertEntity {
  final String id;
  final String budgetId;
  final String? budgetName;
  final AlertType alertType;
  final String message;
  final double? projectedOverage;
  final double? safeDailySpend;
  final String? suggestedAction;
  final DateTime triggeredAt;
  final DateTime? dismissedAt;
  final AlertStatus status;

  BudgetAlertEntity({
    required this.id,
    required this.budgetId,
    this.budgetName,
    required this.alertType,
    required this.message,
    this.projectedOverage,
    this.safeDailySpend,
    this.suggestedAction,
    required this.triggeredAt,
    this.dismissedAt,
    required this.status,
  });

  bool get isActive => status == AlertStatus.active;
  bool get canDismiss => isActive;
}
