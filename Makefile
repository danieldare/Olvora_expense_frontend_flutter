# ═══════════════════════════════════════════════════════════════════════════
# OLVORA EXPENSE APP - BUILD COMMANDS
# ═══════════════════════════════════════════════════════════════════════════
# Usage: make <command>
# Run `make help` to see all available commands
# ═══════════════════════════════════════════════════════════════════════════

.PHONY: help dev build clean setup test analyze format

# Default target
help:
	@echo "═══════════════════════════════════════════════════════════════"
	@echo "  OLVORA - Available Commands"
	@echo "═══════════════════════════════════════════════════════════════"
	@echo ""
	@echo "  Development:"
	@echo "    make dev              Run app in debug mode"
	@echo "    make dev-ios          Run on iOS simulator"
	@echo "    make dev-android      Run on Android emulator"
	@echo "    make fresh-install-ios         Fresh install on iOS (resets permissions)"
	@echo "    make fresh-install-android     Fresh install on Android (resets permissions)"
	@echo "    make fresh-install DEVICE=<id> Fresh install on specific device"
	@echo "    make reset-permissions         Guide to reset app permissions"
	@echo ""
	@echo "  Build (Release):"
	@echo "    make build            Build release APK"
	@echo "    make build-apk        Build split APKs (arm64, armv7a, x86_64)"
	@echo "    make build-aab        Build App Bundle for Play Store"
	@echo "    make build-ios        Build iOS release"
	@echo ""
	@echo "  Build (Production):"
	@echo "    make build-prod-apk   Production APK with obfuscation"
	@echo "    make build-prod-aab   Production AAB with obfuscation"
	@echo "    make build-prod-ios   Production iOS with obfuscation"
	@echo ""
	@echo "  Analysis:"
	@echo "    make analyze          Run Flutter analyzer"
	@echo "    make lint             Run linter (non-fatal)"
	@echo "    make size             Analyze APK size"
	@echo "    make format           Format code"
	@echo ""
	@echo "  Maintenance:"
	@echo "    make setup            Get dependencies"
	@echo "    make clean            Clean build artifacts"
	@echo "    make reset            Clean + setup"
	@echo "    make pods             Update iOS CocoaPods"
	@echo ""
	@echo "  Testing:"
	@echo "    make test             Run all tests"
	@echo "    make test-coverage    Run tests with coverage"
	@echo ""
	@echo "═══════════════════════════════════════════════════════════════"

# ─────────────────────────────────────────────────────────────────────────────
# DEVELOPMENT
# ─────────────────────────────────────────────────────────────────────────────

dev:
	flutter run

dev-ios:
	flutter run -d ios

dev-android:
	flutter run -d android

dev-web:
	flutter run -d chrome

# Fresh install - uninstalls and reinstalls app (resets all permissions)
fresh-install-ios: clean
	@echo "🗑️  Uninstalling app from iOS device..."
	flutter install --uninstall-only -d ios || true
	@echo "📦 Installing fresh build on iOS..."
	flutter run -d ios

fresh-install-android: clean
	@echo "🗑️  Uninstalling app from Android device..."
	flutter install --uninstall-only -d android || true
	@echo "📦 Installing fresh build on Android..."
	flutter run -d android

# Fresh install on specific device by ID
# Usage: make fresh-install DEVICE=<device-id>
# Example: make fresh-install DEVICE=00008030-001E64D03C38802E
fresh-install: clean
ifndef DEVICE
	@echo "❌ Error: DEVICE not specified"
	@echo "Usage: make fresh-install DEVICE=<device-id>"
	@echo ""
	@echo "Available devices:"
	@flutter devices
	@exit 1
endif
	@echo "🗑️  Uninstalling app from device $(DEVICE)..."
	flutter install --uninstall-only -d $(DEVICE) || true
	@echo "📦 Installing fresh build on device $(DEVICE)..."
	flutter run -d $(DEVICE)

# Show guide for resetting permissions
reset-permissions:
	@echo "═══════════════════════════════════════════════════════════════"
	@echo "  HOW TO RESET APP PERMISSIONS"
	@echo "═══════════════════════════════════════════════════════════════"
	@echo ""
	@echo "OPTION 1: Fresh Install (Recommended)"
	@echo "  This completely removes the app and reinstalls it fresh."
	@echo ""
	@echo "  For iOS:"
	@echo "    make fresh-install DEVICE=<your-device-id>"
	@echo ""
	@echo "  Example:"
	@echo "    make fresh-install DEVICE=00008130-0014752A0843401C"
	@echo ""
	@echo "OPTION 2: Manual Reset (iOS)"
	@echo "  1. Open Settings app on your iPhone"
	@echo "  2. Scroll down and find 'Olvora Expense'"
	@echo "  3. Tap on it"
	@echo "  4. Enable 'Microphone' toggle"
	@echo "  5. Return to the app and try again"
	@echo ""
	@echo "OPTION 3: Delete and Reinstall Manually"
	@echo "  1. Long-press the app icon on your iPhone"
	@echo "  2. Tap 'Remove App' > 'Delete App'"
	@echo "  3. Run: flutter run -d <device-id>"
	@echo ""
	@echo "═══════════════════════════════════════════════════════════════"
	@echo ""
	@echo "To see connected devices, run: flutter devices"
	@echo ""

