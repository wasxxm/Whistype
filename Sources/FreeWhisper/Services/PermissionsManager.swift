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

    func openAccessibilitySettings() {
        let url = URL(
            string:
                "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        )!
        NSWorkspace.shared.open(url)
    }
}
