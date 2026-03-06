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
3. The onboarding will ask for two permissions — see [Permissions](#permissions) below
4. On first use, the selected transcription model downloads automatically:
   - WhisperKit (large-v3-turbo): ~1.5 GB
   - Qwen3-ASR or ParakeetASR: ~400 MB

## Permissions

Whistype requests two permissions during onboarding. Both are requested together with a single "Grant Access" button.

---

### Microphone — Required

**Why:** Whistype needs to hear your voice to transcribe it. Without microphone access the app cannot record audio and will not function at all.

**What it does:** Captures audio from your microphone only while you are holding ⌥ Space. Recording stops the moment you release the key. Audio is processed entirely on-device and never sent anywhere.

**How to grant if you missed it:**
1. Open **System Settings**
2. Go to **Privacy & Security → Microphone**
3. Find **Whistype** in the list and toggle it **On**
4. Relaunch Whistype

---

### Accessibility — Recommended

**Why:** After transcription, Whistype needs to paste the text into whatever app you were using — your browser, email client, notes app, etc. macOS requires Accessibility permission to simulate the paste keyboard shortcut (⌘V) in other apps.

**What it does:** Allows Whistype to send a single paste command to the frontmost app after transcription completes. Whistype does not read, monitor, or interact with any other app's content.

**Without this permission:** Transcribed text is still copied to your clipboard automatically. You can paste it manually with ⌘V. Auto-paste just won't happen.

**How to grant if you missed it or denied it:**
1. Open **System Settings**
2. Go to **Privacy & Security → Accessibility**
3. Click the **+** button if Whistype is not in the list, navigate to `/Applications/Whistype.app` and add it
4. Toggle **Whistype On**
5. Relaunch Whistype

> macOS does not allow apps to re-prompt for Accessibility after the first time. If you denied it during onboarding, you must grant it manually via System Settings as described above.

---

## Uninstall

1. Quit Whistype from the menu bar
2. Delete `/Applications/Whistype.app`
3. Optionally remove app data:
   ```
   ~/Library/Containers/com.innowazi.Whistype
   ~/Library/Application Support/Whistype
   ```