# ─────────────────────────────────────────────────────────────────────────────
# BUILD (RELEASE)
# ─────────────────────────────────────────────────────────────────────────────

build:
	flutter build apk --release --tree-shake-icons

build-apk:
	flutter build apk --release --tree-shake-icons --split-per-abi

build-apk-arm64:
	flutter build apk --release --tree-shake-icons --target-platform=android-arm64

build-aab:
	flutter build appbundle --release --tree-shake-icons

build-ios:
	flutter build ios --release --tree-shake-icons

# ─────────────────────────────────────────────────────────────────────────────
# BUILD (PRODUCTION - with obfuscation)
# ─────────────────────────────────────────────────────────────────────────────

# NOTE: Set API_BASE_URL for production builds:
# make build-prod-apk API_URL=https://your-api.com/api

API_URL ?= http://192.168.100.15:4000/api

build-prod-apk:
	flutter build apk --release \
		--obfuscate \
		--split-debug-info=build/debug-info \
		--tree-shake-icons \
		--split-per-abi \
		--dart-define=API_BASE_URL=$(API_URL) \
		--dart-define=FLUTTER_ENV=production

build-prod-aab:
	flutter build appbundle --release \
		--obfuscate \
		--split-debug-info=build/debug-info \
		--tree-shake-icons \
		--dart-define=API_BASE_URL=$(API_URL) \
		--dart-define=FLUTTER_ENV=production

build-prod-ios:
	flutter build ios --release \
		--obfuscate \
		--split-debug-info=build/debug-info \
		--tree-shake-icons \
		--dart-define=API_BASE_URL=$(API_URL) \
		--dart-define=FLUTTER_ENV=production

# ─────────────────────────────────────────────────────────────────────────────
# BUILD (OPTIMIZED - via script)
# ─────────────────────────────────────────────────────────────────────────────

build-optimized:
	./scripts/build_release.sh android

build-optimized-ios:
	./scripts/build_release.sh ios

build-optimized-all:
	./scripts/build_release.sh all

# ─────────────────────────────────────────────────────────────────────────────
# CLEAN & SETUP
# ─────────────────────────────────────────────────────────────────────────────

setup:
	flutter pub get

clean:
	flutter clean
	rm -rf build/

reset: clean setup

pods:
	cd ios && pod install --repo-update

pods-clean:
	cd ios && rm -rf Pods Podfile.lock && pod install --repo-update

# ─────────────────────────────────────────────────────────────────────────────
# ANALYSIS
# ─────────────────────────────────────────────────────────────────────────────

analyze:
	flutter analyze

lint:
	flutter analyze --no-fatal-infos --no-fatal-warnings

format:
	dart format lib/ test/

format-check:
	dart format --set-exit-if-changed lib/ test/

# ─────────────────────────────────────────────────────────────────────────────
# SIZE ANALYSIS
# ─────────────────────────────────────────────────────────────────────────────

size:
	flutter build apk --release --analyze-size --target-platform=android-arm64

size-ios:
	flutter build ios --release --analyze-size

# ─────────────────────────────────────────────────────────────────────────────
# TESTING
# ─────────────────────────────────────────────────────────────────────────────

test:
	flutter test

test-coverage:
	flutter test --coverage

test-watch:
	flutter test --watch

# ─────────────────────────────────────────────────────────────────────────────
# UTILITIES
# ─────────────────────────────────────────────────────────────────────────────

gen:
	dart run build_runner build --delete-conflicting-outputs

gen-watch:
	dart run build_runner watch --delete-conflicting-outputs

outdated:
	flutter pub outdated

upgrade:
	flutter pub upgrade

# ─────────────────────────────────────────────────────────────────────────────
# RELEASE WORKFLOW
# ─────────────────────────────────────────────────────────────────────────────

prerelease: clean setup analyze test

release-android: prerelease build-prod-aab
	@echo "✅ Android release ready: build/app/outputs/bundle/release/app-release.aab"

release-ios: prerelease build-prod-ios
	@echo "✅ iOS release ready - open Xcode to archive"

