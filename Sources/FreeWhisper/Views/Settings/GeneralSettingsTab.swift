import SwiftUI

struct GeneralSettingsTab: View {
    @AppStorage("selectedModel") private var selectedModel = Constants.defaultModel
    @AppStorage("autoPasteEnabled") private var autoPasteEnabled = true
    @AppStorage("showCapsule") private var showCapsule = true
    @AppStorage("maxRecordingSeconds") private var maxRecordingSeconds =
        Constants.defaultMaxRecordingSeconds
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    private let availableModels = [
        "large-v3-turbo",
        "large-v3",
        "distil-large-v3",
        "base.en",
        "small.en",
    ]

    var body: some View {
        Form {
            Section("Transcription") {
                Picker("Model", selection: $selectedModel) {
                    ForEach(availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.menu)
                .help("Larger models are more accurate but slower.")
            }

            Section("Behavior") {
                Toggle("Auto-paste transcription", isOn: $autoPasteEnabled)
                    .help("Automatically paste text into the active app after transcription.")

                Toggle("Show floating capsule", isOn: $showCapsule)
                    .help("Show the recording indicator at the bottom of the screen.")

                Stepper(
                    "Max recording: \(maxRecordingSeconds)s",
                    value: $maxRecordingSeconds,
                    in: 10...300,
                    step: 10
                )
                .help("Automatically stop recording after this duration.")
            }

            Section("System") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .help("Start FreeWhisper when you log in to your Mac.")

                HStack {
                    Text("Hotkey")
                    Spacer()
                    Text("⌥ Space")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
