import SwiftUI

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(Constants.appName)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 12)

            Text("Version \(appVersion)")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)

            Text("Free, open-source speech-to-text for macOS")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            VStack(spacing: 6) {
                infoRow(label: "Engines", value: "WhisperKit / Qwen3-ASR")
                infoRow(label: "License", value: "MIT")
            }
            .padding(.top, 20)

            Spacer()

            Link(destination: URL(string: "https://github.com/InnoWazi/Whistype")!) {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                    Text("View on GitHub")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.tertiary)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(width: 240)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}
