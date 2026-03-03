import AppKit
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
            fatalError("Failed to create ModelContainer: \(error)")
        }
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[Whistype] applicationDidFinishLaunching")
        NSApp.setActivationPolicy(.accessory)

        container.coordinator.setupModelContainer(modelContainer)
        container.permissions.promptAccessibilityIfNeeded()
        capsuleWindowController = FloatingCapsuleWindowController(coordinator: container.coordinator)

        if !UserDefaults.standard.bool(forKey: Constants.Keys.hasCompletedOnboarding) {
            NSApp.setActivationPolicy(.regular)
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: {
                    $0.title.contains("Welcome")
                }) {
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }

        NSLog("[Whistype] Starting model load")
        Task {
            await container.coordinator.loadModel()
        }
    }
}
