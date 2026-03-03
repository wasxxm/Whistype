import AppKit
import ApplicationServices
import Foundation

final class PasteService: OutputPasting {
    /// The app that was frontmost when recording started.
    private var savedFrontmostApp: NSRunningApplication?

    func saveFrontmostApp() {
        savedFrontmostApp = NSWorkspace.shared.frontmostApplication
        NSLog(
            "[Whistype] Saved frontmost app: %@",
            savedFrontmostApp?.localizedName ?? "nil"
        )
    }

    func paste(text: String) {
        // Re-activate the app that was in focus before recording
        if let app = savedFrontmostApp {
            NSLog("[Whistype] Re-activating: %@", app.localizedName ?? "unknown")
            app.activate()
        }

        if !AXIsProcessTrusted() {
            NSLog("[Whistype] AX not trusted — prompting and copying to clipboard")
            copyToClipboard(text: text)
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            savedFrontmostApp = nil
            return
        }

        // Strategy 1: Accessibility API — insert text directly at cursor
        if insertViaAccessibility(text: text) {
            NSLog("[Whistype] Text inserted via Accessibility API")
            savedFrontmostApp = nil
            return
        }

        // Strategy 2: Clipboard + simulated Cmd+V
        NSLog("[Whistype] AX insert failed, falling back to Cmd+V")
        copyToClipboard(text: text)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.simulateCommandV()
            self?.savedFrontmostApp = nil
        }
    }

    func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        NSLog("[Whistype] Text copied to clipboard (%d chars)", text.count)
    }

    // MARK: - Strategy 1: Accessibility API

    private static let textRoles: Set<String> = [kAXTextFieldRole, kAXTextAreaRole]

    private func insertViaAccessibility(text: String) -> Bool {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedRef: CFTypeRef?
        let focusErr = AXUIElementCopyAttributeValue(
            systemWide, kAXFocusedUIElementAttribute as CFString, &focusedRef
        )
        guard focusErr == .success, let focused = focusedRef else {
            NSLog("[Whistype] AX: No focused element (err %d)", focusErr.rawValue)
            return false
        }

        let element = focused as! AXUIElement

        var roleRef: CFTypeRef?
        let roleErr = AXUIElementCopyAttributeValue(
            element, kAXRoleAttribute as CFString, &roleRef
        )
        guard roleErr == .success, let role = roleRef as? String else {
            NSLog("[Whistype] AX: Cannot read element role")
            return false
        }
        NSLog("[Whistype] AX: Focused element role = %@", role)

        guard Self.textRoles.contains(role) else {
            NSLog("[Whistype] AX: Not a text input role (%@)", role)
            return false
        }

        // Read value before insertion to verify it actually changed
        let valueBefore = readAXValue(element)

        let setErr = AXUIElementSetAttributeValue(
            element, kAXSelectedTextAttribute as CFString, text as CFTypeRef
        )
        guard setErr == .success else {
            NSLog("[Whistype] AX: Set selected text failed (err %d)", setErr.rawValue)
            return false
        }

        // Verify the value actually changed (some apps report success but don't insert)
        if let before = valueBefore {
            let after = readAXValue(element)
            if before == after {
                NSLog("[Whistype] AX: Value unchanged — app ignores AX insertion")
                return false
            }
        }

        return true
    }

    private func readAXValue(_ element: AXUIElement) -> String? {
        var valueRef: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(
            element, kAXValueAttribute as CFString, &valueRef
        )
        guard err == .success, let str = valueRef as? String else { return nil }
        return str
    }

    // MARK: - Strategy 2: CGEvent Cmd+V

    private func simulateCommandV() {
        let source = CGEventSource(stateID: .hidSystemState)
        let vKeyCode: CGKeyCode = 0x09

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        else {
            NSLog("[Whistype] CGEvent creation failed, trying AppleScript")
            simulateAppleScriptPaste()
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        usleep(50_000)  // 50ms between key down and up
        keyUp.post(tap: .cghidEventTap)

        NSLog("[Whistype] CGEvent Cmd+V posted via cghidEventTap")
    }

    private func simulateAppleScriptPaste() {
        let script = NSAppleScript(source: """
            tell application "System Events"
                keystroke "v" using command down
            end tell
        """)
        var error: NSDictionary?
        script?.executeAndReturnError(&error)
        if let error {
            NSLog("[Whistype] AppleScript paste error: %@", error)
        } else {
            NSLog("[Whistype] AppleScript paste executed")
        }
    }
}
