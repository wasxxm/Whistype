# Release Process

This documents the full process for building, signing, notarizing, and publishing a new Whistype release.

## Prerequisites

- Valid **Developer ID Application: Waseem Khan (3426FSU868)** certificate in Keychain
- Notarization credentials stored: `xcrun notarytool store-credentials "Whistype-Notarize"`
- XcodeGen installed: `brew install xcodegen`

## Steps

### 1. Bump the version

Update `MARKETING_VERSION` in `project.yml`, then regenerate the project:

```bash
xcodegen generate
```

### 2. Run the release script

```bash
./scripts/release.sh
```

This does the following automatically:
1. Cleans the build directory
2. Archives with Release configuration (arm64, Developer ID signing, Hardened Runtime)
3. Exports the archive
4. Verifies the signature and checks for `get-task-allow` entitlement
5. Creates a DMG with an Applications symlink
6. Signs the DMG with Developer ID + secure timestamp
7. Submits the DMG to Apple's notary service
8. Prints the submission ID

### 3. Check notarization status

```bash
xcrun notarytool info <submission-id> --keychain-profile "Whistype-Notarize"
```

First-time submissions may take longer (up to a few hours). Subsequent submissions are usually under 15 minutes.

### 4. Staple the ticket

Once status shows `Accepted`:

```bash
xcrun stapler staple Whistype-X.X.X.dmg
xcrun stapler validate Whistype-X.X.X.dmg
spctl --assess --type open --context context:primary-signature -vvv Whistype-X.X.X.dmg
```

### 5. Publish on GitHub

```bash
gh release create vX.X.X Whistype-X.X.X.dmg \
  --title "Whistype X.X.X" \
  --notes "Release notes here" \
  --repo wasxxm/Whistype
```

## Signing Details

| Config | Identity | Style |
|--------|----------|-------|
| Debug | Apple Development | Automatic |
| Release | Developer ID Application | Manual (via script) |

## Entitlements

Production entitlements (no `get-task-allow`):
- `com.apple.security.device.audio-input`
- `com.apple.security.automation.apple-events`
