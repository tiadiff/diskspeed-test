#!/bin/bash

APP_NAME="SSDSpeedTestWin"
PROJECT_DIR="windows/SSDSpeedTestWin"
OUTPUT_DIR="publish_windows"

echo "Cleanup..."
rm -rf "$OUTPUT_DIR"

echo "Building Windows Executable (win-x64)..."
dotnet publish "$PROJECT_DIR/$APP_NAME.csproj" \
    -c Release \
    -r win-x64 \
    --self-contained true \
    -p:PublishSingleFile=true \
    -p:EnableWindowsTargeting=true \
    -o "$OUTPUT_DIR"

echo "Build complete! The executable is located in the '$OUTPUT_DIR' directory."
ls -lh "$OUTPUT_DIR"
