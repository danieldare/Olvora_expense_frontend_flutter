import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../data/repositories/category_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../../core/utils/auth_error_handler.dart';

/// Provider for category repository (using V2 API service with enhanced token management)
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final apiServiceV2 = ref.watch(apiServiceV2Provider);
  return CategoryRepositoryImpl(apiServiceV2);
});

/// Provider for all categories
/// CRITICAL: Depends on auth state to ensure data is cleared when user changes
/// Uses keepAlive to prevent unnecessary reloads and reduce flicker
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  // Keep provider alive to cache results and prevent flicker
  ref.keepAlive();

  // Watch user ID - only refetch when user actually changes
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    return [];
  }

  try {
    final repository = ref.watch(categoryRepositoryProvider);
    final categories = await repository.getAllCategories();

    return categories;
  } catch (e, stackTrace) {
    // Handle authentication errors centrally
    if (AuthErrorHandler.isAuthError(e)) {
      // CRITICAL FIX: Do NOT invalidate authNotifierProvider - it resets state to Initial
      // causing navigation loops. Instead, call logout() which properly transitions to Unauthenticated.
      // Only logout if we're currently authenticated (don't logout if already unauthenticated)
      final currentAuthState = ref.read(authNotifierProvider);
      if (currentAuthState is AuthStateAuthenticated) {
        Future.microtask(() {
          ref.read(authNotifierProvider.notifier).logout();
        });
      }

      return AuthErrorHandler.handleAuthError<List<CategoryModel>>(
        e,
        stackTrace,
        tag: 'CategoriesProvider',
      );
    }

    // For other errors, re-throw to show error state in UI
    throw Exception(
      'Failed to load categories: ${AuthErrorHandler.extractErrorMessage(e)}',
    );
  }
});
