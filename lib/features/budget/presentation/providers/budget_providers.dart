import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/scheduler.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/dto/create_budget_dto.dart';
import '../../data/dto/update_budget_dto.dart';
import '../../domain/entities/budget_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Provider for budget repository (using V2 API service with enhanced token management)
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final apiServiceV2 = ref.watch(apiServiceV2Provider);
  return BudgetRepositoryImpl(apiServiceV2);
});

/// Provider for general budgets (daily, weekly, monthly)
/// CRITICAL: Depends on auth state to ensure data is cleared when user changes
final generalBudgetsProvider = FutureProvider<List<BudgetEntity>>((ref) async {
  // Keep data alive to prevent disposal on widget unmount
  ref.keepAlive();

  // Watch user ID - only refetch when user actually changes
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return [];
  }

  final repository = ref.watch(budgetRepositoryProvider);
  return repository.getGeneralBudgets();
});

/// Provider for category-specific budgets
/// CRITICAL: Depends on auth state to ensure data is cleared when user changes
final categoryBudgetsProvider = FutureProvider<List<BudgetEntity>>((ref) async {
  // Keep data alive to prevent disposal on widget unmount
  ref.keepAlive();

  // Watch user ID - only refetch when user actually changes
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return [];
  }

  final repository = ref.watch(budgetRepositoryProvider);
  return repository.getCategoryBudgets();
});

/// Provider for spending statistics
final spendingStatisticsProvider = FutureProvider<Map<String, double>>((
  ref,
) async {
  final repository = ref.watch(budgetRepositoryProvider);
  return repository.getSpendingStatistics();
});

/// StateNotifier for budget operations
final budgetNotifierProvider =
    StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {
      final repository = ref.watch(budgetRepositoryProvider);
      return BudgetNotifier(repository, ref);
    });

/// Budget state
class BudgetState {
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  BudgetState({this.isLoading = false, this.error, this.lastUpdated});

  BudgetState copyWith({
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return BudgetState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Budget notifier for managing budget operations
class BudgetNotifier extends StateNotifier<BudgetState> {
  final BudgetRepository _repository;
  final Ref _ref;

  BudgetNotifier(this._repository, this._ref) : super(BudgetState());

  /// Refresh general budgets
  Future<void> refreshGeneralBudgets() async {
    return Future(() {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _ref.invalidate(generalBudgetsProvider);
      });
    });
  }

  /// Refresh category budgets
  Future<void> refreshCategoryBudgets() async {
    return Future(() {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _ref.invalidate(categoryBudgetsProvider);
      });
    });
  }

  /// Refresh all budgets
  Future<void> refreshAllBudgets() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.wait([refreshGeneralBudgets(), refreshCategoryBudgets()]);
      state = state.copyWith(isLoading: false, lastUpdated: DateTime.now());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create a new budget
  Future<BudgetEntity> createBudget(CreateBudgetDto dto) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final budget = await _repository.createBudget(dto);
      await refreshAllBudgets();
      return budget;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Update an existing budget
  Future<BudgetEntity> updateBudget(String id, UpdateBudgetDto dto) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final budget = await _repository.updateBudget(id, dto);
      await refreshAllBudgets();
      return budget;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Delete a budget
  /// [deleteAssociatedCategories] - If true, deletes all associated category budgets. If false, keeps them as independent.
  Future<void> deleteBudget(String id, {bool deleteAssociatedCategories = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteBudget(id, deleteAssociatedCategories: deleteAssociatedCategories);
      await refreshAllBudgets();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}
