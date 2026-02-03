import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/secure_storage_service.dart';
import '../services/api_service.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(),
);

final apiServiceProvider = Provider<ApiService>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return ApiService(secureStorage: secureStorage);
});
