import Combine
import Foundation
import os
import WhisperKit

final class WhisperTranscriptionService: Transcription {
    private(set) var isModelLoaded = false

    var loadingStatusPublisher: AnyPublisher<ModelLoadingStatus, Never> {
        loadingStatusSubject.eraseToAnyPublisher()
    }

    private let loadingStatusSubject = CurrentValueSubject<ModelLoadingStatus, Never>(.idle)
    private var whisperKit: WhisperKit?

    func loadModel(name: String) async throws {
        let resolvedName = Self.resolveModelName(name)
        Logger.transcription.info("WhisperKit loadModel started for: \(name) -> \(resolvedName)")
        loadingStatusSubject.send(.downloading(progress: 0))

        // Encoder on GPU + decoder on ANE is the configuration Argmax documents as the
        // fastest at https://github.com/argmaxinc/argmax-oss-swift/discussions/243 (72x
        // real-time on M2 Ultra vs 42x for the ANE-only default). The encoder is a
        // throughput-bound parallel workload that benefits from the GPU, while the
        // decoder forward pass is latency-bound and wins from the ANE's stateful KV cache.
        let computeOptions = ModelComputeOptions(
            audioEncoderCompute: .cpuAndGPU,
            textDecoderCompute: .cpuAndNeuralEngine
        )

        let config = WhisperKitConfig(
            model: resolvedName,
            computeOptions: computeOptions,
            verbose: false,
            logLevel: .error,
            prewarm: true,
            load: true,
            download: true
        )

        loadingStatusSubject.send(.loading)
        Logger.transcription.info("Creating WhisperKit (download + prewarm + load)")

        do {
            let kit = try await WhisperKit(config)

            // WhisperKit's `prewarm: true` validates the ANE specialization cache
            // but doesn't run actual inference. The first real transcribe call still
            // pays a JIT cost as CoreML compiles the encoder + decoder graphs for
            // the runtime compute units. Run a silent dummy pass so the user's first
            // hotkey press hits a hot graph instead of the compile path.
            loadingStatusSubject.send(.prewarming)
            Logger.transcription.info("WhisperKit warming up inference graph…")
            let warmupSamples = [Float](repeating: 0, count: 8000)  // 0.5s silence
            let warmupOptions = DecodingOptions(
                task: .transcribe,
                language: "en",
                temperature: 0,
                temperatureFallbackCount: 0,
                usePrefillPrompt: true,
                usePrefillCache: true,
                skipSpecialTokens: true,
                withoutTimestamps: true
            )
            _ = try? await kit.transcribe(audioArray: warmupSamples, decodeOptions: warmupOptions)

            whisperKit = kit
            isModelLoaded = true
            loadingStatusSubject.send(.ready)
            Logger.transcription.info("WhisperKit model ready (warmed up)")
        } catch {
            loadingStatusSubject.send(.failed(message: error.localizedDescription))
            Logger.transcription.error("WhisperKit model load failed: \(error.localizedDescription)")
            throw error
        }
    }

    func transcribe(samples: [Float]) async throws -> String {
        guard let whisperKit else {
            throw TranscriptionError.modelNotLoaded
        }

        // VAD chunking has a small upfront cost (running a VAD model over the audio),
        // so we only enable it when the recording exceeds Whisper's 30-second window.
        // Below that, a single window is enough and the VAD pass is pure overhead.
        // Above it, chunking is required: WhisperKit caps each window at 224 output
        // tokens, so longer dictation hits the cap mid-thought without chunking.
        let durationSeconds = Double(samples.count) / Constants.audioSampleRate
        let chunkingStrategy: ChunkingStrategy? =
            durationSeconds > Constants.whisperChunkingThresholdSeconds ? .vad : nil

        // Keep WhisperKit's default temperature-fallback behaviour (5 retries with
        // rising temperature) so low-confidence windows get rescued. Clean dictation
        // never triggers a fallback, so the speed cost is paid only on hard audio
        // and accuracy on edge cases stays high.
        let options = DecodingOptions(
            task: .transcribe,
            language: "en",
            temperature: 0,
            usePrefillPrompt: true,
            usePrefillCache: true,
            skipSpecialTokens: true,
            withoutTimestamps: true,
            suppressBlank: true,
            chunkingStrategy: chunkingStrategy
        )

        let result = try await whisperKit.transcribe(
            audioArray: samples,
            decodeOptions: options
        )
        let text = result.map(\.text).joined(separator: " ").trimmingCharacters(
            in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            throw TranscriptionError.emptyResult
        }

        return text
    }

    /// Resolves the picker sentinel `auto` to WhisperKit's chip-aware default
    /// (e.g. `openai_whisper-large-v3-v20240930` on M2/M3/M4, `_626MB` on M1).
    /// Any other value is passed through to WhisperKit's glob model search.
    private static func resolveModelName(_ name: String) -> String {
        guard name == Constants.WhisperModelID.auto else { return name }
        return WhisperKit.recommendedModels().default
    }
}
