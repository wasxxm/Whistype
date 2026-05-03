import AppKit
import ApplicationServices
import Foundation
import os

final class PasteService: OutputPasting {
    /// The app that was frontmost when recording started.
    private var savedFrontmostApp: NSRunningApplication?

    private lazy var cachedPasteScript: NSAppleScript? = {
        let script = NSAppleScript(source: """
            tell application "System Events"
                keystroke "v" using command down
            end tell
        """)
        script?.compileAndReturnError(nil)
        return script
    }()

    func saveFrontmostApp() {
        savedFrontmostApp = NSWorkspace.shared.frontmostApplication
        Logger.paste.debug("Saved frontmost app: \(self.savedFrontmostApp?.localizedName ?? "nil")")
    }

    func paste(text: String) {
        if !AXIsProcessTrusted() {
            // PermissionsManager already prompts for accessibility once at first
            // launch (see Constants.Keys.hasPromptedAccessibility). Re-triggering
            // the system prompt on every paste is noisy; just fall back to
            // clipboard-only and let the user grant access at their own pace.
            Logger.paste.info("AX not trusted — falling back to clipboard-only")
            copyToClipboard(text: text)
            savedFrontmostApp = nil
            return
        }

        // Re-activate the app that was in focus before recording
        if let app = savedFrontmostApp {
            Logger.paste.debug("Re-activating: \(app.localizedName ?? "unknown")")
            app.activate()
        }

        // Strategy 1: Accessibility API — insert text directly at cursor
        if insertViaAccessibility(text: text) {
            Logger.paste.info("Text inserted via Accessibility API")
            savedFrontmostApp = nil
            return
        }

        // Strategy 2: Clipboard + simulated Cmd+V
        Logger.paste.info("AX insert failed, falling back to Cmd+V")
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
        Logger.paste.debug("Text copied to clipboard (\(text.count) chars)")
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
            Logger.paste.debug("AX: No focused element (err \(focusErr.rawValue))")
            return false
        }

        // CFTypeRef is toll-free bridged to AXUIElement (cast always succeeds)
        let element = focused as! AXUIElement

        var roleRef: CFTypeRef?
        let roleErr = AXUIElementCopyAttributeValue(
            element, kAXRoleAttribute as CFString, &roleRef
        )
        guard roleErr == .success, let role = roleRef as? String else {
            Logger.paste.debug("AX: Cannot read element role")
            return false
        }
        Logger.paste.debug("AX: Focused element role = \(role)")

        guard Self.textRoles.contains(role) else {
            Logger.paste.debug("AX: Not a text input role (\(role))")
            return false
        }

        // Read value before insertion to verify it actually changed
        let valueBefore = readAXValue(element)

        let setErr = AXUIElementSetAttributeValue(
            element, kAXSelectedTextAttribute as CFString, text as CFTypeRef
        )
        guard setErr == .success else {
            Logger.paste.debug("AX: Set selected text failed (err \(setErr.rawValue))")
            return false
        }

        // Verify the value actually changed (some apps report success but don't insert)
        if let before = valueBefore {
            let after = readAXValue(element)
            if before == after {
                Logger.paste.debug("AX: Value unchanged — app ignores AX insertion")
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
            Logger.paste.error("CGEvent creation failed, trying AppleScript")
            simulateAppleScriptPaste()
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        Logger.paste.debug("CGEvent Cmd+V posted via cghidEventTap")
    }

    private func simulateAppleScriptPaste() {
        var error: NSDictionary?
        cachedPasteScript?.executeAndReturnError(&error)
        if let error {
            Logger.paste.error("AppleScript paste error: \(error)")
        } else {
            Logger.paste.debug("AppleScript paste executed")
        }
    }
}
