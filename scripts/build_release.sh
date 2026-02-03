#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
# OLVORA EXPENSE APP - OPTIMIZED RELEASE BUILD SCRIPT
# ═══════════════════════════════════════════════════════════════════════════
# 
# This script builds optimized release versions of the app with:
# - Tree shaking enabled
# - Code shrinking (R8/ProGuard)
# - ABI splits for Android
# - Symbol stripping
# - Deferred components (if configured)
#
# Usage:
#   ./scripts/build_release.sh android    # Build Android APK/AAB
#   ./scripts/build_release.sh ios        # Build iOS IPA
#   ./scripts/build_release.sh all        # Build both platforms
#   ./scripts/build_release.sh analyze    # Analyze bundle size
# ═══════════════════════════════════════════════════════════════════════════

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Navigate to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}     OLVORA - OPTIMIZED RELEASE BUILD${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Clean previous builds
clean_build() {
    echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
    flutter clean
    rm -rf build/
    echo -e "${GREEN}✓ Clean complete${NC}"
}

# Get dependencies
get_deps() {
    echo -e "${YELLOW}📦 Getting dependencies...${NC}"
    flutter pub get
    echo -e "${GREEN}✓ Dependencies installed${NC}"
}

# Build Android
build_android() {
    echo ""
    echo -e "${BLUE}📱 Building Android Release...${NC}"
    echo ""
    
    # Build App Bundle (recommended for Play Store)
    echo -e "${YELLOW}Building App Bundle (AAB)...${NC}"
    flutter build appbundle \
        --release \
        --obfuscate \
        --split-debug-info=build/debug-info/android \
        --tree-shake-icons
    
    echo ""
    echo -e "${YELLOW}Building Split APKs...${NC}"
    flutter build apk \
        --release \
        --obfuscate \
        --split-debug-info=build/debug-info/android \
        --tree-shake-icons \
        --split-per-abi
    
    echo ""
    echo -e "${GREEN}✓ Android build complete${NC}"
    echo ""
    echo -e "  ${BLUE}App Bundle:${NC} build/app/outputs/bundle/release/app-release.aab"
    echo -e "  ${BLUE}APKs:${NC}"
    ls -lh build/app/outputs/flutter-apk/*.apk 2>/dev/null | awk '{print "    " $9 " (" $5 ")"}'
}

# Build iOS
build_ios() {
    echo ""
    echo -e "${BLUE}🍎 Building iOS Release...${NC}"
    echo ""
    
    # Update pods
    echo -e "${YELLOW}Updating CocoaPods...${NC}"
    cd ios && pod install --repo-update && cd ..
    
    # Build iOS
    flutter build ios \
        --release \
        --obfuscate \
        --split-debug-info=build/debug-info/ios \
        --tree-shake-icons
    
    echo ""
    echo -e "${GREEN}✓ iOS build complete${NC}"
    echo -e "  ${BLUE}Archive:${NC} Open Xcode to archive and distribute"
}

# Analyze bundle size
analyze_size() {
    echo ""
    echo -e "${BLUE}📊 Analyzing Bundle Size...${NC}"
    echo ""
    
    # Build with size analysis
    flutter build apk \
        --release \
        --analyze-size \
        --target-platform=android-arm64
    
    echo ""
    echo -e "${GREEN}✓ Size analysis complete${NC}"
    echo -e "  ${BLUE}View detailed analysis in DevTools${NC}"
}

# Main execution
case "$1" in
    "android")
        clean_build
        get_deps
        build_android
        ;;
    "ios")
        clean_build
        get_deps
        build_ios
        ;;
    "all")
        clean_build
        get_deps
        build_android
        build_ios
        ;;
    "analyze")
        analyze_size
        ;;
    "quick-android")
        # Skip clean for faster builds during development
        get_deps
        build_android
        ;;
    *)
        echo "Usage: $0 {android|ios|all|analyze|quick-android}"
        echo ""
        echo "Commands:"
        echo "  android       Build optimized Android APK/AAB"
        echo "  ios           Build optimized iOS archive"
        echo "  all           Build both platforms"
        echo "  analyze       Analyze bundle size"
        echo "  quick-android Quick Android build (no clean)"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}     BUILD COMPLETE${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"

