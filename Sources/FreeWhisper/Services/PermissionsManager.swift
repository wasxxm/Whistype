import AVFoundation
import AppKit
import Foundation

final class PermissionsManager: PermissionsChecking {
    var microphoneGranted: Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }

    var accessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    func requestMicrophone() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .audio)
    }

    func promptAccessibilityIfNeeded() {
        guard !accessibilityGranted else { return }
        guard !UserDefaults.standard.bool(forKey: "hasPromptedAccessibility") else { return }
        UserDefaults.standard.set(true, forKey: "hasPromptedAccessibility")
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    func openAccessibilitySettings() {
        let url = URL(
            string:
                "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        )!
        NSWorkspace.shared.open(url)
    }
}
