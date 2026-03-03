import SwiftData
import SwiftUI

@main
struct FreeWhisperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var container = DependencyContainer()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    private let modelContainer: ModelContainer

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(coordinator: container.coordinator)
                .task { await bootstrapIfNeeded() }
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
                .modelContainer(modelContainer)
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

        let schema = Schema([TranscriptionRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    @MainActor
    private func bootstrapIfNeeded() async {
        guard appDelegate.coordinator == nil else { return }

        appDelegate.coordinator = container.coordinator
        appDelegate.modelContainer = modelContainer
        appDelegate.setupCapsule()
        appDelegate.setupAndLoadModel()
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
