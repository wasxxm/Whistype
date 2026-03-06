import Foundation

enum AudioRecorderError: LocalizedError {
    case noInputDevice
    case converterCreationFailed

    var errorDescription: String? {
        switch self {
        case .noInputDevice:
            return "No audio input device found."
        case .converterCreationFailed:
            return "Failed to create audio format converter."
        }
    }
}
