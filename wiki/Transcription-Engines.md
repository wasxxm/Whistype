# Transcription Engines

Whistype supports three on-device transcription engines. All processing happens locally — no audio ever leaves your Mac.

## Comparison

| Engine | Framework | Models | Speed | Accuracy | First Download |
|--------|-----------|--------|-------|----------|----------------|
| WhisperKit | CoreML + ANE | large-v3-turbo, large-v3, distil-large-v3, base.en, small.en | Fast | High | ~1.5 GB |
| Qwen3-ASR | MLX | qwen3-asr | Moderate | High | ~400 MB |
| ParakeetASR | MLX | parakeet | Fast | High | ~400 MB |

## WhisperKit

Uses Apple's CoreML framework and the Apple Neural Engine for hardware-accelerated inference. Based on OpenAI's Whisper architecture. Best for accuracy across diverse accents and vocabulary.

**Recommended model:** `large-v3-turbo` — best balance of speed and accuracy.

## Qwen3-ASR

Uses MLX (Apple's machine learning framework for Apple Silicon) to run Alibaba's Qwen3-ASR model. Good alternative to WhisperKit with comparable accuracy.

## ParakeetASR

Uses MLX to run NVIDIA's Parakeet model. Optimized for speed, performs well for English speech.

## Switching Engines

Open **Settings → General** and select the engine from the dropdown. The selected engine's model will download on first use. Previously downloaded models are cached.

## Model Storage

Models are cached in:
```
~/Library/Application Support/Whistype/
```
