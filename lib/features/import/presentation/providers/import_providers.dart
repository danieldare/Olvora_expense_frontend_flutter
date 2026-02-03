import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../data/repositories/import_repository_impl.dart';
import '../../data/datasources/import_remote_datasource.dart';
import '../../data/datasources/import_local_datasource.dart';
import '../../data/matchers/category_matcher.dart';
import '../../data/matchers/mapping_memory.dart';
import '../../domain/repositories/import_repository.dart';
import '../../domain/entities/import_preview.dart';
import '../../domain/entities/import_result.dart';
import '../../domain/entities/import_history_entry.dart';
import '../../domain/entities/category_mapping.dart';

/// Provider for ImportRemoteDataSource
final importRemoteDataSourceProvider = Provider<ImportRemoteDataSource>((ref) {
  final apiService = ref.watch(apiServiceV2Provider);
  return ImportRemoteDataSource(apiService);
});

/// Provider for ImportLocalDataSource
final importLocalDataSourceProvider = Provider<ImportLocalDataSource>((ref) {
  return ImportLocalDataSource();
});

/// Provider for ImportRepository
final importRepositoryProvider = Provider<ImportRepository>((ref) {
  final remoteDataSource = ref.watch(importRemoteDataSourceProvider);
  final localDataSource = ref.watch(importLocalDataSourceProvider);
  return ImportRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );
});

/// Provider for MappingMemory
final mappingMemoryProvider = Provider<MappingMemory>((ref) {
  return MappingMemory();
});

/// Provider for CategoryMatcher
final categoryMatcherProvider = Provider<CategoryMatcher>((ref) {
  final memory = ref.watch(mappingMemoryProvider);
  return CategoryMatcher(memory: memory);
});

/// Provider for import history
final importHistoryProvider = FutureProvider<List<ImportHistoryEntry>>((ref) async {
  final repository = ref.watch(importRepositoryProvider);
  return await repository.getImportHistory();
});

/// State for import flow
class ImportState {
  final ImportPreview? preview;
  final bool isParsing;
  final bool isImporting;
  final String? error;
  final ImportResult? result;

  const ImportState({
    this.preview,
    this.isParsing = false,
    this.isImporting = false,
    this.error,
    this.result,
  });

  ImportState copyWith({
    ImportPreview? preview,
    bool? isParsing,
    bool? isImporting,
    String? error,
    ImportResult? result,
  }) {
    return ImportState(
      preview: preview ?? this.preview,
      isParsing: isParsing ?? this.isParsing,
      isImporting: isImporting ?? this.isImporting,
      error: error,
      result: result ?? this.result,
    );
  }
}

/// StateNotifier for managing import flow
class ImportNotifier extends StateNotifier<ImportState> {
  final ImportRepository _repository;
  final CategoryMatcher _categoryMatcher;
  final MappingMemory _mappingMemory;

  ImportNotifier(this._repository, this._categoryMatcher, this._mappingMemory)
      : super(const ImportState());

  /// Update category mapping for an expense
  void updateCategoryMapping(String originalCategory, String categoryName) async {
    final preview = state.preview;
    if (preview == null) return;

    // Update expenses with new category
    final updatedExpenses = preview.expenses.map((e) {
      if (e.originalCategory == originalCategory) {
        return e.copyWithCategory(categoryName);
      }
      return e;
    }).toList();

    // Update category mappings
    final updatedMappings = preview.categoryMappings.map((m) {
      if (m.originalName == originalCategory) {
        return CategoryMapping(
          originalName: m.originalName,
          mappedCategoryName: categoryName,
          confidence: 1.0,
          source: MappingSource.user,
          suggestions: m.suggestions,
        );
      }
      return m;
    }).toList();

    // Save mapping for future use
    await _mappingMemory.saveMapping(originalCategory, categoryName);

    final updatedPreview = ImportPreview(
      file: preview.file,
      structure: preview.structure,
      expenses: updatedExpenses,
      categoryMappings: updatedMappings,
      selectedYear: preview.selectedYear,
      selectedSheetName: preview.selectedSheetName,
    );

    state = state.copyWith(preview: updatedPreview);
  }

  /// Set preview (called after parsing)
  void setPreview(ImportPreview preview) {
    state = state.copyWith(preview: preview, isParsing: false, error: null);
  }

  /// Set parsing state
  void setParsing(bool isParsing) {
    state = state.copyWith(isParsing: isParsing);
  }

  /// Set importing state
  void setImporting(bool isImporting) {
    state = state.copyWith(isImporting: isImporting);
  }

  /// Set error
  void setError(String error) {
    state = state.copyWith(error: error, isParsing: false, isImporting: false);
  }

  /// Set result
  void setResult(ImportResult result) {
    state = state.copyWith(result: result, isImporting: false);
  }

  /// Reset state
  void reset() {
    state = const ImportState();
  }
}

/// Provider for ImportNotifier
final importNotifierProvider =
    StateNotifierProvider<ImportNotifier, ImportState>((ref) {
  final repository = ref.watch(importRepositoryProvider);
  final categoryMatcher = ref.watch(categoryMatcherProvider);
  final mappingMemory = ref.watch(mappingMemoryProvider);
  return ImportNotifier(repository, categoryMatcher, mappingMemory);
});
