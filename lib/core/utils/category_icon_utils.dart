import 'package:flutter/material.dart';

/// Utility class for mapping category icon names to Material icons
class CategoryIconUtils {
  /// Get Material icon from category icon name
  static IconData getCategoryIconFromName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'food':
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'transport':
      case 'car':
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'entertainment':
      case 'movie':
        return Icons.movie_rounded;
      case 'shopping':
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'bills':
      case 'receipt':
        return Icons.receipt_rounded;
      case 'health':
      case 'medical':
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'local_hospital':
        return Icons.local_hospital_rounded;
      case 'education':
      case 'school':
        return Icons.school_rounded;
      case 'bolt':
      case 'electricity':
        return Icons.bolt_rounded;
      case 'home':
      case 'rent':
        return Icons.home_rounded;
      case 'wifi':
      case 'internet':
        return Icons.wifi_rounded;
      case 'security':
      case 'insurance':
        return Icons.security_rounded;
      case 'spa':
      case 'personal_care':
        return Icons.spa_rounded;
      case 'card_giftcard':
      case 'gifts':
        return Icons.card_giftcard_rounded;
      case 'flight':
      case 'travel':
        return Icons.flight_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
