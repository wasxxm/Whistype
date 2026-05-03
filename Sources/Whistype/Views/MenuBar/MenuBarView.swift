import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var coordinator: TranscriptionCoordinator
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            statusSection

            Divider()

            actionSection

            Divider()

            appSection
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch coordinator.loadingStatus {
            case .idle:
                Label("Initializing...", systemImage: "circle.dashed")
                    .foregroundStyle(.secondary)

            case .downloading(let progress):
                Label(
                    "Downloading model: \(Int(progress * 100))%",
                    systemImage: "arrow.down.circle"
                )
                .foregroundStyle(.orange)

                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .padding(.horizontal, 4)

            case .prewarming:
                Label("Optimizing for your device...", systemImage: "cpu")
                    .foregroundStyle(.orange)

            case .loading:
                Label("Loading model...", systemImage: "memorychip")
                    .foregroundStyle(.orange)

            case .ready:
                Label("Ready", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)

            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .lineLimit(2)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var actionSection: some View {
        if coordinator.state.isRecording {
            Label("Recording... release ⌥ Space to stop", systemImage: "mic.fill")
                .foregroundStyle(.red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        } else if !coordinator.isModelLoaded {
            Text("Model loading...")
                .font(.caption)
                .foregroundStyle(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        } else {
            Text("Hold ⌥ Space to record")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }

        Button {
            // .accessory activation policy means openWindow alone won't bring
            // the app forward; the History window opens behind whatever the
            // user is currently in. Activate explicitly first.
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "history")
        } label: {
            Label("History", systemImage: "clock.arrow.circlepath")
        }
    }

    @ViewBuilder
    private var appSection: some View {
        Button {
            // Same .accessory issue as History — SettingsLink opens the window
            // but doesn't bring the app to the front. Use openSettings + an
            // explicit activate so the window lands on top.
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        } label: {
            Label("Settings...", systemImage: "gear")
        }
        .keyboardShortcut(",", modifiers: .command)

        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Label("Quit Whistype", systemImage: "power")
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
