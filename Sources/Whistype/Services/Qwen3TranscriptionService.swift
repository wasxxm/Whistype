import Combine
import Foundation
import Qwen3ASR

final class Qwen3TranscriptionService: Transcription {
    private(set) var isModelLoaded = false

    var loadingStatusPublisher: AnyPublisher<ModelLoadingStatus, Never> {
        loadingStatusSubject.eraseToAnyPublisher()
    }

    private let loadingStatusSubject = CurrentValueSubject<ModelLoadingStatus, Never>(.idle)
    private var model: Qwen3ASRModel?

    func loadModel(name: String) async throws {
        NSLog("[Whistype] Qwen3-ASR loadModel started")
        loadingStatusSubject.send(.downloading(progress: 0))
        loadingStatusSubject.send(.loading)

        do {
            NSLog("[Whistype] Downloading Qwen3-ASR model (~400MB on first run)")
            let asrModel = try await Qwen3ASRModel.fromPretrained()
            model = asrModel
            isModelLoaded = true
            loadingStatusSubject.send(.ready)
            NSLog("[Whistype] Qwen3-ASR model ready")
        } catch {
            loadingStatusSubject.send(.failed(message: error.localizedDescription))
            NSLog("[Whistype] Qwen3-ASR model load failed: %@", error.localizedDescription)
            throw error
        }
    }

    func transcribe(samples: [Float]) async throws -> String {
        guard let model else {
            throw TranscriptionError.modelNotLoaded
        }

        let text = model.transcribe(audio: samples, sampleRate: 16000, language: "en")
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw TranscriptionError.emptyResult
        }

        return trimmed
    }
}
