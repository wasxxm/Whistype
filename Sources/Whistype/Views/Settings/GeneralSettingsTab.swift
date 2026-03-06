import SwiftUI

struct GeneralSettingsTab: View {
    @AppStorage(Constants.Keys.selectedEngine) private var selectedEngine = Constants.defaultEngine
    @AppStorage(Constants.Keys.selectedModel) private var selectedModel = Constants.defaultModel
    @AppStorage(Constants.Keys.selectedQwen3Model) private var selectedQwen3Model = Constants.defaultQwen3Model
    @AppStorage(Constants.Keys.autoPasteEnabled) private var autoPasteEnabled = true
    @AppStorage(Constants.Keys.showCapsule) private var showCapsule = true
    @AppStorage(Constants.Keys.launchAtLogin) private var launchAtLogin = false

    private let availableEngines = [
        (Constants.EngineID.whisperKit, "WhisperKit (CoreML)"),
        (Constants.EngineID.qwen3, "Qwen3-ASR"),
    ]

    private let availableQwen3Models = [
        (Constants.EngineID.parakeet, "Parakeet TDT 0.6B (CoreML)"),
        (Constants.EngineID.qwen3, "Qwen3-ASR 0.6B (MLX)"),
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

                if selectedEngine == Constants.EngineID.whisperKit {
                    Picker("Model", selection: $selectedModel) {
                        ForEach(availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                } else {
                    Picker("Model", selection: $selectedQwen3Model) {
                        ForEach(availableQwen3Models, id: \.0) { model in
                            Text(model.1).tag(model.0)
                        }
                    }
                    .pickerStyle(.menu)
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
                        KeyCapView(text: "⌥", size: .small)
                        KeyCapView(text: "Space", size: .small)
                    }
                }
            } header: {
                Label("System", systemImage: "gearshape.2")
            }
        }
        .formStyle(.grouped)
    }
}