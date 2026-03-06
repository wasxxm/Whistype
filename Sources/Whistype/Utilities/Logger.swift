import os

extension Logger {
    private static let subsystem = "com.innowazi.Whistype"

    static let coordinator = Logger(subsystem: subsystem, category: "coordinator")
    static let audio = Logger(subsystem: subsystem, category: "audio")
    static let transcription = Logger(subsystem: subsystem, category: "transcription")
    static let paste = Logger(subsystem: subsystem, category: "paste")
    static let ui = Logger(subsystem: subsystem, category: "ui")
    static let app = Logger(subsystem: subsystem, category: "app")
}
