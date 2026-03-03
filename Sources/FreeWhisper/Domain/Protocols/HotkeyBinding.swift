import Foundation

protocol HotkeyBinding: AnyObject {
    var onToggle: (() -> Void)? { get set }
    func register()
    func unregister()
}
