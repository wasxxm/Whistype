# FreeWhisper

Free, fast, on-device speech-to-text for macOS. Built on [WhisperKit](https://github.com/argmaxinc/WhisperKit) with CoreML acceleration for Apple Silicon.

Press **⌥ Space** anywhere to start dictating. Press again to stop. Text is transcribed locally and pasted into the active app.

## Features

- **Zero cost** — no subscription, no API keys, no cloud
- **On-device** — audio never leaves your Mac
- **Fast** — CoreML + Apple Neural Engine acceleration on M-series chips
- **Global hotkey** — ⌥ Space from any app
- **Floating capsule** — minimal recording indicator at bottom of screen
- **Auto-paste** — transcribed text goes straight into the active app
- **History** — searchable log of past transcriptions
- **Open source** — MIT license

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon (M1/M2/M3/M4) recommended
- Xcode 16.0+ (for building from source)

## Install

### Build from source

```bash
git clone https://github.com/InnoWazi/FreeWhisper.git
cd FreeWhisper
xcodegen generate
open FreeWhisper.xcodeproj
```

Select the FreeWhisper scheme and press ⌘R to build and run.

### First launch

1. Grant microphone access when prompted
2. Grant Accessibility access in System Settings (for auto-paste)
3. The Whisper model downloads automatically on first use (~1.5 GB)
4. Press ⌥ Space to start dictating

## How it works

FreeWhisper sits in your menu bar. When you press ⌥ Space, a floating capsule appears at the bottom of your screen showing recording state. Press ⌥ Space again to stop. The audio is transcribed using WhisperKit (large-v3-turbo model by default) and the text is pasted into whatever app you were using.

## Architecture

```
Presentation  →  FloatingCapsuleView, MenuBarView, SettingsView
Coordination  →  TranscriptionCoordinator (state machine)
Services      →  AudioRecorderService, WhisperTranscriptionService,
                  HotkeyService, PasteService, PermissionsManager
Domain        →  Protocols, TranscriptionState enum
```

All services are protocol-based with dependency injection. The coordinator owns the state machine and orchestrates the entire flow: idle → recording → transcribing → done → idle.

## Settings

- Model selection (large-v3-turbo, large-v3, distil-large-v3, base.en, small.en)
- Auto-paste toggle
- Floating capsule toggle
- Max recording duration
- Launch at login

## Permissions

| Permission | Required | Purpose |
|---|---|---|
| Microphone | Yes | Capture speech |
| Accessibility | Optional | Auto-paste via Cmd+V simulation |

## Tech stack

- Swift / SwiftUI / AppKit
- [WhisperKit](https://github.com/argmaxinc/WhisperKit) — CoreML speech recognition
- [HotKey](https://github.com/soffes/HotKey) — global keyboard shortcuts
- AVAudioEngine — microphone capture
- SwiftData — transcription history
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — project generation

## License

MIT
