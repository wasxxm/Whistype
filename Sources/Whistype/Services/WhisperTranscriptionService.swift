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
        NSLog("[Whistype] loadModel started for: %@", name)
        loadingStatusSubject.send(.downloading(progress: 0))

        // Let WhisperKit handle download + prewarm + load in one pass.
        // On first launch CoreML compiles the model for ANE (~18s).
        // Subsequent launches use the cached compilation and are fast.
        let config = WhisperKitConfig(
            model: name,
            verbose: false,
            logLevel: .error,
            prewarm: true,
            load: true,
            download: true
        )

        loadingStatusSubject.send(.loading)
        NSLog("[Whistype] Creating WhisperKit (download + prewarm + load)")
        let kit = try await WhisperKit(config)

        whisperKit = kit
        isModelLoaded = true
        loadingStatusSubject.send(.ready)
        NSLog("[Whistype] Model ready")
    }

    func transcribe(samples: [Float]) async throws -> String {
        guard let whisperKit else {
            throw TranscriptionError.modelNotLoaded
        }

        let options = DecodingOptions(
            task: .transcribe,
            language: "en",
            temperature: 0,
            temperatureFallbackCount: 0,
            usePrefillPrompt: true,
            usePrefillCache: true,
            skipSpecialTokens: true,
            withoutTimestamps: true,
            suppressBlank: true,
            concurrentWorkerCount: 16
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
