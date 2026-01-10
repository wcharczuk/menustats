#!/bin/bash

set -e

APP_NAME="MenuStats"
BUILD_DIR=".build/release"
BUNDLE_DIR="$BUILD_DIR/$APP_NAME.app"
INSTALL_DIR="/Applications"

# Check if built app exists
if [ ! -d "$BUNDLE_DIR" ]; then
    echo "Error: App bundle not found at $BUNDLE_DIR"
    echo "Run ./build.sh first to build the app."
    exit 1
fi

echo "Installing $APP_NAME to $INSTALL_DIR..."

# Quit running instance
pkill -f "$APP_NAME" 2>/dev/null || true
sleep 0.5

# Remove existing installation
rm -rf "$INSTALL_DIR/$APP_NAME.app"

# Copy new build
cp -r "$BUNDLE_DIR" "$INSTALL_DIR/"

echo "Installed to $INSTALL_DIR/$APP_NAME.app"

# Launch the app
echo "Launching $APP_NAME..."
open "$INSTALL_DIR/$APP_NAME.app"
