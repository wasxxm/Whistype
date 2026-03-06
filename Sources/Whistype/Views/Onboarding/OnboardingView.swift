import SwiftUI

struct OnboardingView: View {
    let permissions: PermissionsChecking
    @ObservedObject var coordinator: TranscriptionCoordinator
    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var micGranted = false
    @State private var accessibilityPrompted = false

    private let totalSteps = 3

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
            permissionsStep
        case 2:
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
    private var permissionsStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            Text("Permissions")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Whistype needs microphone access to capture speech, and accessibility access to paste transcribed text into any app.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Grant Access") {
                Task {
                    micGranted = await permissions.requestMicrophone()
                    permissions.promptAccessibilityIfNeeded()
                    accessibilityPrompted = true
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(micGranted)

            VStack(alignment: .leading, spacing: 10) {
                permissionRow(
                    icon: "mic.fill",
                    color: .orange,
                    label: "Microphone",
                    granted: micGranted
                )
                permissionRow(
                    icon: "hand.raised.fill",
                    color: .purple,
                    label: "Accessibility",
                    granted: permissions.accessibilityGranted
                )
            }
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private func permissionRow(icon: String, color: Color, label: String, granted: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(label)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: granted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(granted ? .green : .secondary)
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
