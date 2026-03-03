import Combine
import Foundation

protocol Transcription: AnyObject {
    var isModelLoaded: Bool { get }
    var loadingStatusPublisher: AnyPublisher<ModelLoadingStatus, Never> { get }
    func loadModel(name: String) async throws
    func transcribe(samples: [Float]) async throws -> String
}

enum ModelLoadingStatus: Equatable {
    case idle
    case downloading(progress: Double)
    case prewarming
    case loading
    case ready
    case failed(message: String)

    var displayText: String {
        switch self {
        case .idle: return "Waiting..."
        case .downloading(let progress):
            let pct = Int(progress * 100)
            return "Downloading model: \(pct)%"
        case .prewarming: return "Optimizing for your device..."
        case .loading: return "Loading model..."
        case .ready: return "Ready"
        case .failed(let message): return "Failed: \(message)"
        }
    }
}
