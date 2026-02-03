import '../../domain/entities/feature_request_entity.dart';

class FeatureRequestModel {
  final String id;
  final String description;
  final String userId;
  final FeatureRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeatureRequestModel({
    required this.id,
    required this.description,
    required this.userId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeatureRequestModel.fromJson(Map<String, dynamic> json) {
    return FeatureRequestModel(
      id: json['id'] as String,
      description: json['description'] as String,
      userId: json['userId'] as String,
      status: _parseStatus(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static FeatureRequestStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return FeatureRequestStatus.pending;
      case 'reviewed':
        return FeatureRequestStatus.reviewed;
      case 'in_progress':
        return FeatureRequestStatus.inProgress;
      case 'completed':
        return FeatureRequestStatus.completed;
      case 'rejected':
        return FeatureRequestStatus.rejected;
      default:
        return FeatureRequestStatus.pending;
    }
  }

  FeatureRequestEntity toEntity() {
    return FeatureRequestEntity(
      id: id,
      description: description,
      userId: userId,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
