# Whistype

**[Website](https://whistype.wazeem.com)** · **[Download](https://github.com/wasxxm/Whistype/releases/latest)** · **[Wiki](https://github.com/wasxxm/Whistype/wiki)**

Free, fast, on-device speech-to-text for macOS. Supports [WhisperKit](https://github.com/argmaxinc/WhisperKit) (CoreML), [Qwen3-ASR](https://github.com/ivan-digital/qwen3-asr-swift) (MLX), and [ParakeetASR](https://github.com/ivan-digital/qwen3-asr-swift) (MLX) engines on Apple Silicon.

Hold **⌥ Space** anywhere to dictate. Release to stop. Text is transcribed locally and pasted into the active app.

## Features

- **Zero cost** — no subscription, no API keys, no cloud
- **On-device** — audio never leaves your Mac
- **Three engines** — WhisperKit (CoreML), Qwen3-ASR (MLX), or ParakeetASR (MLX), switchable in settings
- **Fast** — CoreML + Apple Neural Engine or MLX acceleration on M-series chips
- **Global hotkey** — hold ⌥ Space from any app
- **Floating capsule** — minimal recording indicator at bottom of screen
- **Auto-paste** — transcribed text goes straight into the active app
- **History** — searchable log of past transcriptions
- **Open source** — MIT license

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon (M1 or later) — required
- Xcode 16.0+ (for building from source only)

## Install

### Download (recommended)

Download the latest notarized DMG from [GitHub Releases](https://github.com/wasxxm/Whistype/releases/latest):

1. Download `Whistype-1.0.0.dmg`
2. Open the DMG and drag Whistype to Applications
3. Launch Whistype from Applications
4. Follow the onboarding to grant microphone and accessibility permissions

### Build from source

```bash
git clone https://github.com/wasxxm/Whistype.git
cd Whistype
xcodegen generate
open Whistype.xcodeproj
```

Select the Whistype scheme and press ⌘R to build and run.

### First launch

1. Grant microphone access when prompted
2. Grant Accessibility access in System Settings (for auto-paste)
3. The model downloads automatically on first use (~1.5 GB for WhisperKit, ~400 MB for Qwen3-ASR/ParakeetASR)
4. Hold ⌥ Space to dictate, release to stop

## How it works

Whistype sits in your menu bar. Hold ⌥ Space and a floating capsule appears at the bottom of your screen showing recording state. Release to stop. The audio is transcribed using the selected engine (WhisperKit large-v3-turbo by default) and the text is pasted into whatever app you were using.

## Architecture

```
Presentation  →  FloatingCapsuleView, MenuBarView, SettingsView
Coordination  →  TranscriptionCoordinator (state machine)
Services      →  AudioRecorderService, WhisperTranscriptionService,
                  Qwen3TranscriptionService, ParakeetTranscriptionService,
                  HotkeyService, PasteService, PermissionsManager
Domain        →  Protocols, TranscriptionState enum
```

All services are protocol-based with dependency injection. The coordinator owns the state machine and orchestrates the entire flow: idle → recording → transcribing → done → idle.

## Settings

- Engine selection (WhisperKit, Qwen3-ASR, or ParakeetASR)
- Model selection (large-v3-turbo, large-v3, distil-large-v3, base.en, small.en — WhisperKit only)
- Auto-paste toggle
- Floating capsule toggle
- Launch at login

## Permissions

| Permission | Required | Purpose |
|---|---|---|
| Microphone | Yes | Capture speech |
| Accessibility | Optional | Auto-paste via key event simulation |

## Tech stack

- Swift / SwiftUI / AppKit
- [WhisperKit](https://github.com/argmaxinc/WhisperKit) — CoreML speech recognition
- [qwen3-asr-swift](https://github.com/ivan-digital/qwen3-asr-swift) — MLX speech recognition (Qwen3-ASR and ParakeetASR)
- [HotKey](https://github.com/soffes/HotKey) — global keyboard shortcuts
- AVAudioEngine — microphone capture
- SwiftData — transcription history
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — project generation

## License

MIT
