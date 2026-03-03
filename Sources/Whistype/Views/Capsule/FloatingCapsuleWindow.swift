import AppKit
import Combine
import SwiftUI

@MainActor
final class FloatingCapsuleWindowController {
    private var window: NSPanel?
    private var coordinator: TranscriptionCoordinator
    private var cancellable: AnyCancellable?
    private var isShowing = false

    init(coordinator: TranscriptionCoordinator) {
        self.coordinator = coordinator
        setupWindow()
        observeState()
    }

    func show() {
        guard !isShowing, let window, let screen = NSScreen.main else { return }
        isShowing = true

        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - Constants.capsuleWidth / 2
        let startY = screenFrame.minY + Constants.capsuleBottomPadding - 20
        let endY = screenFrame.minY + Constants.capsuleBottomPadding

        window.setFrame(
            NSRect(
                x: x, y: startY,
                width: Constants.capsuleWidth,
                height: Constants.capsuleHeight
            ),
            display: true
        )
        window.alphaValue = 0.0
        window.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.35
            context.timingFunction = CAMediaTimingFunction(
                controlPoints: 0.34, 1.56, 0.64, 1.0
            )
            window.animator().setFrame(
                NSRect(
                    x: x, y: endY,
                    width: Constants.capsuleWidth,
                    height: Constants.capsuleHeight
                ),
                display: true
            )
            window.animator().alphaValue = 1.0
        }
    }

    func hide() {
        guard isShowing, let window, let screen = NSScreen.main else { return }
        isShowing = false

        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - Constants.capsuleWidth / 2
        let targetY = screenFrame.minY + Constants.capsuleBottomPadding - 12

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().setFrame(
                NSRect(
                    x: x, y: targetY,
                    width: Constants.capsuleWidth,
                    height: Constants.capsuleHeight
                ),
                display: true
            )
            window.animator().alphaValue = 0.0
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
        panel.hasShadow = false
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
                let showCapsule = UserDefaults.standard.bool(forKey: Constants.Keys.showCapsule)
                guard showCapsule else { return }

                if state.shouldShowCapsule {
                    self?.show()
                } else {
                    self?.hide()
                }
            }
    }
}
