import SwiftData
import SwiftUI

@main
struct FreeWhisperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var container = DependencyContainer()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(coordinator: container.coordinator)
        } label: {
            MenuBarLabel(state: container.coordinator.state)
        }

        Settings {
            SettingsView()
        }

        Window("Welcome to FreeWhisper", id: "onboarding") {
            OnboardingView(
                permissions: container.permissions as! PermissionsManager,
                coordinator: container.coordinator,
                onComplete: { hasCompletedOnboarding = true }
            )
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 480, height: 560)

        Window("Transcription History", id: "history") {
            HistoryView()
        }
        .defaultSize(width: 480, height: 600)
    }

    init() {
        UserDefaults.standard.register(defaults: [
            "autoPasteEnabled": true,
            "showCapsule": true,
            "maxRecordingSeconds": Constants.defaultMaxRecordingSeconds,
            "selectedModel": Constants.defaultModel,
        ])
    }
}

struct MenuBarLabel: View {
    let state: TranscriptionState

    var body: some View {
        Image(systemName: iconName)
            .symbolRenderingMode(.hierarchical)
    }

    private var iconName: String {
        switch state {
        case .idle: return "waveform.circle"
        case .recording: return "waveform.circle.fill"
        case .transcribing: return "ellipsis.circle"
        case .done: return "checkmark.circle"
        case .error: return "exclamationmark.circle"
        }
    }
}
