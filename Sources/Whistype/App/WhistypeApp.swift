import SwiftData
import SwiftUI

@main
struct WhistypeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(coordinator: appDelegate.container.coordinator)
        } label: {
            Image(systemName: "waveform.circle")
                .symbolRenderingMode(.hierarchical)
        }

        Settings {
            SettingsView()
        }

        Window("Welcome to Whistype", id: "onboarding") {
            OnboardingView(
                permissions: appDelegate.container.permissions as! PermissionsManager,
                coordinator: appDelegate.container.coordinator,
                onComplete: { hasCompletedOnboarding = true }
            )
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 480, height: 560)

        Window("Transcription History", id: "history") {
            HistoryView()
                .modelContainer(appDelegate.modelContainer)
        }
        .defaultSize(width: 480, height: 600)
    }

    init() {
        UserDefaults.standard.register(defaults: [
            "autoPasteEnabled": true,
            "showCapsule": true,
            "selectedModel": Constants.defaultModel,
        ])
    }
}
