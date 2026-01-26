#!/bin/bash
# Build and install TimeFlow Android APK
# Usage: ./scripts/build_android.sh [--release] [--no-install]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Parse arguments
BUILD_TYPE="debug"
DO_INSTALL=true

for arg in "$@"; do
    case $arg in
        --release)
            BUILD_TYPE="release"
            ;;
        --no-install)
            DO_INSTALL=false
            ;;
    esac
done

echo "========================================"
echo "  TimeFlow Android Build Script"
echo "========================================"
echo ""

# Step 1: Generate build info
echo "📝 Generating build info..."
./scripts/generate_build_info.sh
echo ""

# Step 2: Get dependencies
echo "📦 Getting dependencies..."
flutter pub get
echo ""

# Step 3: Generate drift code (if needed)
echo "🔧 Generating drift database code..."
flutter pub run build_runner build --delete-conflicting-outputs
echo ""

# Step 4: Build APK
echo "🏗️  Building $BUILD_TYPE APK..."
flutter build apk --$BUILD_TYPE
echo ""

APK_PATH="build/app/outputs/flutter-apk/app-$BUILD_TYPE.apk"

if [ ! -f "$APK_PATH" ]; then
    echo "❌ Build failed - APK not found at $APK_PATH"
    exit 1
fi

echo "✅ APK built: $APK_PATH"
echo ""

# Step 5: Install (if requested and device connected)
if [ "$DO_INSTALL" = true ]; then
    echo "📱 Checking for connected devices..."

    if ! command -v adb &> /dev/null; then
        echo "⚠️  ADB not found - skipping install"
        echo "   Install manually: adb install $APK_PATH"
        exit 0
    fi

    DEVICES=$(adb devices | grep -v "List" | grep "device$" | wc -l)

    if [ "$DEVICES" -eq 0 ]; then
        echo "⚠️  No devices connected - skipping install"
        echo "   Install manually: adb install $APK_PATH"
        exit 0
    fi

    echo "📲 Uninstalling old version (if exists)..."
    adb uninstall com.rinserepeatlabs.timeflow 2>/dev/null || true

    echo "📲 Installing new APK..."
    adb install "$APK_PATH"

    echo ""
    echo "✅ Done! TimeFlow installed on device."
    echo ""
    echo "🚀 Launching app..."
    adb shell am start -n com.rinserepeatlabs.timeflow/.MainActivity 2>/dev/null || true
else
    echo "📁 APK ready at: $APK_PATH"
fi

echo ""
echo "========================================"
echo "  Build complete!"
echo "========================================"
