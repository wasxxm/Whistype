import SwiftUI

struct GeneralSettingsTab: View {
    @AppStorage("selectedEngine") private var selectedEngine = Constants.defaultEngine
    @AppStorage("selectedModel") private var selectedModel = Constants.defaultModel
    @AppStorage("autoPasteEnabled") private var autoPasteEnabled = true
    @AppStorage("showCapsule") private var showCapsule = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    private let availableEngines = [
        ("whisperkit", "WhisperKit (CoreML)"),
        ("qwen3-asr", "Qwen3-ASR (MLX)"),
    ]

    private let availableModels = [
        "large-v3_turbo",
        "large-v3",
        "distil-large-v3",
        "base.en",
        "small.en",
    ]

    var body: some View {
        Form {
            Section("Transcription") {
                Picker("Engine", selection: $selectedEngine) {
                    ForEach(availableEngines, id: \.0) { engine in
                        Text(engine.1).tag(engine.0)
                    }
                }
                .pickerStyle(.menu)

                if selectedEngine == "whisperkit" {
                    Picker("Model", selection: $selectedModel) {
                        ForEach(availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                    .help("Larger models are more accurate but slower.")
                } else {
                    HStack {
                        Text("Model")
                        Spacer()
                        Text("Qwen3-ASR-0.6B (4-bit)")
                            .foregroundStyle(.secondary)
                    }
                }

            }

            Section("Behavior") {
                Toggle("Auto-paste transcription", isOn: $autoPasteEnabled)
                    .help("Automatically paste text into the active app after transcription.")

                Toggle("Show floating capsule", isOn: $showCapsule)
                    .help("Show the recording indicator at the bottom of the screen.")
            }

            Section("System") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .help("Start Whistype when you log in to your Mac.")

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
