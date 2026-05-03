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

    /// Models in descending order of accuracy. The first entry, `auto`, resolves
    /// at load time to WhisperKit's chip-aware default — the OpenAI Whisper Large V3
    /// Turbo (Sept 2024 release with the 4-layer decoder) on M2/M3/M4, or its 4-bit
    /// compressed variant on M1. The remaining entries let power users override.
    private let availableModels: [(id: String, label: String)] = [
        (Constants.WhisperModelID.auto, "Recommended for this Mac"),
        (Constants.WhisperModelID.largeV3TurboV20240930, "Whisper Large V3 Turbo - balanced"),
        (Constants.WhisperModelID.largeV3TurboV20240930Streaming, "Whisper Large V3 Turbo - streaming"),
        (Constants.WhisperModelID.largeV3TurboV20240930Compressed, "Whisper Large V3 Turbo - 4-bit (compact)"),
        (Constants.WhisperModelID.distilLargeV3Turbo, "Distil Whisper Large V3 Turbo - fastest large"),
        (Constants.WhisperModelID.distilLargeV3TurboCompressed, "Distil Whisper Large V3 Turbo - 4-bit"),
        (Constants.WhisperModelID.largeV3, "Whisper Large V3 - highest accuracy"),
        (Constants.WhisperModelID.smallEn, "Whisper Small (English) - lightweight"),
        (Constants.WhisperModelID.baseEn, "Whisper Base (English) - smallest"),
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
                        ForEach(availableModels, id: \.id) { model in
                            Text(model.label).tag(model.id)
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