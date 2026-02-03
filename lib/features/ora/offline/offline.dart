// Ora Offline System
//
// A world-class offline-first architecture using Isar database
//
// Features:
// - Query offline expenses without loading everything
// - Real-time UI updates via watch collections
// - Financial data encrypted at rest
// - Bulk operations for efficient sync
// - Future-proof for attachments, receipt images, etc.
//
// Usage:
// ```dart
// // In main.dart, initialize before runApp
// final container = ProviderContainer();
// await container.read(initializeOfflineSystemProvider.future);
//
// // In widgets, use providers
// final syncStatus = ref.watch(syncStatusProvider);
// final expenses = ref.watch(userExpensesProvider(userId));
// ```

// Schemas
export 'schemas/offline_message.dart';
export 'schemas/offline_expense.dart';
export 'schemas/sync_metadata.dart';

// Services
export 'services/isar_service.dart';
export 'services/offline_repository.dart';
export 'services/sync_engine.dart';

// Providers
export 'providers/offline_providers.dart';
