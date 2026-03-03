import SwiftUI

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            Text(Constants.appName)
                .font(.title)
                .fontWeight(.semibold)

            Text("Free, open-source speech-to-text for macOS")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()
                .frame(width: 200)

            VStack(spacing: 8) {
                infoRow(label: "Version", value: appVersion)
                infoRow(label: "Engine", value: "WhisperKit (CoreML)")
                infoRow(label: "License", value: "MIT")
            }

            Spacer()

            Link("View on GitHub", destination: URL(string: "https://github.com/InnoWazi/FreeWhisper")!)
                .font(.subheadline)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .frame(width: 220)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}
