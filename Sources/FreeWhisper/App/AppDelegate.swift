import AppKit
import SwiftData
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var capsuleWindowController: FloatingCapsuleWindowController?
    var coordinator: TranscriptionCoordinator?
    var modelContainer: ModelContainer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func setupCapsule() {
        guard let coordinator else { return }
        capsuleWindowController = FloatingCapsuleWindowController(coordinator: coordinator)
    }

    func setupAndLoadModel() {
        guard let coordinator, let modelContainer else { return }
        coordinator.setupModelContainer(modelContainer)
        Task {
            await coordinator.loadModel()
        }
    }
}
