import Foundation
import HotKey

final class HotkeyService: HotkeyBinding {
    var onKeyDown: (() -> Void)?
    var onKeyUp: (() -> Void)?

    private var hotKey: HotKey?

    func register() {
        hotKey = HotKey(key: .space, modifiers: [.option])
        hotKey?.keyDownHandler = { [weak self] in
            self?.onKeyDown?()
        }
        hotKey?.keyUpHandler = { [weak self] in
            self?.onKeyUp?()
        }
    }

    func unregister() {
        hotKey = nil
    }
}
