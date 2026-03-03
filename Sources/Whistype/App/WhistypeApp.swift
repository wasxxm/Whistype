import SwiftData
import SwiftUI

@main
struct WhistypeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage(Constants.Keys.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(coordinator: appDelegate.container.coordinator)
        } label: {
            MenuBarIcon(coordinator: appDelegate.container.coordinator)
        }

        Settings {
            SettingsView()
        }

        Window("Welcome to Whistype", id: "onboarding") {
            OnboardingView(
                permissions: appDelegate.container.permissions,
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
            Constants.Keys.selectedEngine: Constants.defaultEngine,
            Constants.Keys.selectedModel: Constants.defaultModel,
            Constants.Keys.selectedQwen3Model: Constants.defaultQwen3Model,
            Constants.Keys.autoPasteEnabled: true,
            Constants.Keys.showCapsule: true,
            Constants.Keys.launchAtLogin: false,
            Constants.Keys.hasCompletedOnboarding: false,
            Constants.Keys.hasPromptedAccessibility: false,
        ])
    }
}
