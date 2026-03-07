#!/bin/bash
# Build, sign, package, notarize, staple, and upload Whistype for distribution
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Whistype"
SCHEME="${APP_NAME}"
TEAM_ID="3426FSU868"
IDENTITY="Developer ID Application"
VERSION=$(grep 'MARKETING_VERSION' "${PROJECT_DIR}/project.yml" | head -1 | sed 's/.*"\(.*\)"/\1/')
BUILD_DIR="${PROJECT_DIR}/build"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"
EXPORT_DIR="${BUILD_DIR}/export"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_PATH="${PROJECT_DIR}/${DMG_NAME}"
KEYCHAIN_PROFILE="Whistype-Notarize"
GITHUB_TAG="v${VERSION}"

# Prefer Apple's HTTP timestamp endpoint; fall back to DigiCert if unreachable.
if curl -s --max-time 5 http://timestamp.apple.com/ts01 >/dev/null 2>&1; then
    TIMESTAMP_URL="http://timestamp.apple.com/ts01"
else
    echo "Apple timestamp server unreachable, using DigiCert"
    TIMESTAMP_URL="http://timestamp.digicert.com"
fi

echo "=== Whistype Release Build v${VERSION} ==="
echo "Timestamp server: ${TIMESTAMP_URL}"
echo ""

# Step 1: Clean build directory
echo "--- Step 1: Cleaning build directory ---"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Step 2: Archive with Release configuration
# Override signing to use Developer ID (project defaults to Apple Development)
echo "--- Step 2: Archiving (Release config) ---"
xcodebuild archive \
    -project "${PROJECT_DIR}/${APP_NAME}.xcodeproj" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -archivePath "${ARCHIVE_PATH}" \
    -destination "generic/platform=macOS" \
    ARCHS=arm64 \
    CODE_SIGN_IDENTITY="${IDENTITY}" \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM="${TEAM_ID}" \
    ENABLE_HARDENED_RUNTIME=YES \
    OTHER_CODE_SIGN_FLAGS="--timestamp=${TIMESTAMP_URL}" \
    -quiet

echo "Archive created at: ${ARCHIVE_PATH}"

# Step 3: Export archive
echo "--- Step 3: Exporting archive ---"
xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportOptionsPlist "${PROJECT_DIR}/ExportOptions.plist" \
    -exportPath "${EXPORT_DIR}" \
    -quiet

EXPORTED_APP="${EXPORT_DIR}/${APP_NAME}.app"
if [ ! -d "${EXPORTED_APP}" ]; then
    echo "Error: Exported app not found at ${EXPORTED_APP}"
    exit 1
fi
echo "Exported app: ${EXPORTED_APP}"

# Step 4: Verify code signing before DMG
echo "--- Step 4: Verifying code signature ---"
codesign -dvvv "${EXPORTED_APP}" 2>&1 | grep -E "Authority|TeamIdentifier|Signature"
echo ""

# Check no get-task-allow entitlement
if codesign -d --entitlements - "${EXPORTED_APP}" 2>&1 | grep -q "get-task-allow"; then
    echo "Error: get-task-allow entitlement found! This is a Debug build."
    exit 1
fi
echo "No get-task-allow entitlement (good)"

# Step 5: Create DMG
echo "--- Step 5: Creating DMG ---"
rm -f "${DMG_PATH}"

DMG_TEMP="${BUILD_DIR}/dmg-staging"
mkdir -p "${DMG_TEMP}"
cp -R "${EXPORTED_APP}" "${DMG_TEMP}/"
ln -s /Applications "${DMG_TEMP}/Applications"

hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${DMG_TEMP}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

rm -rf "${DMG_TEMP}"
echo "DMG created: ${DMG_PATH}"

# Step 6: Sign the DMG (xcodebuild does not sign DMGs)
echo "--- Step 6: Signing DMG ---"
codesign --force --sign "${IDENTITY}: Waseem Khan (${TEAM_ID})" \
    --timestamp="${TIMESTAMP_URL}" \
    "${DMG_PATH}"
echo "DMG signed"

# Step 7: Submit for notarization and wait for result
echo "--- Step 7: Notarizing (this may take a few minutes) ---"
xcrun notarytool submit "${DMG_PATH}" \
    --keychain-profile "${KEYCHAIN_PROFILE}" \
    --wait 2>&1

# Step 8: Staple the notarization ticket
echo "--- Step 8: Stapling ---"
xcrun stapler staple "${DMG_PATH}"

# Step 9: Verify Gatekeeper acceptance
echo "--- Step 9: Verifying Gatekeeper ---"
spctl --assess --type open --context context:primary-signature --verbose "${DMG_PATH}" 2>&1

# Step 10: Upload to GitHub release (creates tag/release if missing)
echo "--- Step 10: Uploading to GitHub release ${GITHUB_TAG} ---"
if gh release view "${GITHUB_TAG}" >/dev/null 2>&1; then
    gh release upload "${GITHUB_TAG}" "${DMG_PATH}" --clobber
else
    gh release create "${GITHUB_TAG}" "${DMG_PATH}" \
        --title "${APP_NAME} ${VERSION}" \
        --notes "Release ${VERSION}"
fi

echo ""
echo "=== Done: ${DMG_NAME} notarized, stapled, and uploaded to ${GITHUB_TAG} ==="
