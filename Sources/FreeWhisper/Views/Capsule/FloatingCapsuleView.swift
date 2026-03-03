import SwiftUI

struct FloatingCapsuleView: View {
    @ObservedObject var coordinator: TranscriptionCoordinator

    var body: some View {
        ZStack {
            capsuleBackground
            capsuleContent
        }
        .frame(width: Constants.capsuleWidth, height: Constants.capsuleHeight)
        .clipShape(RoundedRectangle(cornerRadius: Constants.capsuleCornerRadius))
        .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
    }

    @ViewBuilder
    private var capsuleBackground: some View {
        ZStack {
            VisualEffectBackground()
            backgroundTint
        }
    }

    @ViewBuilder
    private var backgroundTint: some View {
        switch coordinator.state {
        case .recording:
            Color.red.opacity(0.1)
        case .done:
            Color.green.opacity(0.1)
        case .error:
            Color.red.opacity(0.15)
        default:
            Color.clear
        }
    }

    @ViewBuilder
    private var capsuleContent: some View {
        switch coordinator.state {
        case .recording(let startTime):
            RecordingContent(
                audioLevel: coordinator.audioLevel,
                startTime: startTime
            )
        case .transcribing:
            TranscribingContent()
        case .done(let text):
            DoneContent(text: text)
        case .error(let message):
            ErrorContent(message: message)
        case .idle:
            EmptyView()
        }
    }
}

private struct RecordingContent: View {
    let audioLevel: Float
    let startTime: Date

    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .opacity(isPulsing ? 0.7 : 1.0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever()) {
                        isPulsing = true
                    }
                }

            AudioLevelIndicator(level: audioLevel)

            Spacer()

            Text(startTime, style: .timer)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
    }
}

private struct TranscribingContent: View {
    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)

            Text("Transcribing...")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct DoneContent: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 16))

            Text(text)
                .font(.system(.body, design: .rounded))
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

private struct ErrorContent: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.system(size: 16))

            Text(message)
                .font(.system(.caption, design: .rounded))
                .lineLimit(1)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
