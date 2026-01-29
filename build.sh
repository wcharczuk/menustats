#!/bin/bash

set -e

echo "Building MenuStats release binary..."

# Clean previous build to ensure fresh compilation
echo "Cleaning previous build..."
swift package clean 2>/dev/null || true
rm -rf .build

# Build release configuration
swift build -c release

# Create app bundle structure
APP_NAME="MenuStats"
APP_BUNDLE="$APP_NAME.app"
BUILD_DIR=".build/release"
BUNDLE_DIR="$BUILD_DIR/$APP_BUNDLE"

echo "Creating app bundle..."

# Remove existing bundle if present
rm -rf "$BUNDLE_DIR"

# Create bundle structure
mkdir -p "$BUNDLE_DIR/Contents/MacOS"
mkdir -p "$BUNDLE_DIR/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/$APP_NAME" "$BUNDLE_DIR/Contents/MacOS/"

# Generate app icon
echo "Generating app icon..."
ICONSET_DIR="Sources/MenuStats/Resources/Assets.xcassets/AppIcon.appiconset"
ICONSET_TEMP=".build/AppIcon.iconset"
rm -rf "$ICONSET_TEMP"
mkdir -p "$ICONSET_TEMP"
cp "$ICONSET_DIR"/icon_16x16.png "$ICONSET_TEMP/icon_16x16.png"
cp "$ICONSET_DIR"/icon_16x16@2x.png "$ICONSET_TEMP/icon_16x16@2x.png"
cp "$ICONSET_DIR"/icon_32x32.png "$ICONSET_TEMP/icon_32x32.png"
cp "$ICONSET_DIR"/icon_32x32@2x.png "$ICONSET_TEMP/icon_32x32@2x.png"
cp "$ICONSET_DIR"/icon_128x128.png "$ICONSET_TEMP/icon_128x128.png"
cp "$ICONSET_DIR"/icon_128x128@2x.png "$ICONSET_TEMP/icon_128x128@2x.png"
cp "$ICONSET_DIR"/icon_256x256.png "$ICONSET_TEMP/icon_256x256.png"
cp "$ICONSET_DIR"/icon_256x256@2x.png "$ICONSET_TEMP/icon_256x256@2x.png"
cp "$ICONSET_DIR"/icon_512x512.png "$ICONSET_TEMP/icon_512x512.png"
cp "$ICONSET_DIR"/icon_512x512@2x.png "$ICONSET_TEMP/icon_512x512@2x.png"
iconutil -c icns "$ICONSET_TEMP" -o "$BUNDLE_DIR/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET_TEMP"

# Create Info.plist
cat > "$BUNDLE_DIR/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>MenuStats</string>
    <key>CFBundleIdentifier</key>
    <string>com.menustats.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleName</key>
    <string>MenuStats</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Sign the app (ad-hoc signing for local use)
echo "Signing app bundle..."
codesign --force --deep --sign - "$BUNDLE_DIR"

echo ""
echo "=========================================="
echo "Build complete!"
echo "=========================================="
echo ""
echo "App bundle created at:"
echo "  $BUNDLE_DIR"
echo ""
echo "To install, run:"
echo "  ./install.sh"
