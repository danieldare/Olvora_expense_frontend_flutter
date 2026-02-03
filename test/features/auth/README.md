# Authentication Tests

## Quick Start

1. **Generate Mock Files:**
   ```bash
   cd frontend_flutter_main
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Run Tests:**
   ```bash
   # All auth tests
   flutter test test/features/auth/
   
   # Specific test file
   flutter test test/features/auth/presentation/notifiers/auth_notifier_test.dart
   ```

## Test Structure

- `presentation/notifiers/auth_notifier_test.dart` - Tests for AuthNotifier state management
- `data/repositories/auth_repository_impl_test.dart` - Tests for repository layer
- `integration/auth_flow_integration_test.dart` - End-to-end flow tests

## Note

The test files use `@GenerateMocks` annotations. You must run `build_runner` to generate the mock files before running tests. The mock files will be generated in the same directory as the test files with `.mocks.dart` extension.
