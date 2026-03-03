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
        .overlay(borderOverlay)
        .shadow(color: shadowColor, radius: 16, y: 6)
        .animation(.easeInOut(duration: 0.3), value: coordinator.state.stateKey)
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
            Color.red.opacity(0.08)
        case .done:
            Color.green.opacity(0.06)
        case .error:
            Color.red.opacity(0.1)
        default:
            Color.clear
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch coordinator.state {
        case .recording:
            RoundedRectangle(cornerRadius: Constants.capsuleCornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [.red.opacity(0.6), .red.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1.5
                )
        case .transcribing:
            RoundedRectangle(cornerRadius: Constants.capsuleCornerRadius)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
        default:
            RoundedRectangle(cornerRadius: Constants.capsuleCornerRadius)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        }
    }

    private var shadowColor: Color {
        switch coordinator.state {
        case .recording: .red.opacity(0.15)
        case .done: .green.opacity(0.1)
        default: .black.opacity(0.25)
        }
    }

    @ViewBuilder
    private var capsuleContent: some View {
        switch coordinator.state {
        case .recording(let startTime):
            RecordingContent(audioLevel: coordinator.audioLevel, startTime: startTime)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        case .transcribing:
            TranscribingContent()
                .transition(.opacity)
        case .done(let text):
            DoneContent(text: text)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        case .error(let message):
            ErrorContent(message: message)
                .transition(.opacity)
        case .idle:
            EmptyView()
        }
    }
}

// MARK: - Recording

private struct RecordingContent: View {
    let audioLevel: Float
    let startTime: Date
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 14) {
            recordingDot
            AudioLevelIndicator(level: audioLevel)
            Spacer()
            timerLabel
        }
        .padding(.horizontal, 20)
    }

    private var recordingDot: some View {
        ZStack {
            Circle()
                .fill(Color.red.opacity(0.25))
                .frame(width: 16, height: 16)
                .scaleEffect(isPulsing ? 1.4 : 0.8)
                .opacity(isPulsing ? 0 : 0.6)
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }

    private var timerLabel: some View {
        Text(startTime, style: .timer)
            .font(.system(.callout, design: .monospaced).weight(.medium))
            .foregroundStyle(.white.opacity(0.7))
    }
}

// MARK: - Transcribing

private struct TranscribingContent: View {
    @State private var dotIndex = 0
    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "waveform")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .symbolEffect(.variableColor.iterative, options: .repeating)

            Text("Transcribing")
                .font(.system(.callout, design: .rounded).weight(.medium))
                .foregroundStyle(.white.opacity(0.7))

            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(.white.opacity(dotIndex == i ? 0.7 : 0.25))
                        .frame(width: 4, height: 4)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onReceive(timer) { _ in
            dotIndex = (dotIndex + 1) % 3
        }
    }
}

// MARK: - Done

private struct DoneContent: View {
    let text: String
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 17))
                .foregroundStyle(.green)
                .scaleEffect(appeared ? 1.0 : 0.3)
                .opacity(appeared ? 1.0 : 0)

            Text(text)
                .font(.system(.callout, design: .rounded))
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(.white.opacity(0.85))

            Spacer()
        }
        .padding(.horizontal, 20)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
    }
}

// MARK: - Error

private struct ErrorContent: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 15))
                .foregroundStyle(.red.opacity(0.9))

            Text(message)
                .font(.system(.caption, design: .rounded).weight(.medium))
                .lineLimit(1)
                .foregroundStyle(.white.opacity(0.6))

            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Visual Effect

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
