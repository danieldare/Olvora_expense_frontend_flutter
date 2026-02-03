import 'package:intl/intl.dart';
import '../../../categories/data/repositories/category_repository.dart';
import '../../../../core/services/expense_parsing/expense_parsing.dart';
import '../../../../core/services/api_service_v2.dart';

/// Enhanced voice parser service with global currency support
///
/// Features:
/// - Uses HybridParser for intelligent parsing (generic + AI)
/// - Supports 30+ global currencies
/// - Parses spoken number words (e.g., "fifty dollars")
/// - Extracts dates from natural language
/// - Category matching with keyword expansion
class VoiceParserService {
  // Parser instances
  HybridExpenseParser? _hybridParser;
  GenericExpenseParser? _genericParser;

  /// Initialize with API service for AI parsing
  void initializeWithApiService(ApiServiceV2 apiService) {
    _hybridParser = HybridExpenseParser.withApiService(
      apiService,
      config: const HybridParserConfig(
        aiParsingThreshold: 0.60, // Lower threshold for voice - more ambiguous
        preferAIForSources: {ParsingSource.voice},
        respectConnectivity: true,
      ),
    );
    _genericParser = _hybridParser!.genericParser;
  }

  /// Initialize with generic parser only (offline mode)
  void initializeOffline() {
    _genericParser = GenericExpenseParser();
    _hybridParser = HybridExpenseParser(genericParser: _genericParser);
  }

  /// Parse voice input text to extract expense details
  ///
  /// Uses HybridParser for amount/currency extraction, then enhances
  /// with category matching and date parsing.
  Future<ParsedVoiceExpense> parseVoiceInputAsync(
    String text,
    List<CategoryModel> categories,
  ) async {
    // Initialize parser if needed
    _genericParser ??= GenericExpenseParser();
    _hybridParser ??= HybridExpenseParser(genericParser: _genericParser);

    final lowerText = text.toLowerCase();

    // Parse using HybridParser for amount, currency, merchant
    final parsedResult = await _hybridParser!.parse(text, ParsingSource.voice);

    // Extract category (voice-specific logic with keywords)
    CategoryModel? category = _extractCategory(lowerText, categories);

    // Extract date (voice-specific with natural language)
    DateTime? date = parsedResult.date ?? _extractDate(lowerText);

    // Use parsed amount or try voice-specific extraction (spoken numbers)
    double? amount = parsedResult.amount ?? _extractSpokenAmount(lowerText);

    return ParsedVoiceExpense(
      amount: amount,
      currency: parsedResult.currency,
      currencySymbol: parsedResult.currencySymbol,
      category: category,
      date: date,
      merchant: parsedResult.merchant,
      description: parsedResult.description ?? _extractDescription(lowerText),
      rawText: text,
      confidence: parsedResult.confidence,
      parsedResult: parsedResult,
    );
  }

  /// Synchronous parsing (uses generic parser only)
  ParsedVoiceExpense parseVoiceInput(
    String text,
    List<CategoryModel> categories,
  ) {
    _genericParser ??= GenericExpenseParser();

    final lowerText = text.toLowerCase();

    // Parse using GenericExpenseParser
    final parsedResult = _genericParser!.parse(text, ParsingSource.voice);

    // Extract category
    CategoryModel? category = _extractCategory(lowerText, categories);

    // Extract date
    DateTime? date = parsedResult.date ?? _extractDate(lowerText);

    // Use parsed amount or try voice-specific extraction
    double? amount = parsedResult.amount ?? _extractSpokenAmount(lowerText);

    return ParsedVoiceExpense(
      amount: amount,
      currency: parsedResult.currency,
      currencySymbol: parsedResult.currencySymbol,
      category: category,
      date: date,
      merchant: parsedResult.merchant,
      description: parsedResult.description ?? _extractDescription(lowerText),
      rawText: text,
      confidence: parsedResult.confidence,
      parsedResult: parsedResult,
    );
  }

