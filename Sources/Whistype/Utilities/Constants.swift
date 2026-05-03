import Foundation

enum Constants {
    static let appName = "Whistype"
    static let defaultEngine = EngineID.whisperKit
    static let defaultModel = WhisperModelID.auto
    static let defaultQwen3Model = EngineID.qwen3
    static let maxHistoryCount = 50
    static let capsuleWidth: CGFloat = 300
    static let capsuleHeight: CGFloat = 52
    static let capsuleCornerRadius: CGFloat = 26
    static let capsuleBottomPadding: CGFloat = 80
    static let doneDismissDelay: TimeInterval = 1.5
    static let errorDismissDelay: TimeInterval = 2.0
    static let audioSampleRate: Double = 16000
    static let minimumRecordingDuration: TimeInterval = 0.5
    /// Audio length above which WhisperKit needs explicit chunking to avoid
    /// a single-window 224-token output cap (Whisper architectural limit per window).
    static let whisperChunkingThresholdSeconds: TimeInterval = 28

    enum EngineID {
        static let whisperKit = "whisperkit"
        static let qwen3 = "qwen3-asr"
        static let parakeet = "parakeet-tdt"
    }

    /// Stable identifiers persisted in UserDefaults for the WhisperKit model picker.
    /// `auto` is a sentinel resolved at load time to `WhisperKit.recommendedModels().default`,
    /// which selects the best CoreML variant for the user's chip (full v20240930 on M2+,
    /// 4-bit compressed `_626MB` on M1).
    enum WhisperModelID {
        static let auto = "auto"
        static let largeV3TurboV20240930 = "large-v3-v20240930"
        static let largeV3TurboV20240930Streaming = "large-v3-v20240930_turbo"
        static let largeV3TurboV20240930Compressed = "large-v3-v20240930_626MB"
        static let distilLargeV3Turbo = "distil-whisper_distil-large-v3_turbo"
        static let distilLargeV3TurboCompressed = "distil-whisper_distil-large-v3_turbo_600MB"
        static let largeV3 = "large-v3"
        static let smallEn = "small.en"
        static let baseEn = "base.en"
    }

    enum Keys {
        static let selectedEngine = "selectedEngine"
        static let selectedModel = "selectedModel"
        static let autoPasteEnabled = "autoPasteEnabled"
        static let showCapsule = "showCapsule"
        static let launchAtLogin = "launchAtLogin"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let selectedQwen3Model = "selectedQwen3Model"
        static let hasPromptedAccessibility = "hasPromptedAccessibility"
        static let didMigrateLegacyWhisperModel = "didMigrateLegacyWhisperModelV1"
        static let restoreClipboardAfterPaste = "restoreClipboardAfterPaste"
    }
}
