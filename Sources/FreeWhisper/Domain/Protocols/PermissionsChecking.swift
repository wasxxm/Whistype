import Foundation

protocol PermissionsChecking: AnyObject {
    var microphoneGranted: Bool { get }
    var accessibilityGranted: Bool { get }
    func requestMicrophone() async -> Bool
    func promptAccessibilityIfNeeded()
    func openAccessibilitySettings()
}
