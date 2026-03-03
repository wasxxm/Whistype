import AppKit
import SwiftData
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let container = DependencyContainer()
    private(set) var modelContainer: ModelContainer!
    private var capsuleWindowController: FloatingCapsuleWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[FreeWhisper] applicationDidFinishLaunching")
        NSApp.setActivationPolicy(.accessory)

        let schema = Schema([TranscriptionRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        container.coordinator.setupModelContainer(modelContainer)
        container.permissions.promptAccessibilityIfNeeded()
        capsuleWindowController = FloatingCapsuleWindowController(coordinator: container.coordinator)

        NSLog("[FreeWhisper] Starting model load")
        Task {
            await container.coordinator.loadModel()
        }
    }
}
