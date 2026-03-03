import SwiftUI

struct MenuBarIcon: View {
    @ObservedObject var coordinator: TranscriptionCoordinator

    var body: some View {
        Image(systemName: coordinator.state.isRecording
              ? "waveform.circle.fill"
              : "waveform.circle")
            .symbolRenderingMode(.hierarchical)
    }
}
