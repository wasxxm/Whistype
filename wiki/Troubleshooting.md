# Troubleshooting

## Auto-paste not working

Transcription completes but text is not pasted into the active app.

**Cause:** Accessibility permission is not granted. Whistype needs this to send the paste command (⌘V) to other apps.

**Fix:**
1. Open **System Settings → Privacy & Security → Accessibility**
2. Check if Whistype is in the list
   - If yes — make sure the toggle is **On**. If it was already on, toggle it Off then back On
   - If no — click **+**, navigate to `/Applications/Whistype.app`, and add it, then toggle **On**
3. Relaunch Whistype

> Note: macOS does not allow apps to re-prompt for Accessibility permission. If you denied it during onboarding, you must grant it manually via System Settings.

---

## Microphone not working

Whistype shows an error or does not respond when you hold ⌥ Space.

**Fix:**
1. Open **System Settings → Privacy & Security → Microphone**
2. Find Whistype and toggle it **On**
3. Relaunch Whistype
4. Check that no other app is exclusively holding the microphone (e.g. video call apps)

---

## Hotkey not working

⌥ Space does not trigger recording.

- Check that another app is not capturing ⌥ Space globally (e.g. Spotlight, Alfred, Raycast)
- Make sure Accessibility permission is granted — see [Auto-paste not working](#auto-paste-not-working)
- Quit and relaunch Whistype

---

## Model download stuck or failed

- Check your internet connection
- Quit Whistype, delete the partial download from `~/Library/Application Support/Whistype/`, and relaunch

---

## App won't open — "damaged or can't be verified"

This should not happen with the notarized DMG from GitHub Releases. If it does:

```bash
xattr -cr /Applications/Whistype.app
```

---

## Transcription quality is poor

- Speak clearly and at a normal pace
- Reduce background noise
- Try switching to a different engine or model in Settings
- WhisperKit `large-v3-turbo` generally gives the best accuracy

---

## High CPU or memory during transcription

- The first transcription after launch loads the model into memory — subsequent ones are faster
- MLX-based engines (Qwen3-ASR, ParakeetASR) use GPU memory on Apple Silicon
- This is expected behaviour for on-device AI inference
