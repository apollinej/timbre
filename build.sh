#!/bin/bash
set -euo pipefail

# timbre build script
# Builds the Swift package and creates a macOS .app bundle.
#
# Usage:
#   ./build.sh              # debug build
#   ./build.sh release      # optimized release build
#   ./build.sh install      # build + copy to /Applications
#   ./build.sh clean        # remove build artifacts

APP_NAME="Timbre"
BUNDLE_ID="com.timbre.app"
DISPLAY_NAME="timbre"
MIN_MACOS="14.0"
ICON_FILE="timbre icon.png"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Read semver from VERSION file (single source of truth).
# Falls back to 0.0.0 if missing — a real release should always have one.
if [[ -f "$SCRIPT_DIR/VERSION" ]]; then
    APP_VERSION="$(cat "$SCRIPT_DIR/VERSION" | tr -d '[:space:]')"
else
    APP_VERSION="0.0.0"
fi

BUILD_CONFIG="debug"
INSTALL=false
if [[ "${1:-}" == "release" ]]; then
    BUILD_CONFIG="release"
elif [[ "${1:-}" == "install" ]]; then
    BUILD_CONFIG="release"
    INSTALL=true
elif [[ "${1:-}" == "clean" ]]; then
    echo "Cleaning build artifacts..."
    swift package clean
    rm -rf "$SCRIPT_DIR/$APP_NAME.app"
    echo "Done."
    exit 0
fi

echo "Building $DISPLAY_NAME ($BUILD_CONFIG)..."

if [[ "$BUILD_CONFIG" == "release" ]]; then
    swift build -c release 2>&1
else
    swift build 2>&1
fi

echo "Creating .app bundle..."

APP_DIR="$SCRIPT_DIR/$APP_NAME.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp ".build/$BUILD_CONFIG/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"

# Copy resource bundle (fonts, etc.)
# SPM's Bundle.module accessor looks at Bundle.main.bundleURL (the .app root),
# not Contents/Resources/, so place it at the app root.
BUNDLE_PATH=$(find ".build/$BUILD_CONFIG/" -name "Timbre_Timbre.bundle" -type d 2>/dev/null | head -1)
if [[ -n "$BUNDLE_PATH" ]]; then
    cp -R "$BUNDLE_PATH" "$APP_DIR/Timbre_Timbre.bundle"
fi

# Create Info.plist
cat > "$APP_DIR/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$DISPLAY_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$DISPLAY_NAME</string>
    <key>CFBundleVersion</key>
    <string>$APP_VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$APP_VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>$MIN_MACOS</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>timbre needs microphone access to record audio.</string>
    <key>ATSApplicationFontsPath</key>
    <string>Timbre_Timbre.bundle</string>
</dict>
</plist>
PLIST

# Create .icns from icon image if available
if [[ -f "$ICON_FILE" ]]; then
    ICONSET="$APP_DIR/Contents/Resources/AppIcon.iconset"
    mkdir -p "$ICONSET"
    for size in 16 32 64 128 256 512; do
        sips -z "$size" "$size" "$ICON_FILE" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null 2>&1
        double=$((size * 2))
        sips -z "$double" "$double" "$ICON_FILE" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null 2>&1
    done
    iconutil -c icns "$ICONSET" -o "$APP_DIR/Contents/Resources/AppIcon.icns" 2>/dev/null
    rm -rf "$ICONSET"
    echo "App icon created from $ICON_FILE"
else
    echo "No icon file found ($ICON_FILE). App will use default icon."
fi

echo ""
echo "✓ $DISPLAY_NAME.app built at: $APP_DIR"

if $INSTALL; then
    echo "Installing to /Applications..."
    rm -rf "/Applications/$APP_NAME.app"
    cp -R "$APP_DIR" "/Applications/$APP_NAME.app"
    echo "✓ Installed to /Applications/$APP_NAME.app"
fi

echo ""
echo "Run with:  open $APP_DIR"
echo "  or:      ./$APP_NAME.app/Contents/MacOS/$APP_NAME"