  /// Extract amount from spoken number words
  ///
  /// Handles: "fifty dollars", "twenty five pounds", "one hundred euros"
  double? _extractSpokenAmount(String text) {
    // Multi-currency spoken patterns
    final currencyWords = {
      'dollar': 'USD',
      'dollars': 'USD',
      'buck': 'USD',
      'bucks': 'USD',
      'pound': 'GBP',
      'pounds': 'GBP',
      'quid': 'GBP',
      'euro': 'EUR',
      'euros': 'EUR',
      'yen': 'JPY',
      'rupee': 'INR',
      'rupees': 'INR',
      'naira': 'NGN',
      'peso': 'MXN',
      'pesos': 'MXN',
      'franc': 'CHF',
      'francs': 'CHF',
      'yuan': 'CNY',
      'won': 'KRW',
      'rand': 'ZAR',
      'dirham': 'AED',
      'dirhams': 'AED',
      'riyal': 'SAR',
      'riyals': 'SAR',
      'baht': 'THB',
      'ringgit': 'MYR',
      'lira': 'TRY',
    };

    // Number words to values
    final ones = {
      'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4,
      'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9,
      'ten': 10, 'eleven': 11, 'twelve': 12, 'thirteen': 13,
      'fourteen': 14, 'fifteen': 15, 'sixteen': 16, 'seventeen': 17,
      'eighteen': 18, 'nineteen': 19,
    };

    final tens = {
      'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50,
      'sixty': 60, 'seventy': 70, 'eighty': 80, 'ninety': 90,
    };

    // Try to find currency word first to narrow the search
    bool hasCurrencyContext = currencyWords.keys.any((word) => text.contains(word));

    if (!hasCurrencyContext) {
      // Also check for generic money words
      hasCurrencyContext = text.contains('money') ||
          text.contains('spent') ||
          text.contains('paid') ||
          text.contains('cost');
    }

    if (!hasCurrencyContext) return null;

    // Parse number words
    double total = 0;
    double current = 0;
    bool foundNumber = false;

    final words = text.split(RegExp(r'\s+'));

    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[,.]'), '');

      if (ones.containsKey(cleanWord)) {
        current += ones[cleanWord]!;
        foundNumber = true;
      } else if (tens.containsKey(cleanWord)) {
        current += tens[cleanWord]!;
        foundNumber = true;
      } else if (cleanWord == 'hundred') {
        current = current == 0 ? 100 : current * 100;
        foundNumber = true;
      } else if (cleanWord == 'thousand' || cleanWord == 'k' || cleanWord == 'grand') {
        current = current == 0 ? 1000 : current * 1000;
        total += current;
        current = 0;
        foundNumber = true;
      } else if (cleanWord == 'million') {
        current = current == 0 ? 1000000 : current * 1000000;
        total += current;
        current = 0;
        foundNumber = true;
      } else if (cleanWord == 'and') {
        // "one hundred and fifty" - continue accumulating
        continue;
      } else if (currencyWords.containsKey(cleanWord)) {
        // Hit currency word, finalize current number
        if (foundNumber) {
          total += current;
          return total > 0 ? total : null;
        }
      }
    }

    // If we found numbers but didn't hit a currency word at the end
    if (foundNumber) {
      total += current;
      return total > 0 ? total : null;
    }

