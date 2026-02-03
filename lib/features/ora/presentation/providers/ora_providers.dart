import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_providers_v2.dart';
import '../../data/repositories/ora_repository.dart';
import '../../domain/models/ora_conversation_state.dart';
import 'ora_conversation_notifier.dart';

// Re-export offline providers for convenience
export '../../offline/providers/offline_providers.dart';
export '../../offline/offline.dart';

/// Provider for Ora repository
final oraRepositoryProvider = Provider<OraRepository>((ref) {
  final apiService = ref.watch(apiServiceV2Provider);
  return OraRepositoryImpl(apiService);
});

/// Provider for Ora conversation state
final oraConversationProvider = StateNotifierProvider.autoDispose<
    OraConversationNotifier, OraConversationState>((ref) {
  final repository = ref.watch(oraRepositoryProvider);
  return OraConversationNotifier(repository: repository);
});
