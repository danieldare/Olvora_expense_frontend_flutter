/// Mapping between original category name and Olvora category
class CategoryMapping {
  final String originalName;       // From file: "Internet Sub"
  final String? mappedCategoryId;  // Olvora category ID (for future use)
  final String? mappedCategoryName;// Olvora category name
  final double confidence;         // 0.0 - 1.0
  final MappingSource source;
  final List<String> suggestions;  // Alternative suggestions

  const CategoryMapping({
    required this.originalName,
    this.mappedCategoryId,
    this.mappedCategoryName,
    required this.confidence,
    required this.source,
    this.suggestions = const [],
  });

  bool get isMapped => mappedCategoryName != null;
  bool get needsUserInput => !isMapped;
  bool get isAutoMapped => isMapped && source != MappingSource.user;
}

/// Source of the category mapping
enum MappingSource {
  exactMatch,      // Exact string match
  keywordMatch,    // Matched via keyword bank
  fuzzyMatch,      // Fuzzy string similarity
  savedMapping,    // User's previous mapping
  crowdSourced,    // Other users' common mapping (future)
  user,            // User selected in this session
}
