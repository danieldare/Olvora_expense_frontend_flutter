/// Capability item model
/// Represents a single capability that Ora can perform
class CapabilityItem {
  final String icon;
  final String label;
  final String? description;
  final String? category;
  final int? priority;

  const CapabilityItem({
    required this.icon,
    required this.label,
    this.description,
    this.category,
    this.priority,
  });

  factory CapabilityItem.fromJson(Map<String, dynamic> json) {
    return CapabilityItem(
      icon: json['icon'] as String? ?? 'help_outline',
      label: json['label'] as String? ?? 'Unknown',
      description: json['description'] as String?,
      category: json['category'] as String?,
      priority: json['priority'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'icon': icon,
      'label': label,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (priority != null) 'priority': priority,
    };
  }
}
