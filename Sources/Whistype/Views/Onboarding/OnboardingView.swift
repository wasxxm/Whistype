import SwiftUI

struct OnboardingView: View {
    let permissions: PermissionsManager
    @ObservedObject var coordinator: TranscriptionCoordinator
    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var micGranted = false
    @State private var accessibilityGranted = false
    @State private var modelDownloadProgress: String?

    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 0) {
            stepIndicator
                .padding(.top, 24)

            Spacer()

            stepContent
                .frame(maxWidth: 360)

            Spacer()

            navigationButtons
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 40)
        .frame(width: 480, height: 560)
    }

    @ViewBuilder
    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            welcomeStep
        case 1:
            microphoneStep
        case 2:
            accessibilityStep
        case 3:
            readyStep
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("Whistype")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Free, fast, on-device speech-to-text. Press ⌥ Space anywhere to start dictating.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.body)
        }
    }

    @ViewBuilder
    private var microphoneStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)

            Text("Microphone Access")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Whistype needs your microphone to capture speech for transcription. Audio never leaves your device.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Grant Access") {
                Task {
                    micGranted = await permissions.requestMicrophone()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(micGranted)

            if micGranted {
                Label("Microphone access granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }

    @ViewBuilder
    private var accessibilityStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.raised.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.purple)

            Text("Accessibility Access")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Optional. Enables auto-paste into the active app after transcription. Without this, text is copied to clipboard only.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Open System Settings") {
                permissions.openAccessibilitySettings()
            }
            .buttonStyle(.borderedProminent)

            if permissions.accessibilityGranted {
                Label("Accessibility access granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }

    @ViewBuilder
    private var readyStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)

            Text("You're All Set")
                .font(.title2)
                .fontWeight(.semibold)

            Text("The Whisper model will download automatically on first use. Press ⌥ Space anywhere to start dictating.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            hotkeyDisplay
        }
    }

    @ViewBuilder
    private var hotkeyDisplay: some View {
        HStack(spacing: 4) {
            KeyCapView(text: "⌥")
            Text("+")
                .foregroundStyle(.secondary)
            KeyCapView(text: "Space")
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button("Back") {
                    withAnimation { currentStep -= 1 }
                }
            }

            Spacer()

            if currentStep < totalSteps - 1 {
                Button("Continue") {
                    withAnimation { currentStep += 1 }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Start Using Whistype") {
                    onComplete()
                    NSApplication.shared.keyWindow?.close()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

struct KeyCapView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.title3, design: .rounded, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
    }
}
