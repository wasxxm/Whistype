import SwiftUI

struct MenuBarView: View {
    @ObservedObject var coordinator: TranscriptionCoordinator
    @Environment(\.openWindow) private var openWindow

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
        Group {
            if coordinator.isModelLoaded {
                Label("Ready", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Label("Loading model...", systemImage: "arrow.down.circle")
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var actionSection: some View {
        Button {
            coordinator.toggle()
        } label: {
            if coordinator.state.isRecording {
                Label("Stop Recording", systemImage: "stop.circle")
            } else {
                Label("Start Recording (⌥ Space)", systemImage: "mic.circle")
            }
        }
        .keyboardShortcut(.space, modifiers: .option)
        .disabled(!coordinator.isModelLoaded)

        Button {
            openWindow(id: "history")
        } label: {
            Label("History", systemImage: "clock.arrow.circlepath")
        }
    }

    @ViewBuilder
    private var appSection: some View {
        SettingsLink {
            Label("Settings...", systemImage: "gear")
        }
        .keyboardShortcut(",", modifiers: .command)

        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Label("Quit FreeWhisper", systemImage: "power")
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
