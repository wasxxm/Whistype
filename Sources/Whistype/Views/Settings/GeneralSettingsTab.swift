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
            Section {
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
                } else {
                    LabeledContent("Model") {
                        Text("Qwen3-ASR-0.6B (4-bit)")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Label("Transcription", systemImage: "waveform")
            }

            Section {
                Toggle("Auto-paste transcription", isOn: $autoPasteEnabled)
                Toggle("Show floating capsule", isOn: $showCapsule)
            } header: {
                Label("Behavior", systemImage: "hand.tap")
            }

            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)

                LabeledContent("Hotkey") {
                    HStack(spacing: 3) {
                        SettingsKeyCap(text: "⌥")
                        SettingsKeyCap(text: "Space")
                    }
                }
            } header: {
                Label("System", systemImage: "gearshape.2")
            }
        }
        .formStyle(.grouped)
    }
}

private struct SettingsKeyCap: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.caption, design: .rounded, weight: .medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(.separator, lineWidth: 0.5)
            )
    }
}
