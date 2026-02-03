#!/bin/bash

# Script to generate mock files for authentication tests
# Run this before running tests

echo "🔧 Generating mock files for auth tests..."
echo ""

cd "$(dirname "$0")"

# Generate mocks using build_runner
flutter pub run build_runner build --delete-conflicting-outputs

echo ""
echo "✅ Mock files generated!"
echo ""
echo "You can now run tests with:"
echo "  flutter test test/features/auth/"
