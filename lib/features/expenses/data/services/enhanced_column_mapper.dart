import 'column_mapper.dart';

/// Enhanced column mapper with advanced fuzzy matching and confidence scoring.
///
/// Features:
/// - Levenshtein distance for fuzzy matching
/// - Confidence scores for each detection
/// - Multiple detection strategies
/// - Context-aware matching (e.g., "Transaction Date" → date)
/// - Handles variations: "Amount (NGN)", "Total Amount", "Price ($)", etc.
class EnhancedColumnMapper {
  /// Detects columns with confidence scores.
  ///
  /// Returns ColumnMappingWithConfidence with detected mappings and scores.
  static ColumnMappingWithConfidence detectWithConfidence(List<String> headers) {
    final mappings = <String, ColumnDetection?>{};

    // Detect each field type
    mappings['title'] = _detectColumn(headers, _titleKeywords, _titlePatterns);
    mappings['amount'] = _detectColumn(headers, _amountKeywords, _amountPatterns);
    mappings['date'] = _detectColumn(headers, _dateKeywords, _datePatterns);
    mappings['category'] = _detectColumn(headers, _categoryKeywords, _categoryPatterns);
    mappings['merchant'] = _detectColumn(headers, _merchantKeywords, _merchantPatterns);
    mappings['description'] = _detectColumn(headers, _descriptionKeywords, _descriptionPatterns);

    return ColumnMappingWithConfidence(
      titleColumn: mappings['title']?.columnName,
      amountColumn: mappings['amount']?.columnName,
      dateColumn: mappings['date']?.columnName,
      categoryColumn: mappings['category']?.columnName,
      merchantColumn: mappings['merchant']?.columnName,
      descriptionColumn: mappings['description']?.columnName,
      detections: mappings,
    );
  }

  /// Detects a single column using multiple strategies.
  static ColumnDetection? _detectColumn(
    List<String> headers,
    List<String> keywords,
    List<RegExp> patterns,
  ) {
    ColumnDetection? bestMatch;
    double bestScore = 0.0;

    for (final header in headers) {
      final normalized = header.toLowerCase().trim();
      
      // Strategy 1: Exact match (confidence: 1.0)
      for (final keyword in keywords) {
        if (normalized == keyword) {
          return ColumnDetection(
            columnName: header,
            confidence: 1.0,
            method: DetectionMethod.exact,
          );
        }
      }

      // Strategy 2: Contains match (confidence: 0.8-0.9)
      for (final keyword in keywords) {
        if (normalized.contains(keyword) || keyword.contains(normalized)) {
          final score = keyword.length / normalized.length.clamp(1, double.infinity);
          final confidence = (0.8 + (score * 0.1)).clamp(0.0, 0.9);
          
          if (confidence > bestScore) {
            bestMatch = ColumnDetection(
              columnName: header,
              confidence: confidence,
              method: DetectionMethod.contains,
            );
            bestScore = confidence;
          }
        }
      }

      // Strategy 3: Pattern match (confidence: 0.7-0.85)
      for (final pattern in patterns) {
        if (pattern.hasMatch(normalized)) {
          final confidence = 0.75;
          if (confidence > bestScore) {
            bestMatch = ColumnDetection(
              columnName: header,
              confidence: confidence,
              method: DetectionMethod.pattern,
            );
            bestScore = confidence;
          }
        }
      }

      // Strategy 4: Fuzzy match (confidence: 0.5-0.7)
      for (final keyword in keywords) {
        final distance = _levenshteinDistance(normalized, keyword);
        final maxLen = normalized.length > keyword.length ? normalized.length : keyword.length;
        
        if (maxLen > 0) {
          final similarity = 1.0 - (distance / maxLen);
          
          // Only consider if similarity > 0.6 (fuzzy threshold)
          if (similarity > 0.6) {
            final confidence = (0.5 + (similarity - 0.6) * 0.5).clamp(0.5, 0.7);
            
            if (confidence > bestScore) {
              bestMatch = ColumnDetection(
                columnName: header,
                confidence: confidence,
                method: DetectionMethod.fuzzy,
              );
              bestScore = confidence;
            }
          }
        }
      }
    }

    return bestMatch;
  }

