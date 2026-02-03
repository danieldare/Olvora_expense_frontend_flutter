import '../../data/matchers/mapping_memory.dart';

/// Use case: Save a category mapping for future imports
class SaveCategoryMapping {
  final MappingMemory _memory;

  SaveCategoryMapping({
    required MappingMemory memory,
  }) : _memory = memory;

  /// Save mapping
  Future<void> execute({
    required String originalName,
    required String categoryName,
  }) async {
    await _memory.saveMapping(originalName, categoryName);
  }
}
