enum TripStatus {
  active('ACTIVE'),
  closed('CLOSED'),
  archived('ARCHIVED');

  final String value;
  const TripStatus(this.value);

  static TripStatus fromString(String value) {
    return TripStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TripStatus.active,
    );
  }
}

enum TripVisibility {
  private('PRIVATE'),
  shared('SHARED');

  final String value;
  const TripVisibility(this.value);

  static TripVisibility fromString(String value) {
    return TripVisibility.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TripVisibility.private,
    );
  }
}

enum TripParticipantRole {
  owner('OWNER'),
  participant('PARTICIPANT');

  final String value;
  const TripParticipantRole(this.value);

  static TripParticipantRole fromString(String value) {
    return TripParticipantRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TripParticipantRole.participant,
    );
  }
}

enum TripMessageType {
  user('USER'),
  system('SYSTEM');

  final String value;
  const TripMessageType(this.value);

  static TripMessageType fromString(String value) {
    return TripMessageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TripMessageType.user,
    );
  }
}

class TripEntity {
  final String id;
  final String name;
  final String ownerId;
  final String currency;
  final DateTime startTime;
  final DateTime? endTime;
  final TripStatus status;
  final TripVisibility visibility;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TripParticipantEntity> participants;
  final List<TripMessageEntity> messages;
  final double totalSpent;
  final int expenseCount;

  TripEntity({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.currency,
    required this.startTime,
    this.endTime,
    this.status = TripStatus.active,
    this.visibility = TripVisibility.private,
    required this.createdAt,
    required this.updatedAt,
    this.participants = const [],
    this.messages = const [],
    this.totalSpent = 0.0,
    this.expenseCount = 0,
  });

  factory TripEntity.fromJson(Map<String, dynamic> json) {
    return TripEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['ownerId'] as String,
      currency: json['currency'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      status: TripStatus.fromString(json['status'] as String),
      visibility: TripVisibility.fromString(json['visibility'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) => TripParticipantEntity.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => TripMessageEntity.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      expenseCount: (json['expenseCount'] as int?) ?? 0,
    );
  }
}

class TripParticipantEntity {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final TripParticipantRole role;
  final DateTime joinedAt;

  TripParticipantEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.role = TripParticipantRole.participant,
    required this.joinedAt,
  });

  factory TripParticipantEntity.fromJson(Map<String, dynamic> json) {
    return TripParticipantEntity(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userEmail: json['userEmail'] as String,
      role: TripParticipantRole.fromString(json['role'] as String),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }
}

class TripMessageEntity {
  final String id;
  final String? senderId;
  final String? senderName;
  final String message;
  final TripMessageType type;
  final DateTime createdAt;

  TripMessageEntity({
    required this.id,
    this.senderId,
    this.senderName,
    required this.message,
    this.type = TripMessageType.user,
    required this.createdAt,
  });

  factory TripMessageEntity.fromJson(Map<String, dynamic> json) {
    return TripMessageEntity(
      id: json['id'] as String,
      senderId: json['senderId'] as String?,
      senderName: json['senderName'] as String?,
      message: json['message'] as String,
      type: TripMessageType.fromString(json['type'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class TripSummaryEntity {
  final String id;
  final String tripId;
  final double totalSpent;
  final int numberOfExpenses;
  final int participantCount;
  final DateTime startTime;
  final DateTime endTime;
  final String currency;
  final DateTime createdAt;

  TripSummaryEntity({
    required this.id,
    required this.tripId,
    required this.totalSpent,
    required this.numberOfExpenses,
    required this.participantCount,
    required this.startTime,
    required this.endTime,
    required this.currency,
    required this.createdAt,
  });

  factory TripSummaryEntity.fromJson(Map<String, dynamic> json) {
    return TripSummaryEntity(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      totalSpent: (json['totalSpent'] as num).toDouble(),
      numberOfExpenses: json['numberOfExpenses'] as int,
      participantCount: json['participantCount'] as int,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      currency: json['currency'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

enum SplitType {
  equal('EQUAL'),
  exact('EXACT'),
  percentage('PERCENTAGE');

  final String value;
  const SplitType(this.value);

  static SplitType fromString(String value) {
    return SplitType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SplitType.equal,
    );
  }
}

class ExpenseSplitItemEntity {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final double? percentage;

  ExpenseSplitItemEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    this.percentage,
  });

  factory ExpenseSplitItemEntity.fromJson(Map<String, dynamic> json) {
    return ExpenseSplitItemEntity(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      amount: (json['amount'] as num).toDouble(),
      percentage: json['percentage'] != null
          ? (json['percentage'] as num).toDouble()
          : null,
    );
  }
}

class ExpenseSplitEntity {
  final String id;
  final String expenseId;
  final String tripId;
  final SplitType splitType;
  final double totalAmount;
  final List<ExpenseSplitItemEntity> items;
  final DateTime createdAt;

  ExpenseSplitEntity({
    required this.id,
    required this.expenseId,
    required this.tripId,
    required this.splitType,
    required this.totalAmount,
    required this.items,
    required this.createdAt,
  });

  factory ExpenseSplitEntity.fromJson(Map<String, dynamic> json) {
    return ExpenseSplitEntity(
      id: json['id'] as String,
      expenseId: json['expenseId'] as String,
      tripId: json['tripId'] as String,
      splitType: SplitType.fromString(json['splitType'] as String),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      items: (json['items'] as List<dynamic>)
          .map((item) => ExpenseSplitItemEntity.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
