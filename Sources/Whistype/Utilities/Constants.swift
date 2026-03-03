import Foundation

enum Constants {
    static let appName = "Whistype"
    static let defaultEngine = "whisperkit"
    static let defaultModel = "large-v3_turbo"
    static let maxHistoryCount = 50
    static let capsuleWidth: CGFloat = 300
    static let capsuleHeight: CGFloat = 52
    static let capsuleCornerRadius: CGFloat = 26
    static let capsuleBottomPadding: CGFloat = 80
    static let doneDismissDelay: TimeInterval = 1.5
    static let errorDismissDelay: TimeInterval = 2.0
    static let audioSampleRate: Double = 16000

    enum Keys {
        static let selectedEngine = "selectedEngine"
        static let selectedModel = "selectedModel"
        static let autoPasteEnabled = "autoPasteEnabled"
        static let showCapsule = "showCapsule"
        static let launchAtLogin = "launchAtLogin"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let hasPromptedAccessibility = "hasPromptedAccessibility"
    }
}
