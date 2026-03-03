import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var capsuleWindowController: FloatingCapsuleWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        if !UserDefaults.standard.bool(forKey: "hasSetDefaults") {
            setDefaultPreferences()
        }
    }

    func setupCapsuleWindow(coordinator: TranscriptionCoordinator) {
        capsuleWindowController = FloatingCapsuleWindowController(coordinator: coordinator)
    }

    func showCapsule() {
        capsuleWindowController?.show()
    }

    func hideCapsule() {
        capsuleWindowController?.hide()
    }

    private func setDefaultPreferences() {
        UserDefaults.standard.set(true, forKey: "autoPasteEnabled")
        UserDefaults.standard.set(true, forKey: "showCapsule")
        UserDefaults.standard.set(Constants.defaultMaxRecordingSeconds, forKey: "maxRecordingSeconds")
        UserDefaults.standard.set(Constants.defaultModel, forKey: "selectedModel")
        UserDefaults.standard.set(true, forKey: "hasSetDefaults")
    }
}
