#!/bin/bash
# Build Whistype and deploy to /Applications
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Whistype"
DEST="/Applications/${APP_NAME}.app"

echo "Building ${APP_NAME}..."
xcodebuild -project "${PROJECT_DIR}/${APP_NAME}.xcodeproj" \
    -scheme "${APP_NAME}" \
    -destination "platform=macOS" \
    -configuration Debug \
    build -quiet

BUILD_APP=$(find ~/Library/Developer/Xcode/DerivedData/${APP_NAME}-*/Build/Products/Debug/${APP_NAME}.app -maxdepth 0 2>/dev/null | head -1)

if [ -z "$BUILD_APP" ]; then
    echo "Error: Build product not found"
    exit 1
fi

echo "Stopping ${APP_NAME}..."
pkill -x "${APP_NAME}" 2>/dev/null || true
sleep 1

echo "Deploying to ${DEST}..."
rm -rf "${DEST}"
cp -R "${BUILD_APP}" "${DEST}"

echo "Launching ${APP_NAME}..."
open "${DEST}"

echo "Done."
