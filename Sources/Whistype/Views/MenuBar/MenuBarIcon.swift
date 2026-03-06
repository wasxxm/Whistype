import SwiftUI

struct MenuBarIcon: View {
    @ObservedObject var coordinator: TranscriptionCoordinator

    var body: some View {
        Image(systemName: iconName)
            .symbolRenderingMode(.hierarchical)
    }

    private var iconName: String {
        if coordinator.state.isRecording {
            return "waveform.circle.fill"
        } else if coordinator.state.isTranscribing {
            return "waveform.badge.magnifyingglass"
        } else {
            return "waveform.circle"
        }
    }
}
