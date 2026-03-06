# Troubleshooting

## Hotkey not working

**⌥ Space not triggering recording:**
- Check that another app isn't capturing ⌥ Space globally (e.g. Spotlight, Alfred, Raycast)
- Quit and relaunch Whistype
- Make sure Accessibility permission is granted: **System Settings → Privacy & Security → Accessibility**

## Auto-paste not working

Text is transcribed but not pasted into the active app:
- Grant Accessibility permission: **System Settings → Privacy & Security → Accessibility → Whistype → toggle On**
- If already granted, toggle it off and back on, then relaunch Whistype

## Microphone not working

- Grant Microphone permission: **System Settings → Privacy & Security → Microphone → Whistype → toggle On**
- Check no other app is exclusively holding the microphone

## Model download stuck or failed

- Check your internet connection
- Quit Whistype, delete the partial download from `~/Library/Application Support/Whistype/`, and relaunch

## App won't open — "damaged or can't be verified"

This should not happen with the notarized DMG from GitHub Releases. If it does:
```bash
xattr -cr /Applications/Whistype.app
```

## Transcription quality is poor

- Speak clearly and at a normal pace
- Reduce background noise
- Try switching to a different engine or model in Settings
- WhisperKit `large-v3-turbo` generally gives the best accuracy

## High CPU/memory during transcription

- The first transcription after launch loads the model into memory — subsequent ones are faster
- MLX-based engines (Qwen3-ASR, ParakeetASR) use GPU memory on Apple Silicon
- This is expected behaviour for on-device AI inference
