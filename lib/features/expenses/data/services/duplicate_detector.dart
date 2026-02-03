
/// Smart duplicate detection for expense imports.
///
/// Detects duplicates using multiple strategies:
/// - Exact match (date + amount + merchant)
/// - Fuzzy match (similar date, amount, merchant)
/// - Within time window (same merchant, similar amount, within 24 hours)
///
/// Returns duplicate groups with confidence scores.
class DuplicateDetector {
  /// Detects duplicates in a list of expenses.
  ///
  /// Returns list of duplicate groups, each containing indices of duplicate expenses.
  static List<DuplicateGroup> detectDuplicates(List<ExpenseCandidate> expenses) {
    final groups = <DuplicateGroup>[];
    final processed = <int>{};

    for (int i = 0; i < expenses.length; i++) {
      if (processed.contains(i)) continue;

      final expense = expenses[i];
      final duplicates = <int>[i];

      // Check against all other expenses
      for (int j = i + 1; j < expenses.length; j++) {
        if (processed.contains(j)) continue;

        final other = expenses[j];
        final similarity = _calculateSimilarity(expense, other);

        if (similarity >= 0.9) {
          // High confidence duplicate
          duplicates.add(j);
          processed.add(j);
        } else if (similarity >= 0.7) {
          // Medium confidence - might be duplicate
          duplicates.add(j);
          processed.add(j);
        }
      }

      if (duplicates.length > 1) {
        groups.add(DuplicateGroup(
          indices: duplicates,
          confidence: _calculateGroupConfidence(expenses, duplicates),
          reason: _getDuplicateReason(expenses, duplicates),
        ));
        processed.addAll(duplicates);
      }
    }

    return groups;
  }

  /// Calculates similarity between two expenses (0.0 to 1.0).
  static double _calculateSimilarity(ExpenseCandidate a, ExpenseCandidate b) {
    double score = 0.0;
    int factors = 0;

    // Date similarity (within 24 hours = 1.0, within 7 days = 0.8, etc.)
    if (a.date != null && b.date != null) {
      final daysDiff = a.date!.difference(b.date!).inDays.abs();
      double dateScore = 0.0;
      if (daysDiff == 0) {
        dateScore = 1.0;
      } else if (daysDiff <= 1) {
        dateScore = 0.9;
      } else if (daysDiff <= 7) {
        dateScore = 0.7;
      } else if (daysDiff <= 30) {
        dateScore = 0.3;
      }
      score += dateScore * 0.3; // Date is 30% of similarity
      factors++;
    }

    // Amount similarity (exact = 1.0, within 1% = 0.9, within 5% = 0.7)
    if (a.amount != null && b.amount != null) {
      final amountDiff = (a.amount! - b.amount!).abs();
      final avgAmount = (a.amount! + b.amount!) / 2;
      double amountScore = 0.0;
      if (amountDiff == 0) {
        amountScore = 1.0;
      } else if (avgAmount > 0) {
        final percentDiff = amountDiff / avgAmount;
        if (percentDiff <= 0.01) {
          amountScore = 0.9;
        } else if (percentDiff <= 0.05) {
          amountScore = 0.7;
        } else if (percentDiff <= 0.1) {
          amountScore = 0.5;
        }
      }
      score += amountScore * 0.4; // Amount is 40% of similarity
      factors++;
    }

    // Merchant/title similarity (fuzzy string matching)
    if (a.merchant != null && b.merchant != null && 
        a.merchant!.isNotEmpty && b.merchant!.isNotEmpty) {
      final merchantScore = _stringSimilarity(a.merchant!, b.merchant!);
      score += merchantScore * 0.3; // Merchant is 30% of similarity
      factors++;
    } else if (a.title != null && b.title != null &&
        a.title!.isNotEmpty && b.title!.isNotEmpty) {
      final titleScore = _stringSimilarity(a.title!, b.title!);
      score += titleScore * 0.2; // Title is 20% of similarity (less weight)
      factors++;
    }

    // Normalize by number of factors
    return factors > 0 ? score / factors : 0.0;
  }

  /// Calculates string similarity using Levenshtein distance.
  static double _stringSimilarity(String s1, String s2) {
    final normalized1 = s1.toLowerCase().trim();
    final normalized2 = s2.toLowerCase().trim();

    if (normalized1 == normalized2) return 1.0;
    if (normalized1.contains(normalized2) || normalized2.contains(normalized1)) {
      return 0.9;
    }

    final distance = _levenshteinDistance(normalized1, normalized2);
    final maxLen = normalized1.length > normalized2.length 
        ? normalized1.length 
        : normalized2.length;
    
    if (maxLen == 0) return 1.0;
    return 1.0 - (distance / maxLen);
  }

  /// Levenshtein distance implementation.
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
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  /// Calculates confidence for a duplicate group.
  static double _calculateGroupConfidence(
    List<ExpenseCandidate> expenses,
    List<int> indices,
  ) {
    if (indices.length < 2) return 0.0;

    double totalSimilarity = 0.0;
    int comparisons = 0;

    for (int i = 0; i < indices.length; i++) {
      for (int j = i + 1; j < indices.length; j++) {
        totalSimilarity += _calculateSimilarity(
          expenses[indices[i]],
          expenses[indices[j]],
        );
        comparisons++;
      }
    }

    return comparisons > 0 ? totalSimilarity / comparisons : 0.0;
  }

  /// Gets human-readable reason for duplicate detection.
  static String _getDuplicateReason(
    List<ExpenseCandidate> expenses,
    List<int> indices,
  ) {
    if (indices.length < 2) return '';

    final first = expenses[indices[0]];
    final second = expenses[indices[1]];

    // Check for exact match
    if (first.date == second.date &&
        first.amount == second.amount &&
        first.merchant == second.merchant) {
      return 'Exact match: Same date, amount, and merchant';
    }

    // Check for similar date and amount
    if (first.date != null && second.date != null &&
        first.amount != null && second.amount != null) {
      final daysDiff = first.date!.difference(second.date!).inDays.abs();
      final amountDiff = (first.amount! - second.amount!).abs();
      
      if (daysDiff <= 1 && amountDiff < 0.01) {
        return 'Very similar: Same amount, within 1 day';
      }
    }

    return 'Similar expenses detected';
  }
}

/// Expense candidate for duplicate detection.
class ExpenseCandidate {
  final DateTime? date;
  final double? amount;
  final String? merchant;
  final String? title;
  final int rowNumber;

  ExpenseCandidate({
    this.date,
    this.amount,
    this.merchant,
    this.title,
    required this.rowNumber,
  });
}

/// Group of duplicate expenses.
class DuplicateGroup {
  final List<int> indices; // Row numbers
  final double confidence; // 0.0 to 1.0
  final String reason;

  DuplicateGroup({
    required this.indices,
    required this.confidence,
    required this.reason,
  });

  /// Returns true if this is a high-confidence duplicate.
  bool get isHighConfidence => confidence >= 0.9;

  /// Returns count of duplicates in this group.
  int get count => indices.length;
}

