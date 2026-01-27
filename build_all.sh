#!/bin/bash
# Build script for all desktop platforms
# Run this on macOS or Linux to build for all platforms

echo "🚀 Building PlayTorrio for all desktop platforms..."

# Windows
echo ""
echo "📦 Building for Windows..."
flutter clean
flutter build windows --release
if [ $? -eq 0 ]; then
  echo "✅ Windows build complete: build/windows/x64/runner/Release/"
else
  echo "❌ Windows build failed"
fi

# macOS
echo ""
echo "📦 Building for macOS (Universal)..."
flutter clean
flutter build macos --release
if [ $? -eq 0 ]; then
  echo "✅ macOS build complete: build/macos/Build/Products/Release/PlayTorrio.app"
else
  echo "❌ macOS build failed"
fi

# Linux
echo ""
echo "📦 Building for Linux..."
flutter clean
flutter build linux --release
if [ $? -eq 0 ]; then
  echo "✅ Linux build complete: build/linux/x64/release/bundle/"
else
  echo "❌ Linux build failed"
fi

echo ""
echo "🎉 All builds complete!"
echo ""
echo "Bundle locations:"
echo "  Windows: build/windows/x64/runner/Release/"
echo "  macOS:   build/macos/Build/Products/Release/PlayTorrio.app"
echo "  Linux:   build/linux/x64/release/bundle/"
