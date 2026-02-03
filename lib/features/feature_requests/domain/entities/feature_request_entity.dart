enum FeatureRequestStatus { pending, reviewed, inProgress, completed, rejected }

class FeatureRequestEntity {
  final String id;
  final String description;
  final String userId;
  final FeatureRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  FeatureRequestEntity({
    required this.id,
    required this.description,
    required this.userId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  String get statusLabel {
    switch (status) {
      case FeatureRequestStatus.pending:
        return 'Pending';
      case FeatureRequestStatus.reviewed:
        return 'Reviewed';
      case FeatureRequestStatus.inProgress:
        return 'In Progress';
      case FeatureRequestStatus.completed:
        return 'Completed';
      case FeatureRequestStatus.rejected:
        return 'Rejected';
    }
  }
}
