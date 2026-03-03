import Foundation

protocol Transcription: AnyObject {
    var isModelLoaded: Bool { get }
    func loadModel(name: String) async throws
    func transcribe(samples: [Float]) async throws -> String
}
