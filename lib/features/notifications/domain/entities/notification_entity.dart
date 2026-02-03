/// Domain entity for app notifications
class NotificationEntity {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final Map<String, dynamic>? data; // Additional data (e.g., expenseId, tripId)

  NotificationEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.data,
  });

  NotificationEntity copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    // Handle both 'timestamp' and 'createdAt' fields for compatibility
    final timestampValue = json['timestamp'] ?? json['createdAt'];
    if (timestampValue == null) {
      throw Exception('Notification missing timestamp/createdAt field: $json');
    }
    
    return NotificationEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: timestampValue is DateTime 
          ? timestampValue 
          : DateTime.parse(timestampValue as String),
      type: NotificationType.fromString(json['type'] as String),
      isRead: json['isRead'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'isRead': isRead,
      if (data != null) 'data': data,
    };
  }
}

enum NotificationType {
  expenseDetected,
  budgetAlert,
  reminder,
  system,
  tripUpdate,
  weeklySummary;

  static NotificationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'expensedetected':
      case 'expense_detected':
        return NotificationType.expenseDetected;
      case 'budgetalert':
      case 'budget_alert':
        return NotificationType.budgetAlert;
      case 'reminder':
        return NotificationType.reminder;
      case 'system':
        return NotificationType.system;
      case 'tripupdate':
      case 'trip_update':
        return NotificationType.tripUpdate;
      case 'weeklysummary':
      case 'weekly_summary':
        return NotificationType.weeklySummary;
      default:
        return NotificationType.system;
    }
  }
}
