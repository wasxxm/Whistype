# Building from Source

## Prerequisites

- Xcode 16.0 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`
- Apple Silicon Mac (M1 or later)
- macOS 14.0 (Sonoma) or later

## Steps

```bash
git clone https://github.com/wasxxm/Whistype.git
cd Whistype
xcodegen generate
open Whistype.xcodeproj
```

Select the **Whistype** scheme, choose **My Mac** as the destination, and press **⌘R**.

SPM dependencies (WhisperKit, Qwen3-ASR, ParakeetASR, HotKey) resolve automatically on first build.

## Regenerating the Xcode Project

The `.xcodeproj` is generated from `project.yml` using XcodeGen. Whenever `project.yml` changes, regenerate:

```bash
xcodegen generate
```

Do not manually edit `Whistype.xcodeproj/project.pbxproj` — those changes will be overwritten.

## Debug vs Release

- **Debug** — signs with `Apple Development`, includes `get-task-allow` entitlement. Use for day-to-day development.
- **Release** — signs with `Developer ID Application`, Hardened Runtime, secure timestamp. Required for notarization.

Use `scripts/release.sh` for a full Release build. See [Release Process](Release-Process).

## Signing

The project uses Automatic signing with `Apple Development` for Debug builds. You need to be signed in to Xcode with an Apple ID that has an active developer account.
