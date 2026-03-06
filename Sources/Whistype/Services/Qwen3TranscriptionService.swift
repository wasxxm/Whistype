import Combine
import Foundation
import MLX
import os
import Qwen3ASR

final class Qwen3TranscriptionService: Transcription {
    private(set) var isModelLoaded = false

    var loadingStatusPublisher: AnyPublisher<ModelLoadingStatus, Never> {
        loadingStatusSubject.eraseToAnyPublisher()
    }

    private let loadingStatusSubject = CurrentValueSubject<ModelLoadingStatus, Never>(.idle)
    private var model: Qwen3ASRModel?

    func loadModel(name: String) async throws {
        Logger.transcription.info("Qwen3-ASR loadModel started")
        loadingStatusSubject.send(.downloading(progress: 0))

        // 512 MB lets MLX reuse GPU buffers across inference runs without
        // thrashing on longer recordings (up from the previous 256 MB limit).
        Memory.cacheLimit = 512 * 1024 * 1024

        do {
            let asrModel = try await Qwen3ASRModel.fromPretrained { [weak self] progress, _ in
                self?.loadingStatusSubject.send(.downloading(progress: progress))
            }

            loadingStatusSubject.send(.prewarming)
            Logger.transcription.info("Qwen3-ASR warming up Metal shaders…")

            // Run a short dummy transcription to JIT-compile all Metal shaders
            // across the 18 encoder + 28 decoder transformer layers
            let warmupSamples = [Float](repeating: 0, count: 8000) // 0.5s silence
            _ = asrModel.transcribe(audio: warmupSamples, sampleRate: Int(Constants.audioSampleRate), language: "en")

            model = asrModel
            isModelLoaded = true
            loadingStatusSubject.send(.ready)
            Logger.transcription.info("Qwen3-ASR model ready (warmed up)")
        } catch {
            loadingStatusSubject.send(.failed(message: error.localizedDescription))
            Logger.transcription.error("Qwen3-ASR model load failed: \(error.localizedDescription)")
            throw error
        }
    }

    func transcribe(samples: [Float]) async throws -> String {
        guard let model else {
            throw TranscriptionError.modelNotLoaded
        }

        let text = model.transcribe(audio: samples, sampleRate: Int(Constants.audioSampleRate), language: "en")
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw TranscriptionError.emptyResult
        }

        return trimmed
    }
}
