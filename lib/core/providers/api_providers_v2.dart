import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/token_manager_service.dart';
import '../services/api_service_v2.dart';

/// Token manager provider (singleton)
/// CRITICAL: Must be a singleton to ensure token cache is shared across all API calls
final tokenManagerServiceProvider = Provider<TokenManagerService>(
  (ref) {
    // Create singleton instance - Riverpod will cache this
    return TokenManagerService();
  },
);

/// Auth storage provider for syncing session clearing
/// Uses same storage config as AuthLocalDataSource to access 'auth_session' key
final authStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
});

/// Enhanced API service provider with token management
/// CRITICAL: Injects authStorage to sync session clearing with token clearing
final apiServiceV2Provider = Provider<ApiServiceV2>((ref) {
  final tokenManager = ref.watch(tokenManagerServiceProvider);
  final authStorage = ref.watch(authStorageProvider);
  return ApiServiceV2(
    tokenManager: tokenManager,
    authStorage: authStorage,
  );
});
