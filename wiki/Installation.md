# Installation

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon (M1 or later) — required

## Download

1. Go to [Releases](https://github.com/wasxxm/Whistype/releases/latest)
2. Download `Whistype-1.0.0.dmg`
3. Open the DMG
4. Drag **Whistype.app** to the **Applications** folder

## First Launch

1. Open Whistype from `/Applications`
2. macOS will ask to confirm opening a downloaded app — click **Open**
3. The onboarding flow will guide you through:
   - **Microphone** — required for recording audio
   - **Accessibility** — required for auto-pasting transcribed text into the active app
4. On first use, the selected transcription model downloads automatically:
   - WhisperKit (large-v3-turbo): ~1.5 GB
   - Qwen3-ASR or ParakeetASR: ~400 MB

## Uninstall

1. Quit Whistype from the menu bar
2. Delete `/Applications/Whistype.app`
3. Optionally remove app data:
   ```
   ~/Library/Containers/com.innowazi.Whistype
   ~/Library/Application Support/Whistype
   ```
