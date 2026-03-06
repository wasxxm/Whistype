import Combine
import Foundation
import os
import ParakeetASR

final class ParakeetTranscriptionService: Transcription {
    private(set) var isModelLoaded = false

    var loadingStatusPublisher: AnyPublisher<ModelLoadingStatus, Never> {
        loadingStatusSubject.eraseToAnyPublisher()
    }

    private let loadingStatusSubject = CurrentValueSubject<ModelLoadingStatus, Never>(.idle)
    private var model: ParakeetASRModel?

    func loadModel(name: String) async throws {
        Logger.transcription.info("Parakeet-TDT loadModel started")
        loadingStatusSubject.send(.downloading(progress: 0))

        do {
            let asrModel = try await ParakeetASRModel.fromPretrained { [weak self] progress, _ in
                self?.loadingStatusSubject.send(.downloading(progress: progress))
            }

            loadingStatusSubject.send(.prewarming)
            Logger.transcription.info("Parakeet-TDT warming up CoreML…")
            try asrModel.warmUp()

            model = asrModel
            isModelLoaded = true
            loadingStatusSubject.send(.ready)
            Logger.transcription.info("Parakeet-TDT model ready")
        } catch {
            loadingStatusSubject.send(.failed(message: error.localizedDescription))
            Logger.transcription.error("Parakeet-TDT model load failed: \(error.localizedDescription)")
            throw error
        }
    }

    func transcribe(samples: [Float]) async throws -> String {
        guard let model else {
            throw TranscriptionError.modelNotLoaded
        }

        let text = try model.transcribeAudio(samples, sampleRate: Int(Constants.audioSampleRate))
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw TranscriptionError.emptyResult
        }

        return trimmed
    }
}
