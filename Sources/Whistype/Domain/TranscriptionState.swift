import Foundation

enum TranscriptionState: Equatable {
    case idle
    case recording(startTime: Date)
    case transcribing
    case done(text: String)
    case error(message: String)

    var isRecording: Bool {
        if case .recording = self { return true }
        return false
    }

    var isTranscribing: Bool {
        if case .transcribing = self { return true }
        return false
    }

    var isDone: Bool {
        if case .done = self { return true }
        return false
    }

    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    var shouldShowCapsule: Bool {
        switch self {
        case .idle: return false
        case .recording, .transcribing, .done, .error: return true
        }
    }
}
