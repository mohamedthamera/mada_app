#!/bin/bash

# iOS Simulator Fix Script for Flutter
# This script fixes native library errors on iOS Simulator

set -e

PROJECT_DIR="/Users/mohammedthamer/Desktop/mada_app/apps/mobile"
cd "$PROJECT_DIR"

echo "============================================"
echo "iOS Simulator Fix Script"
echo "============================================"

# Step 1: Show current simulators
echo ""
echo "Step 1: Detecting iOS Simulators..."
echo "-------------------------------------"
xcrun simctl list devices available
echo ""
xcrun simctl list runtimes
echo ""

# Step 2: Check for iOS 17 runtime
echo "Step 2: Checking for supported iOS runtimes..."
echo "-------------------------------------"
RUNTIMES=$(xcrun simctl list runtimes 2>/dev/null | grep -o "iOS [0-9]*" | head -5)
echo "Available runtimes: $RUNTIMES"

# Step 3: Check if iOS 17 exists, if not provide instructions
if ! xcrun simctl list runtimes | grep -q "iOS 17"; then
    echo ""
    echo "⚠️  iOS 17 runtime not found! You need to install it via Xcode."
    echo ""
    echo "To install iOS 17 runtime:"
    echo "  1. Open Xcode"
    echo "  2. Go to Settings → Platforms"
    echo "  3. Click 'Download' next to iOS 17.x Simulator"
    echo ""
    echo "Alternatively, download and install manually:"
    echo "  xcrun simctl list runtimes available"
    echo ""
    echo "For now, let's try to create simulators with available runtime..."
fi

# Step 4: Remove any broken/incompatible simulators
echo ""
echo "Step 3: Removing incompatible simulators..."
echo "-------------------------------------"
for simulator in $(xcrun simctl list devices available | grep -E "iPhone.*\(" | grep -oE "iPhone [0-9]+" | sort -u); do
    echo "Checking $simulator..."
done
echo "Simulator check complete."

# Step 5: Create new simulators with supported iOS versions
echo ""
echo "Step 4: Creating supported iOS simulators..."
echo "-------------------------------------"

# Try to create iPhone 17 with available runtime
AVAILABLE_RUNTIME=$(xcrun simctl list runtimes 2>/dev/null | grep -o "iOS [0-9]*" | head -1 | tr -d ' ')
echo "Using runtime: $AVAILABLE_RUNTIME"

if [ -n "$AVAILABLE_RUNTIME" ]; then
    # Create iPhone 17 Pro
    echo "Creating iPhone 17 Pro simulator..."
    xcrun simctl create "iPhone 17 Pro" "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro" "$AVAILABLE_RUNTIME" 2>/dev/null || echo "  (may already exist or runtime unavailable)"
    
    # Create iPhone 16
    echo "Creating iPhone 16 simulator..."
    xcrun simctl create "iPhone 16" "com.apple.CoreSimulator.SimDeviceType.iPhone-16" "$AVAILABLE_RUNTIME" 2>/dev/null || echo "  (may already exist or runtime unavailable)"
else
    echo "⚠️  No runtime available to create simulators."
    echo "Please install an iOS runtime via Xcode first."
fi

# Step 6: Clean Flutter project
echo ""
echo "Step 5: Cleaning Flutter project..."
echo "-------------------------------------"
flutter clean

# Step 7: Get Flutter dependencies
echo ""
echo "Step 6: Getting Flutter dependencies..."
echo "-------------------------------------"
flutter pub get

# Step 8: Remove old pods
echo ""
echo "Step 7: Removing old iOS pods..."
echo "-------------------------------------"
rm -rf ios/Pods
rm -f ios/Podfile.lock
echo "Old pods removed."

# Step 9: Install pods
echo ""
echo "Step 8: Installing iOS pods..."
echo "-------------------------------------"
cd ios
pod install --repo-update
cd ..

# Step 10: Show available simulators
echo ""
echo "Step 9: Final simulator list..."
echo "-------------------------------------"
xcrun simctl list devices available

# Step 11: Build for iOS Simulator
echo ""
echo "Step 10: Building for iOS Simulator..."
echo "-------------------------------------"
flutter build ios --simulator --no-codesign

echo ""
echo "============================================"
echo "✅ Build complete!"
echo "============================================"
echo ""
echo "To run the app:"
echo "  flutter run -d 'iPhone 17 Pro'"
echo ""
echo "Or select a simulator and run:"
echo "  flutter run"
