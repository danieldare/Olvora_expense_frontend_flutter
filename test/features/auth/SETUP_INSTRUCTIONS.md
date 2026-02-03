# Auth Tests Setup Instructions

## ⚠️ IMPORTANT: Generate Mocks First!

Before running the auth tests, you **must** generate the mock files using `build_runner`.

## Quick Setup

### Option 1: Use the Script (Recommended)

```bash
cd frontend_flutter_main
./generate_test_mocks.sh
```

### Option 2: Manual Generation

```bash
cd frontend_flutter_main
flutter pub run build_runner build --delete-conflicting-outputs
```

## What This Does

The `build_runner` command generates mock classes from the `@GenerateMocks` annotations in the test files. This creates files like:
- `test/features/auth/presentation/notifiers/auth_notifier_test.mocks.dart`
- `test/features/auth/data/repositories/auth_repository_impl_test.mocks.dart`

## Running Tests

After generating mocks, run:

```bash
# All auth tests
flutter test test/features/auth/

# Specific test file
flutter test test/features/auth/presentation/notifiers/auth_notifier_test.dart

# With coverage
flutter test --coverage test/features/auth/
```

## Troubleshooting

### Error: "No such file or directory: *.mocks.dart"
**Solution:** Run `build_runner` to generate the mock files.

### Error: "Mock classes not found"
**Solution:** Make sure you've run `build_runner` and the `.mocks.dart` files exist in the same directory as the test files.

### Error: "build_runner fails"
**Solution:** 
1. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter pub run build_runner clean
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. If still failing, check that `mockito` and `build_runner` are in `dev_dependencies` in `pubspec.yaml`

## Test Structure

- **Unit Tests:** Test individual components in isolation
- **Integration Tests:** Test complete flows (require Firebase emulator setup)

## Next Steps

1. ✅ Generate mocks (run `build_runner`)
2. ✅ Run unit tests
3. ⏭️ Set up Firebase emulator for integration tests (optional)
