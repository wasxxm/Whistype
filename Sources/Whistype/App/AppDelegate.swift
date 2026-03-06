import AppKit
import os
import SwiftData
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let container = DependencyContainer()
    let modelContainer: ModelContainer
    private var capsuleWindowController: FloatingCapsuleWindowController?

    override init() {
        let schema = Schema([TranscriptionRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            Logger.app.error("Failed to create ModelContainer: \(error.localizedDescription)")
            let alert = NSAlert()
            alert.messageText = "Failed to Initialize Database"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            alert.runModal()
            NSApp.terminate(nil)
            // ModelContainer is non-optional, but terminate exits the process
            modelContainer = try! ModelContainer(for: schema, configurations: [config])
        }
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.app.info("applicationDidFinishLaunching")
        NSApp.setActivationPolicy(.accessory)

        container.coordinator.setupModelContainer(modelContainer)
        container.permissions.promptAccessibilityIfNeeded()
        capsuleWindowController = FloatingCapsuleWindowController(coordinator: container.coordinator)

        if !UserDefaults.standard.bool(forKey: Constants.Keys.hasCompletedOnboarding) {
            NSApp.setActivationPolicy(.regular)
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: {
                    $0.identifier?.rawValue == "onboarding"
                        || $0.title.contains("Welcome")
                }) {
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }

        Logger.app.info("Starting model load")
        Task {
            await container.coordinator.loadModel()
        }
    }
}
