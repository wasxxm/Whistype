import Combine
import Foundation
import WhisperKit

final class WhisperTranscriptionService: Transcription {
    private(set) var isModelLoaded = false

    var loadingStatusPublisher: AnyPublisher<ModelLoadingStatus, Never> {
        loadingStatusSubject.eraseToAnyPublisher()
    }

    private let loadingStatusSubject = CurrentValueSubject<ModelLoadingStatus, Never>(.idle)
    private var whisperKit: WhisperKit?

    func loadModel(name: String) async throws {
        NSLog("loadModel started for: \(name)")
        loadingStatusSubject.send(.downloading(progress: 0))

        let config = WhisperKitConfig(
            model: name,
            verbose: true,
            logLevel: .info,
            prewarm: false,
            load: false,
            download: false
        )
        NSLog("Creating WhisperKit instance")
        let kit = try await WhisperKit(config)

        NSLog("Downloading/locating model")
        let modelFolder = try await WhisperKit.download(variant: name) { [weak self] progress in
            let fraction = progress.fractionCompleted
            self?.loadingStatusSubject.send(.downloading(progress: fraction))
        }
        kit.modelFolder = modelFolder
        NSLog("Model folder: \(modelFolder)")

        NSLog("Prewarming models")
        loadingStatusSubject.send(.prewarming)
        try await kit.prewarmModels()

        NSLog("Loading models")
        loadingStatusSubject.send(.loading)
        try await kit.loadModels()

        whisperKit = kit
        isModelLoaded = true
        loadingStatusSubject.send(.ready)
        NSLog("Model loaded successfully")
    }

    func transcribe(samples: [Float]) async throws -> String {
        guard let whisperKit else {
            throw TranscriptionError.modelNotLoaded
        }

        let result = try await whisperKit.transcribe(audioArray: samples)
        let text = result.map(\.text).joined(separator: " ").trimmingCharacters(
            in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            throw TranscriptionError.emptyResult
        }

        return text
    }
}

enum TranscriptionError: LocalizedError {
    case modelNotLoaded
    case emptyResult

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Whisper model is not loaded."
        case .emptyResult:
            return "No speech detected in audio."
        }
    }
}
