#!/bin/bash

APP_NAME="SSDSpeedTest"
BUNDLE_ID="com.tiadiff.ssdspeedtest"
BUILD_DIR=".build_app"
SOURCES="Sources/SpeedTestApp.swift Sources/ContentView.swift Sources/DiskSpeedTester.swift"

echo "Cleanup..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/$APP_NAME.app/Contents/MacOS"
mkdir -p "$BUILD_DIR/$APP_NAME.app/Contents/Resources"

echo "Compiling..."
# Using -sdk macosx and -target to ensure correct architecture/version
swiftc -o "$BUILD_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME" \
    -sdk "$(xcrun --show-sdk-path --sdk macosx)" \
    -target "x86_64-apple-macosx13.0" \
    -O -parse-as-library $SOURCES

echo "Creating Info.plist..."
cat <<EOF > "$BUILD_DIR/$APP_NAME.app/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

echo "App built at $BUILD_DIR/$APP_NAME.app"
rm -rf "./$APP_NAME.app"
mv "$BUILD_DIR/$APP_NAME.app" ./
rm -rf "$BUILD_DIR"
