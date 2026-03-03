import Foundation
import HotKey

final class HotkeyService: HotkeyBinding {
    var onToggle: (() -> Void)?

    private var hotKey: HotKey?

    func register() {
        hotKey = HotKey(key: .space, modifiers: [.option])
        hotKey?.keyDownHandler = { [weak self] in
            self?.onToggle?()
        }
    }

    func unregister() {
        hotKey = nil
    }
}