    return null;
  }

  /// Extract category from voice text with enhanced keyword matching
  CategoryModel? _extractCategory(String text, List<CategoryModel> categories) {
    // Enhanced category keywords with more variations
    final categoryKeywords = {
      'food': [
        'food', 'restaurant', 'dining', 'lunch', 'dinner', 'breakfast',
        'eat', 'meal', 'coffee', 'cafe', 'pizza', 'burger', 'sushi',
        'takeout', 'delivery', 'uber eats', 'doordash', 'grubhub',
        'mcdonalds', 'starbucks', 'chipotle', 'subway', 'kfc',
      ],
      'transport': [
        'transport', 'transportation', 'taxi', 'uber', 'lyft', 'grab',
        'gas', 'fuel', 'petrol', 'diesel', 'parking', 'car', 'bus',
        'train', 'metro', 'subway', 'flight', 'airline', 'airport',
        'toll', 'rental', 'carpool',
      ],
      'shopping': [
        'shopping', 'store', 'buy', 'purchase', 'mall', 'amazon',
        'walmart', 'target', 'costco', 'online', 'clothes', 'shoes',
        'electronics', 'gadget', 'appliance',
      ],
      'bills': [
        'bill', 'utility', 'utilities', 'electricity', 'electric',
        'water', 'internet', 'wifi', 'phone', 'mobile', 'cable',
        'subscription', 'netflix', 'spotify', 'insurance', 'rent',
      ],
      'health': [
        'health', 'medical', 'doctor', 'hospital', 'pharmacy',
        'medicine', 'prescription', 'dentist', 'gym', 'fitness',
        'clinic', 'therapy', 'healthcare',
      ],
      'entertainment': [
        'entertainment', 'movie', 'cinema', 'theatre', 'game', 'fun',
        'concert', 'show', 'sports', 'ticket', 'museum', 'park',
        'bowling', 'arcade',
      ],
      'education': [
        'education', 'school', 'course', 'book', 'tuition', 'class',
        'training', 'workshop', 'conference', 'seminar', 'udemy',
        'coursera', 'learning',
      ],
      'home': [
        'home', 'rent', 'house', 'apartment', 'furniture', 'decor',
        'repair', 'maintenance', 'cleaning', 'gardening', 'mortgage',
      ],
      'personal': [
        'personal', 'haircut', 'salon', 'spa', 'beauty', 'grooming',
        'cosmetics', 'skincare',
      ],
      'travel': [
        'travel', 'vacation', 'hotel', 'airbnb', 'booking', 'trip',
        'tourism', 'sightseeing', 'holiday',
      ],
      'groceries': [
        'grocery', 'groceries', 'supermarket', 'market', 'produce',
        'vegetables', 'fruits', 'meat',
      ],
    };

    for (var category in categories) {
      final categoryName = category.name.toLowerCase();

      // Direct match
      if (text.contains(categoryName)) {
        return category;
      }

      // Keyword match
      for (var entry in categoryKeywords.entries) {
        if (categoryName.contains(entry.key)) {
          for (var keyword in entry.value) {
            if (text.contains(keyword)) {
              return category;
            }
          }
        }
      }
    }

    return null;
  }

  /// Extract date from natural language
  DateTime? _extractDate(String text) {
    final now = DateTime.now();

    // Today
    if (text.contains('today')) {
      return now;
    }

    // Yesterday
    if (text.contains('yesterday')) {
      return now.subtract(const Duration(days: 1));
    }

    // Day before yesterday
    if (text.contains('day before yesterday')) {
      return now.subtract(const Duration(days: 2));
    }

    // Last night / this morning
    if (text.contains('last night') || text.contains('this morning')) {
      return now;
    }

    // Days ago
    final daysAgoPattern = RegExp(r'(\d+)\s*days?\s*ago');
    final daysAgoMatch = daysAgoPattern.firstMatch(text);
    if (daysAgoMatch != null) {
      final days = int.tryParse(daysAgoMatch.group(1)!);
      if (days != null) {
        return now.subtract(Duration(days: days));
      }
    }

    // Weeks ago
    final weeksAgoPattern = RegExp(r'(\d+)\s*weeks?\s*ago');
    final weeksAgoMatch = weeksAgoPattern.firstMatch(text);
    if (weeksAgoMatch != null) {
      final weeks = int.tryParse(weeksAgoMatch.group(1)!);
      if (weeks != null) {
        return now.subtract(Duration(days: weeks * 7));
      }
    }

    // Last week
    if (text.contains('last week')) {
      return now.subtract(const Duration(days: 7));
    }

    // Day names: "last monday", "on friday"
    final dayNames = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    for (int i = 0; i < dayNames.length; i++) {
      if (text.contains(dayNames[i])) {
        // Find the most recent occurrence of that day
        final targetWeekday = i + 1; // DateTime weekday is 1-7 (Mon-Sun)
        int daysToSubtract = (now.weekday - targetWeekday) % 7;
        if (daysToSubtract == 0 && !text.contains('today')) {
          daysToSubtract = 7; // If today is that day, assume last week
        }
        return now.subtract(Duration(days: daysToSubtract));
      }
    }

    // Try to parse date formats
    try {
      final dateFormats = [
        'MMM d',
        'MMMM d',
        'MMM d, y',
        'MMMM d, y',
        'MM/dd/yyyy',
        'dd/MM/yyyy',
        'yyyy-MM-dd',
        'd MMM',
        'd MMMM',
      ];

      for (var format in dateFormats) {
        try {
          final date = DateFormat(format).parse(text);
          // If no year was in the format, use current year
          if (!format.contains('y')) {
            return DateTime(now.year, date.month, date.day);
          }
          return date;
        } catch (_) {}
      }
    } catch (_) {}

    return null;
  }

  /// Extract description from voice text
  String? _extractDescription(String text) {
    // Remove common expense phrases to get description
    final cleaned = text
        .replaceAll(RegExp(r'\$[\d,]+\.?\d*'), '')
        .replaceAll(RegExp(r'[\d,]+\.?\d*\s*(dollars?|euros?|pounds?|yen|naira|rupees?)', caseSensitive: false), '')
        .replaceAll(RegExp(r'(spent|paid|cost|bought|purchased)\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+(at|from|on|for)\s+', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.length > 5 && cleaned.length < 200) {
      return cleaned;
    }

    return null;
  }

  /// Get the hybrid parser instance
  HybridExpenseParser? get hybridParser => _hybridParser;

  /// Get the generic parser instance
  GenericExpenseParser? get genericParser => _genericParser;
}

/// Enhanced parsed voice expense with confidence and currency support
class ParsedVoiceExpense {
  final double? amount;
  final String? currency;
  final String? currencySymbol;
  final CategoryModel? category;
  final DateTime? date;
  final String? merchant;
  final String? description;
  final String rawText;
  final double confidence;
  final ParsedExpenseResult? parsedResult;

  ParsedVoiceExpense({
    this.amount,
    this.currency,
    this.currencySymbol,
    this.category,
    this.date,
    this.merchant,
    this.description,
    required this.rawText,
    this.confidence = 0.5,
    this.parsedResult,
  });

  /// Check if we have enough data to create an expense
  bool get isValid => amount != null && amount! > 0;

  /// Get formatted amount with currency
  String get formattedAmount {
    if (amount == null) return '';
    final symbol = currencySymbol ?? '\$';
    return '$symbol${amount!.toStringAsFixed(2)}';
  }

  /// Convert to ParsedExpenseResult for consistency with other parsers
  ParsedExpenseResult toExpenseResult() {
    return parsedResult ?? ParsedExpenseResult(
      amount: amount,
      currency: currency,
      currencySymbol: currencySymbol,
      merchant: merchant,
      category: category?.name,
      date: date,
      description: description,
      rawText: rawText,
      confidence: confidence,
      source: ParsingSource.voice,
      suggestedTitle: merchant ?? description,
    );
  }
}
