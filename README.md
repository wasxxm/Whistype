# Whistype

**[Website](https://whistype.wazeem.com)** · **[Download](https://github.com/wasxxm/Whistype/releases/latest)** · **[Wiki](https://github.com/wasxxm/Whistype/wiki)**

Free, fast, on-device speech-to-text for macOS. Supports [WhisperKit](https://github.com/argmaxinc/WhisperKit) (CoreML), [Qwen3-ASR](https://github.com/ivan-digital/qwen3-asr-swift) (MLX), and [ParakeetASR](https://github.com/ivan-digital/qwen3-asr-swift) (CoreML) engines on Apple Silicon.

Hold **⌥ Space** anywhere to dictate. Release to stop. Text is transcribed locally and pasted into the active app.

## Features

- **Zero cost** — no subscription, no API keys, no cloud
- **On-device** — audio never leaves your Mac
- **Three engines** — WhisperKit (CoreML), Qwen3-ASR (MLX), or ParakeetASR (CoreML), switchable in settings
- **Fast** — encoder on the GPU, decoder on the Apple Neural Engine; the configuration Argmax themselves benchmark as fastest on Apple Silicon
- **Long-form dictation** — auto-chunks at silence past 30 seconds so longer recordings transcribe whole instead of getting cut off mid-sentence
- **Clipboard preserved** — when transcription is pasted via fallback, your prior clipboard contents are saved and restored (same behavior as SuperWhisper)
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

1. Download the `.dmg`
2. Open it and drag Whistype to Applications
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

Whistype sits in your menu bar. Hold ⌥ Space and a floating capsule appears at the bottom of your screen showing recording state. Release to stop. The audio is transcribed using the selected engine and the text is pasted into whatever app you were using.

By default WhisperKit picks the model best suited to your chip via `WhisperKit.recommendedModels()` — OpenAI's Whisper Large V3 Turbo (the September 2024 release with the 4-layer decoder) on M2/M3/M4, or its 4-bit compressed variant on M1. You can override this in Settings.

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
- WhisperKit model picker — `Recommended for this Mac` (auto-detect), Whisper Large V3 Turbo (full / streaming / 4-bit), Distil Whisper Large V3 Turbo, Whisper Large V3, plus Small and Base for low-resource machines
- Auto-paste toggle
- Restore-clipboard-after-paste toggle
- Floating capsule toggle
- Launch at login

## Permissions

Both permissions are requested together during onboarding.

| Permission | Required | Purpose |
|---|---|---|
| Microphone | Yes | Capture audio while ⌥ Space is held |
| Accessibility | Recommended | Auto-paste transcribed text into the active app |

**Why Accessibility?** Whistype simulates a ⌘V keystroke to paste text into whichever app you were using. macOS requires Accessibility permission for any app to send keystrokes to other apps. Without it, text is still copied to your clipboard automatically — you just have to paste manually with ⌘V.

**If you missed it or denied it during onboarding:**
1. Open **System Settings → Privacy & Security → Accessibility**
2. Click **+**, navigate to `/Applications/Whistype.app`, and add it
3. Toggle **Whistype On**
4. Relaunch Whistype

## Tech stack

- Swift / SwiftUI / AppKit
- [WhisperKit](https://github.com/argmaxinc/WhisperKit) — CoreML speech recognition
- [qwen3-asr-swift](https://github.com/ivan-digital/qwen3-asr-swift) — bundles Qwen3-ASR (MLX) and ParakeetASR (CoreML)
- [HotKey](https://github.com/soffes/HotKey) — global keyboard shortcuts
- AVAudioEngine — microphone capture
- SwiftData — transcription history
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — project generation

## License

MIT
