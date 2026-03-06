import Foundation

enum TranscriptionError: LocalizedError {
    case modelNotLoaded
    case emptyResult

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Speech model is not loaded."
        case .emptyResult:
            return "No speech detected in audio."
        }
    }
}
