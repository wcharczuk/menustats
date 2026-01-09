#!/bin/bash

set -e

echo "Building MenuStats release binary..."

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
echo "  cp -r \"$BUNDLE_DIR\" /Applications/"
echo ""
echo "Or drag the app from the following location to /Applications:"
echo "  $(pwd)/$BUNDLE_DIR"
echo ""
echo "To open the build folder in Finder:"
echo "  open \"$BUILD_DIR\""
echo ""
