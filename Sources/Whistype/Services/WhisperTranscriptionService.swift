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
        Logger.transcription.info("WhisperKit loadModel started for: \(name)")
        loadingStatusSubject.send(.downloading(progress: 0))

        let config = WhisperKitConfig(
            model: name,
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
            whisperKit = kit
            isModelLoaded = true
            loadingStatusSubject.send(.ready)
            Logger.transcription.info("WhisperKit model ready")
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
            concurrentWorkerCount: 4
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
