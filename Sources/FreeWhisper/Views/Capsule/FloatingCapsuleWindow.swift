import AppKit
import Combine
import SwiftUI

@MainActor
final class FloatingCapsuleWindowController {
    private var window: NSPanel?
    private var coordinator: TranscriptionCoordinator
    private var cancellable: AnyCancellable?

    init(coordinator: TranscriptionCoordinator) {
        self.coordinator = coordinator
        setupWindow()
        observeState()
    }

    func show() {
        guard let window, let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - Constants.capsuleWidth / 2
        let y = screenFrame.minY + Constants.capsuleBottomPadding

        window.setFrame(
            NSRect(
                x: x, y: y,
                width: Constants.capsuleWidth,
                height: Constants.capsuleHeight
            ),
            display: true
        )

        window.makeKeyAndOrderFront(nil)
        window.animator().alphaValue = 1.0
    }

    func hide() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window?.animator().alphaValue = 0.0
        } completionHandler: { [weak self] in
            self?.window?.orderOut(nil)
        }
    }

    private func setupWindow() {
        let panel = NSPanel(
            contentRect: NSRect(
                x: 0, y: 0,
                width: Constants.capsuleWidth,
                height: Constants.capsuleHeight
            ),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.animationBehavior = .utilityWindow
        panel.isMovableByWindowBackground = false
        panel.alphaValue = 0.0

        let hostingView = NSHostingView(
            rootView: FloatingCapsuleView(coordinator: coordinator)
        )
        panel.contentView = hostingView

        self.window = panel
    }

    private func observeState() {
        cancellable = coordinator.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                let showCapsule = UserDefaults.standard.bool(forKey: "showCapsule")
                guard showCapsule else { return }

                if state.shouldShowCapsule {
                    self?.show()
                } else {
                    self?.hide()
                }
            }
    }
}
