import Foundation
import SwiftData

@Model
final class TranscriptionRecord {
    var text: String
    var timestamp: Date
    var durationSeconds: Double

    init(text: String, timestamp: Date = .now, durationSeconds: Double = 0) {
        self.text = text
        self.timestamp = timestamp
        self.durationSeconds = durationSeconds
    }
}
