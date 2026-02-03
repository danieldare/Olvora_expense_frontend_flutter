enum WeekStartDay {
  sunday('SUNDAY'),
  monday('MONDAY');

  final String value;
  const WeekStartDay(this.value);

  static WeekStartDay fromString(String value) {
    return WeekStartDay.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WeekStartDay.sunday,
    );
  }

  int toNumber() {
    return this == WeekStartDay.sunday ? 0 : 1;
  }

  static WeekStartDay fromNumber(int num) {
    return num == 0 ? WeekStartDay.sunday : WeekStartDay.monday;
  }
}

class UserPreferencesEntity {
  final WeekStartDay weekStartDay;
  final String timezone;
  final String locale;
  final String currency;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserPreferencesEntity({
    required this.weekStartDay,
    required this.timezone,
    required this.locale,
    required this.currency,
    required this.onboardingCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPreferencesEntity.fromJson(Map<String, dynamic> json) {
    return UserPreferencesEntity(
      weekStartDay: WeekStartDay.fromString(json['weekStartDay'] as String),
      timezone: json['timezone'] as String,
      locale: json['locale'] as String,
      currency: json['currency'] as String,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekStartDay': weekStartDay.value,
      'timezone': timezone,
      'locale': locale,
      'currency': currency,
      'onboardingCompleted': onboardingCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserPreferencesEntity copyWith({
    WeekStartDay? weekStartDay,
    String? timezone,
    String? locale,
    String? currency,
    bool? onboardingCompleted,
  }) {
    return UserPreferencesEntity(
      weekStartDay: weekStartDay ?? this.weekStartDay,
      timezone: timezone ?? this.timezone,
      locale: locale ?? this.locale,
      currency: currency ?? this.currency,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
