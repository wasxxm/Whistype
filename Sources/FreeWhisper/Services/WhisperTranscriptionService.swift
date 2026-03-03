import Foundation
import WhisperKit

final class WhisperTranscriptionService: Transcription {
    private(set) var isModelLoaded = false
    private var whisperKit: WhisperKit?

    func loadModel(name: String) async throws {
        // Step 1: Initialize WhisperKit without loading or downloading yet
        let config = WhisperKitConfig(
            model: name,
            verbose: true,
            logLevel: .info,
            prewarm: false,
            load: false,
            download: false
        )
        let kit = try await WhisperKit(config)

        // Step 2: Download model (or use local cache if already downloaded)
        let modelFolder = try await WhisperKit.download(variant: name)
        kit.modelFolder = modelFolder

        // Step 3: Prewarm models (compiles CoreML for this device)
        try await kit.prewarmModels()

        // Step 4: Load models into memory
        try await kit.loadModels()

        whisperKit = kit
        isModelLoaded = true
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
