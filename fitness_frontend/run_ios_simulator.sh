#!/bin/bash
# Helper script to run fitness_frontend on iOS simulator
# This works around the code signing issues on macOS

set -e

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

echo "🏗️  Building for iOS Simulator..."

cd "$(dirname "$0")"

# Clean previous build
rm -rf build/ios

# Run pod install first
echo "📦 Installing CocoaPods dependencies..."
cd ios
export LANG=en_US.UTF-8
pod install
cd ..
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  CODE_SIGNING_ALLOWED=NO \
  | grep -v "^$" || true

cd ..

echo "✅ Build completed!"
echo ""
echo "📱 Installing and launching app on simulator..."

# Get the simulator ID - use the iOS 18.5 one
SIM_ID="1A1849A9-FFC3-4F4D-80A0-CBA15D5B9983"

if [ -z "$SIM_ID" ]; then
    echo "❌ iPhone 16 Pro simulator not found!"
    echo "Available simulators:"
    xcrun simctl list devices | grep iPhone
    exit 1
fi

echo "Using simulator: $SIM_ID"

# Boot simulator if not already running
xcrun simctl boot "$SIM_ID" 2>/dev/null || true
sleep 2

# Open Simulator app
open -a Simulator

# Uninstall old version if exists
xcrun simctl uninstall "$SIM_ID" com.example.fitnessFrontend 2>/dev/null || true

# Find the actual build location (excluding Index.noindex)
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Runner.app" -path "*/Debug-iphonesimulator/*" -type d | grep -v "Index.noindex" | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Could not find Runner.app!"
    exit 1
fi

echo "App found at: $APP_PATH"

# Install the app
xcrun simctl install "$SIM_ID" "$APP_PATH"

echo ""
echo "🚀 Launching app..."

# Launch the app
xcrun simctl launch --console "$SIM_ID" com.example.fitnessFrontend

echo ""
echo "✅ App is running on iOS Simulator!"
echo ""
echo "Press Ctrl+C to stop watching logs"
echo "To rebuild and rerun, just run this script again"

