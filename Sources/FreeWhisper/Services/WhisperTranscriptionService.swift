import Foundation
import WhisperKit

final class WhisperTranscriptionService: Transcription {
    private(set) var isModelLoaded = false
    private var whisperKit: WhisperKit?

    func loadModel(name: String) async throws {
        let config = WhisperKitConfig(model: name)
        whisperKit = try await WhisperKit(config)
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
