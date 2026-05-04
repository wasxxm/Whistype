import AppKit
import ApplicationServices
import Foundation
import os

final class PasteService: OutputPasting {
    /// The app that was frontmost when recording started.
    private var savedFrontmostApp: NSRunningApplication?

    /// Wait this long after posting Cmd+V before reverting the clipboard.
    /// Native Cocoa apps process Cmd+V in <50 ms, Electron and browsers
    /// usually 100-300 ms. 1.0 s is well above the slow-app threshold while
    /// keeping the transcription visible on clipboard only briefly.
    /// 0.3 s (the original 1.0.3 value) was too short and let slow apps read
    /// the restored prior contents instead of the transcription.
    private static let restoreDelay: TimeInterval = 1.0

    /// Pending clipboard restore from the previous paste, if any. Cancelled
    /// when a new paste starts so a slow restore from one transcription
    /// doesn't clobber a fresh one. Pasteboard `changeCount` at the moment
    /// we wrote the transcription is captured alongside; if it changes
    /// (e.g. user manually copies during the restore window) we skip the
    /// restore so we don't undo their action.
    private var pendingRestore: DispatchWorkItem?

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
        // A pending restore from a previous paste would clobber this new
        // transcription if it fires after we set the clipboard. Cancel it now.
        pendingRestore?.cancel()
        pendingRestore = nil

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
        let restoreClipboard = UserDefaults.standard
            .bool(forKey: Constants.Keys.restoreClipboardAfterPaste)
        let snapshot = restoreClipboard ? captureClipboardSnapshot() : nil
        copyToClipboard(text: text)
        let changeCountAfterSet = NSPasteboard.general.changeCount
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self else { return }
            self.simulateCommandV()
            self.savedFrontmostApp = nil
            guard let snapshot else { return }
            self.scheduleClipboardRestore(
                snapshot: snapshot,
                expectedChangeCount: changeCountAfterSet
            )
        }
    }

    private func scheduleClipboardRestore(
        snapshot: [(NSPasteboard.PasteboardType, Data)],
        expectedChangeCount: Int
    ) {
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            // If the pasteboard changed since we set the transcription, the
            // user (or another app) wrote something else into the clipboard
            // during the restore window. Their newer write is more recent
            // intent than our pre-paste snapshot, so leave it alone.
            let currentCount = NSPasteboard.general.changeCount
            guard currentCount == expectedChangeCount else {
                Logger.paste.debug(
                    "Clipboard changed during restore window (expected \(expectedChangeCount), got \(currentCount)) — skipping restore"
                )
                self.pendingRestore = nil
                return
            }
            self.restoreClipboardSnapshot(snapshot)
            self.pendingRestore = nil
        }
        pendingRestore = work
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Self.restoreDelay,
            execute: work
        )
    }

    // MARK: - Clipboard preservation

    /// Captures every type currently on the general pasteboard so we can put
    /// it back after the Cmd+V fallback clobbered it with the transcription.
    /// SuperWhisper does the same — the user's clipboard appears untouched
    /// after dictation.
    private func captureClipboardSnapshot() -> [(NSPasteboard.PasteboardType, Data)] {
        let pb = NSPasteboard.general
        guard let types = pb.types else { return [] }
        return types.compactMap { type in
            guard let data = pb.data(forType: type) else { return nil }
            return (type, data)
        }
    }

    private func restoreClipboardSnapshot(_ snapshot: [(NSPasteboard.PasteboardType, Data)]) {
        let pb = NSPasteboard.general
        pb.clearContents()
        for (type, data) in snapshot {
            pb.setData(data, forType: type)
        }
        Logger.paste.debug("Clipboard restored to pre-paste state (\(snapshot.count) types)")
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
