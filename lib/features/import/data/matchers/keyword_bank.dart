/// Keyword mappings for automatic category detection.
/// 
/// Design principles:
/// 1. Global-first: Core keywords work universally
/// 2. Extensible: Regional packs can be added without code changes
/// 3. Learning: User mappings improve matching over time
class KeywordBank {
  /// Core global keywords - universal expense terms
  static const Map<String, List<String>> coreKeywords = {
    // Bills & Utilities
    'bills': [
      // Internet & Communications
      'internet', 'wifi', 'broadband', 'isp', 'fiber', 'cable',
      'mobile', 'cellular', 'phone bill', 'telephone',
      // Streaming & Subscriptions
      'netflix', 'spotify', 'hulu', 'disney', 'hbo', 'prime video',
      'apple music', 'youtube', 'subscription', 'streaming',
      // Utilities
      'electricity', 'electric', 'power', 'energy', 'utility',
      'water', 'gas bill', 'heating', 'cooling',
      'waste', 'garbage', 'sanitation', 'sewage',
      // Insurance (utility-like recurring)
      'insurance premium', 'monthly bill',
    ],

    // Transportation
    'transport': [
      // Fuel
      'petrol', 'gasoline', 'fuel', 'diesel', 'gas station',
      'shell', 'exxon', 'bp', 'chevron', 'charging station', 'ev charge',
      // Ride services
      'uber', 'lyft', 'bolt', 'grab', 'didi', 'taxi', 'cab', 'rideshare',
      // Public transit
      'bus', 'train', 'metro', 'subway', 'transit', 'fare', 'commute',
      'railway', 'tram', 'ferry',
      // Vehicle
      'car', 'vehicle', 'auto', 'mechanic', 'repair', 'maintenance',
      'tire', 'tyre', 'oil change', 'car wash', 'service',
      'parking', 'toll', 'registration',
      // Travel
      'flight', 'airline', 'airfare',
    ],

    // Food & Dining
    'food': [
      // Meals
      'food', 'meal', 'lunch', 'dinner', 'breakfast', 'brunch',
      'snack', 'takeout', 'takeaway', 'delivery',
      // Establishments
      'restaurant', 'cafe', 'coffee', 'bistro', 'diner', 'eatery',
      'fast food', 'pizza', 'burger', 'sushi', 'thai', 'indian', 'chinese',
      'mcdonald', 'starbucks', 'subway', 'kfc', 'domino',
      // Groceries
      'grocery', 'groceries', 'supermarket', 'market', 'produce',
      'walmart', 'costco', 'whole foods', 'trader joe', 'aldi', 'lidl',
      'tesco', 'carrefour', 'woolworths',
    ],

    // Shopping
    'shopping': [
      // General
      'shopping', 'shop', 'store', 'mall', 'retail', 'purchase',
      // Categories
      'clothes', 'clothing', 'apparel', 'fashion', 'shoes', 'accessories',
      'electronics', 'gadget', 'phone', 'laptop', 'computer', 'tablet',
      'appliance', 'furniture', 'home goods', 'household', 'decor',
      // Online
      'amazon', 'ebay', 'etsy', 'alibaba', 'online order', 'e-commerce',
      'target', 'ikea', 'best buy', 'apple store',
    ],

    // Healthcare
    'health': [
      // Medical
      'hospital', 'clinic', 'medical', 'doctor', 'physician', 'health',
      'pharmacy', 'drug', 'medicine', 'medication', 'prescription', 'rx',
      'lab', 'test', 'scan', 'xray', 'x-ray', 'mri', 'diagnosis',
      // Specialists
      'dental', 'dentist', 'optician', 'optometrist', 'eye', 'glasses',
      'therapy', 'therapist', 'counseling', 'mental health',
      // Wellness
      'gym', 'fitness', 'workout', 'yoga', 'wellness',
      'health insurance', 'copay', 'deductible',
    ],

    // Education
    'education': [
      'school', 'education', 'tuition', 'fees', 'college', 'university',
      'course', 'training', 'class', 'lesson', 'tutorial', 'workshop',
      'book', 'textbook', 'supplies', 'stationery',
      'student loan', 'scholarship', 'certification',
      'udemy', 'coursera', 'skillshare', 'masterclass',
    ],

    // Entertainment
    'entertainment': [
      // Events
      'entertainment', 'movie', 'cinema', 'theater', 'theatre', 'concert',
      'show', 'event', 'ticket', 'festival', 'museum', 'attraction',
      // Social
      'party', 'club', 'bar', 'nightlife', 'lounge',
      // Gaming
      'game', 'gaming', 'playstation', 'xbox', 'nintendo', 'steam',
      // Travel/Leisure
      'vacation', 'holiday', 'travel', 'trip', 'tourism', 'hotel',
      'airbnb', 'resort', 'cruise',
      // Sports
      'sports', 'gym membership', 'recreation',
    ],
  };

  /// Map keyword category keys to ExpenseCategory enum names
  static const Map<String, String> categoryMap = {
    'bills': 'bills',
    'transport': 'transport',
    'food': 'food',
    'shopping': 'shopping',
    'health': 'health',
    'education': 'education',
    'entertainment': 'entertainment',
  };

  /// Get all keywords for matching
  static Map<String, List<String>> get allKeywords => coreKeywords;
}