  /// Calculates Levenshtein distance between two strings.
  static int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  // Enhanced keyword lists
  static const _titleKeywords = [
    'title',
    'description',
    'name',
    'item',
    'expense',
    'transaction',
    'note',
    'memo',
    'details',
    'particulars',
    'narration',
    'remark',
  ];

  static const _amountKeywords = [
    'amount',
    'total',
    'price',
    'cost',
    'sum',
    'value',
    'paid',
    'charge',
    'debit',
    'credit',
    'balance',
    'fee',
  ];

  static const _dateKeywords = [
    'date',
    'transaction date',
    'purchase date',
    'expense date',
    'when',
    'time',
    'timestamp',
    'transaction_date',
    'purchase_date',
    'expense_date',
    'transactiondate',
    'purchasedate',
  ];

  static const _categoryKeywords = [
    'category',
    'type',
    'expense type',
    'cat',
    'expense category',
    'classification',
    'expense_category',
    'expense_type',
    'expensecategory',
    'expensetype',
  ];

  static const _merchantKeywords = [
    'merchant',
    'store',
    'vendor',
    'shop',
    'seller',
    'place',
    'location',
    'business',
    'retailer',
    'provider',
    'supplier',
  ];

  static const _descriptionKeywords = [
    'description',
    'notes',
    'note',
    'details',
    'memo',
    'comment',
    'remarks',
    'narration',
    'particulars',
  ];

  // Pattern-based detection (regex)
  static final _titlePatterns = [
    RegExp(r'^(title|name|item|expense|transaction|description)', caseSensitive: false),
  ];

  static final _amountPatterns = [
    RegExp(r'amount|total|price|cost|sum|value|paid|charge', caseSensitive: false),
    RegExp(r'\$|₦|€|£|₹|¥', caseSensitive: false), // Currency symbols
  ];

  static final _datePatterns = [
    RegExp(r'date|time|when|timestamp', caseSensitive: false),
    RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}', caseSensitive: false), // Date-like patterns
  ];

  static final _categoryPatterns = [
    RegExp(r'category|type|cat|classification', caseSensitive: false),
  ];

  static final _merchantPatterns = [
    RegExp(r'merchant|store|vendor|shop|seller|business', caseSensitive: false),
  ];

  static final _descriptionPatterns = [
    RegExp(r'description|notes|note|details|memo|comment', caseSensitive: false),
  ];
}

/// Column detection result with confidence score.
class ColumnDetection {
  final String columnName;
  final double confidence; // 0.0 to 1.0
  final DetectionMethod method;

  ColumnDetection({
    required this.columnName,
    required this.confidence,
    required this.method,
  });
}

/// Detection method used.
enum DetectionMethod {
  exact,
  contains,
  pattern,
  fuzzy,
}

/// Column mapping with confidence scores.
class ColumnMappingWithConfidence {
  final String? titleColumn;
  final String? amountColumn;
  final String? dateColumn;
  final String? categoryColumn;
  final String? merchantColumn;
  final String? descriptionColumn;
  final Map<String, ColumnDetection?> detections;

  ColumnMappingWithConfidence({
    this.titleColumn,
    this.amountColumn,
    this.dateColumn,
    this.categoryColumn,
    this.merchantColumn,
    this.descriptionColumn,
    required this.detections,
  });

  /// Converts to standard ColumnMapping.
  ColumnMapping toColumnMapping() {
    return ColumnMapping(
      titleColumn: titleColumn,
      amountColumn: amountColumn,
      dateColumn: dateColumn,
      categoryColumn: categoryColumn,
      merchantColumn: merchantColumn,
      descriptionColumn: descriptionColumn,
    );
  }

  /// Returns overall confidence score (average of all detections).
  double get overallConfidence {
    final scores = detections.values
        .where((d) => d != null)
        .map((d) => d!.confidence)
        .toList();
    
    if (scores.isEmpty) return 0.0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  /// Returns true if all required columns are detected with high confidence.
  bool get isHighConfidence {
    return titleColumn != null &&
        amountColumn != null &&
        dateColumn != null &&
        categoryColumn != null &&
        overallConfidence >= 0.7;
  }

  /// Returns true if all required columns are mapped (regardless of confidence).
  bool get isValid {
    return titleColumn != null &&
        amountColumn != null &&
        dateColumn != null &&
        categoryColumn != null;
  }
}

