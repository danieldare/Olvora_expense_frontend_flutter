import 'package:string_similarity/string_similarity.dart';
import 'keyword_bank.dart';
import 'mapping_memory.dart';
import '../../domain/entities/category_mapping.dart';
import '../../../../features/expenses/domain/entities/expense_entity.dart';

class CategoryMatcher {
  final MappingMemory _memory;

  CategoryMatcher({required MappingMemory memory}) : _memory = memory;

  Future<List<CategoryMapping>> matchAll(
    List<String> originalCategories,
  ) async {
    final uniqueCategories = originalCategories.toSet().toList();
    final mappings = <CategoryMapping>[];

    for (final original in uniqueCategories) {
      mappings.add(await match(original));
    }

    return mappings;
  }

  Future<CategoryMapping> match(String originalCategory) async {
    final normalized = originalCategory.toLowerCase().trim();

    // 1. Check saved mappings first
    final savedMapping = await _memory.getMapping(normalized);
    if (savedMapping != null) {
      return CategoryMapping(
        originalName: originalCategory,
        mappedCategoryName: savedMapping,
        confidence: 0.95,
        source: MappingSource.savedMapping,
      );
    }

    // 2. Exact match with category enum names
    final exactMatch = ExpenseCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == normalized,
      orElse: () => ExpenseCategory.other,
    );
    if (exactMatch != ExpenseCategory.other) {
      return CategoryMapping(
        originalName: originalCategory,
        mappedCategoryName: exactMatch.name,
        confidence: 1.0,
        source: MappingSource.exactMatch,
      );
    }

    // 3. Keyword-based matching
    final keywordMatch = _matchByKeywords(normalized);
    if (keywordMatch != null) {
      return CategoryMapping(
        originalName: originalCategory,
        mappedCategoryName: keywordMatch.name,
        confidence: 0.85,
        source: MappingSource.keywordMatch,
        suggestions: _getSuggestions(normalized, exclude: keywordMatch),
      );
    }

    // 4. Fuzzy string matching (lower threshold for better coverage)
    final fuzzyMatch = _matchByFuzzy(normalized);
    if (fuzzyMatch != null && fuzzyMatch.confidence > 0.4) {
      return CategoryMapping(
        originalName: originalCategory,
        mappedCategoryName: fuzzyMatch.category.name,
        confidence: fuzzyMatch.confidence,
        source: MappingSource.fuzzyMatch,
        suggestions: _getSuggestions(normalized, exclude: fuzzyMatch.category),
      );
    }

    // 5. Best guess from suggestions (use top suggestion if confidence > 0.3)
    final suggestions = _getSuggestions(normalized);
    if (suggestions.isNotEmpty) {
      final bestGuess = suggestions.first;
      final guessScore = normalized.similarityTo(bestGuess.toLowerCase());
      if (guessScore > 0.3) {
        return CategoryMapping(
          originalName: originalCategory,
          mappedCategoryName: bestGuess,
          confidence: guessScore,
          source: MappingSource.fuzzyMatch,
          suggestions: suggestions,
        );
      }
    }

    // 6. Default to "other" - ALWAYS return a category for seamless import
    // This ensures users can import without manual mapping
    return CategoryMapping(
      originalName: originalCategory,
      mappedCategoryName: ExpenseCategory.other.name,
      confidence: 0.5, // Medium confidence - user can fix later
      source: MappingSource.fuzzyMatch,
      suggestions: suggestions,
    );
  }

  ExpenseCategory? _matchByKeywords(String normalized) {
    for (final entry in KeywordBank.coreKeywords.entries) {
      final keywords = entry.value;

      // Check if normalized contains any keyword
      for (final keyword in keywords) {
        if (normalized.contains(keyword) || keyword.contains(normalized)) {
          final categoryName = KeywordBank.categoryMap[entry.key];
          if (categoryName != null) {
            return ExpenseCategory.values.firstWhere(
              (c) => c.name == categoryName,
              orElse: () => ExpenseCategory.other,
            );
          }
        }
      }
    }
    return null;
  }

  ({ExpenseCategory category, double confidence})? _matchByFuzzy(
    String normalized,
  ) {
    double bestScore = 0;
    ExpenseCategory? bestMatch;

    for (final category in ExpenseCategory.values) {
      if (category == ExpenseCategory.other) continue;

      final score = normalized.similarityTo(category.name.toLowerCase());
      if (score > bestScore) {
        bestScore = score;
        bestMatch = category;
      }
    }

    // Lower threshold for better coverage - we'll default to "other" if still uncertain
    if (bestMatch != null && bestScore > 0.3) {
      return (category: bestMatch, confidence: bestScore);
    }
    return null;
  }

  List<String> _getSuggestions(String normalized, {ExpenseCategory? exclude}) {
    // Return top 3 likely categories as suggestions
    final scores = <String, double>{};

    for (final category in ExpenseCategory.values) {
      if (category == ExpenseCategory.other || category == exclude) continue;

      // Combine keyword match score and fuzzy score
      double score = normalized.similarityTo(category.name.toLowerCase());

      // Boost if keyword match
      final keywordBoost = _hasKeywordMatch(normalized, category);
      if (keywordBoost) score += 0.3;

      scores[category.name] = score;
    }

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).map((e) => e.key).toList();
  }

  bool _hasKeywordMatch(String normalized, ExpenseCategory category) {
    final categoryKey = KeywordBank.categoryMap.entries
        .firstWhere(
          (e) => e.value == category.name,
          orElse: () => const MapEntry('', ''),
        )
        .key;

    if (categoryKey.isEmpty) return false;

    final keywords = KeywordBank.coreKeywords[categoryKey] ?? [];
    return keywords.any(
      (kw) => normalized.contains(kw) || kw.contains(normalized),
    );
  }
}
