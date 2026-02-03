/// DTO for updating an existing budget
class UpdateBudgetDto {
  final double? amount;
  final bool? enabled;

  UpdateBudgetDto({this.amount, this.enabled});

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (amount != null) json['amount'] = amount;
    if (enabled != null) json['enabled'] = enabled;
    return json;
  }
}
