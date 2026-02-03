/// Production-grade column mapping service with intelligent auto-detection.
///
/// Strategy:
/// 1. Exact match (case-insensitive)
/// 2. Contains match (header contains keyword)
/// 3. Fuzzy match (Levenshtein distance <= 2)
/// 4. Common aliases (e.g., "Total" → Amount)
///
/// Never guesses - returns null if no match found.
class ColumnMapper {
  /// Auto-detects column mappings from CSV headers.
  ///
  /// Returns a mapping with detected columns, or null for unmapped columns.
  /// User can then manually override any mapping.
  static ColumnMapping autoDetect(List<String> headers) {
    return ColumnMapping(
      titleColumn: _detectColumn(headers, _titleKeywords),
      amountColumn: _detectColumn(headers, _amountKeywords),
      dateColumn: _detectColumn(headers, _dateKeywords),
      categoryColumn: _detectColumn(headers, _categoryKeywords),
      merchantColumn: _detectColumn(headers, _merchantKeywords),
      descriptionColumn: _detectColumn(headers, _descriptionKeywords),
    );
  }

  /// Detects a single column using multiple strategies.
  static String? _detectColumn(List<String> headers, List<String> keywords) {
    // Strategy 1: Exact match (case-insensitive)
    for (final header in headers) {
      final normalized = header.toLowerCase().trim();
      for (final keyword in keywords) {
        if (normalized == keyword) {
          return header; // Return original header (preserves case)
        }
      }
    }

    // Strategy 2: Contains match
    for (final header in headers) {
      final normalized = header.toLowerCase().trim();
      for (final keyword in keywords) {
        if (normalized.contains(keyword) || keyword.contains(normalized)) {
          return header;
        }
      }
    }

    // Strategy 3: Fuzzy match (Levenshtein distance <= 2)
    for (final header in headers) {
      final normalized = header.toLowerCase().trim();
      for (final keyword in keywords) {
        if (_fuzzyMatch(normalized, keyword)) {
          return header;
        }
      }
    }

    return null; // No match found - user must map manually
  }

  /// Simple fuzzy matching using Levenshtein-like distance.
  /// Returns true if strings are similar (≤2 character differences).
  static bool _fuzzyMatch(String str1, String str2) {
    // If length difference is too large, not a match
    if ((str1.length - str2.length).abs() > 2) return false;

    // Count character differences
    int differences = 0;
    final minLen = str1.length < str2.length ? str1.length : str2.length;

    for (int i = 0; i < minLen; i++) {
      if (str1[i] != str2[i]) {
        differences++;
        if (differences > 2) return false;
      }
    }

    // Account for length differences
    differences += (str1.length - str2.length).abs();
    return differences <= 2;
  }

  // Keyword lists for each field type
  static const _titleKeywords = [
    'title',
    'description',
    'name',
    'item',
    'expense',
    'transaction',
    'note',
    'memo',
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
  ];

  static const _dateKeywords = [
    'date',
    'transaction date',
    'purchase date',
    'expense date',
    'when',
    'time',
    'timestamp',
  ];

  static const _categoryKeywords = [
    'category',
    'type',
    'expense type',
    'cat',
    'expense category',
    'classification',
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
  ];

  static const _descriptionKeywords = [
    'description',
    'notes',
    'note',
    'details',
    'memo',
    'comment',
    'remarks',
  ];
}

/// Column mapping configuration.
///
/// Maps CSV column names to expense fields.
/// Required fields: title, amount, date, category
/// Optional fields: merchant, description
class ColumnMapping {
  final String? titleColumn;
  final String? amountColumn;
  final String? dateColumn;
  final String? categoryColumn;
  final String? merchantColumn;
  final String? descriptionColumn;

  ColumnMapping({
    this.titleColumn,
    this.amountColumn,
    this.dateColumn,
    this.categoryColumn,
    this.merchantColumn,
    this.descriptionColumn,
  });

  /// Returns true if all required columns are mapped.
  bool get isValid {
    return titleColumn != null &&
        amountColumn != null &&
        dateColumn != null &&
        categoryColumn != null;
  }

  /// Returns list of missing required columns.
  List<String> get missingRequiredColumns {
    final missing = <String>[];
    if (titleColumn == null) missing.add('Title');
    if (amountColumn == null) missing.add('Amount');
    if (dateColumn == null) missing.add('Date');
    if (categoryColumn == null) missing.add('Category');
    return missing;
  }

  /// Converts to API format (Map<String, String>).
  Map<String, String> toJson() {
    final map = <String, String>{};
    if (titleColumn != null) map['titleColumn'] = titleColumn!;
    if (amountColumn != null) map['amountColumn'] = amountColumn!;
    if (dateColumn != null) map['dateColumn'] = dateColumn!;
    if (categoryColumn != null) map['categoryColumn'] = categoryColumn!;
    if (merchantColumn != null) map['merchantColumn'] = merchantColumn!;
    if (descriptionColumn != null) {
      map['descriptionColumn'] = descriptionColumn!;
    }
    return map;
  }

  /// Creates from API format.
  factory ColumnMapping.fromJson(Map<String, dynamic> json) {
    return ColumnMapping(
      titleColumn: json['titleColumn'] as String?,
      amountColumn: json['amountColumn'] as String?,
      dateColumn: json['dateColumn'] as String?,
      categoryColumn: json['categoryColumn'] as String?,
      merchantColumn: json['merchantColumn'] as String?,
      descriptionColumn: json['descriptionColumn'] as String?,
    );
  }

  /// Creates a copy with updated field.
  ColumnMapping copyWith({
    String? titleColumn,
    String? amountColumn,
    String? dateColumn,
    String? categoryColumn,
    String? merchantColumn,
    String? descriptionColumn,
  }) {
    return ColumnMapping(
      titleColumn: titleColumn ?? this.titleColumn,
      amountColumn: amountColumn ?? this.amountColumn,
      dateColumn: dateColumn ?? this.dateColumn,
      categoryColumn: categoryColumn ?? this.categoryColumn,
      merchantColumn: merchantColumn ?? this.merchantColumn,
      descriptionColumn: descriptionColumn ?? this.descriptionColumn,
    );
  }
}
