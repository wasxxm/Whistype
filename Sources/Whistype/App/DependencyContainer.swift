import Combine
import Foundation
import os

@MainActor
final class DependencyContainer {
    let audioRecorder: AudioRecording
    let hotkeyService: HotkeyBinding
    let pasteService: OutputPasting
    let permissions: PermissionsChecking
    let coordinator: TranscriptionCoordinator

    private var _whisperService: WhisperTranscriptionService?
    private var _qwen3Service: Qwen3TranscriptionService?
    private var _parakeetService: ParakeetTranscriptionService?
    private var engineCancellable: AnyCancellable?
    private var qwen3ModelCancellable: AnyCancellable?
    private var whisperModelCancellable: AnyCancellable?
    private var activeEngine: String
    private var activeQwen3Model: String
    private var activeWhisperModel: String

    var whisperService: WhisperTranscriptionService {
        if let existing = _whisperService { return existing }
        let service = WhisperTranscriptionService()
        _whisperService = service
        return service
    }

    var qwen3Service: Qwen3TranscriptionService {
        if let existing = _qwen3Service { return existing }
        let service = Qwen3TranscriptionService()
        _qwen3Service = service
        return service
    }

    var parakeetService: ParakeetTranscriptionService {
        if let existing = _parakeetService { return existing }
        let service = ParakeetTranscriptionService()
        _parakeetService = service
        return service
    }

    init() {
        let recorder = AudioRecorderService()
        let hotkey = HotkeyService()
        let paste = PasteService()
        let perms = PermissionsManager()

        self.audioRecorder = recorder
        self.hotkeyService = hotkey
        self.pasteService = paste
        self.permissions = perms

        let engine = UserDefaults.standard.string(forKey: Constants.Keys.selectedEngine)
            ?? Constants.defaultEngine
        let qwen3Model = UserDefaults.standard.string(forKey: Constants.Keys.selectedQwen3Model)
            ?? Constants.defaultQwen3Model
        let whisperModel = UserDefaults.standard.string(forKey: Constants.Keys.selectedModel)
            ?? Constants.defaultModel
        self.activeEngine = engine
        self.activeQwen3Model = qwen3Model
        self.activeWhisperModel = whisperModel

        let initialService: Transcription
        if engine == Constants.EngineID.qwen3 {
            if qwen3Model == Constants.EngineID.parakeet {
                let service = ParakeetTranscriptionService()
                _parakeetService = service
                initialService = service
            } else {
                let service = Qwen3TranscriptionService()
                _qwen3Service = service
                initialService = service
            }
        } else {
            let service = WhisperTranscriptionService()
            _whisperService = service
            initialService = service
        }

        self.coordinator = TranscriptionCoordinator(
            audioRecorder: recorder,
            transcriptionService: initialService,
            hotkeyService: hotkey,
            pasteService: paste,
            permissions: perms
        )

        observeEngineChanges()
        observeQwen3ModelChanges()
        observeWhisperModelChanges()
    }

    private func resolveQwen3FamilyService() -> Transcription {
        if activeQwen3Model == Constants.EngineID.parakeet {
            return parakeetService
        }
        return qwen3Service
    }

    /// Release inactive transcription engines so their model weights (1-3 GB each)
    /// don't sit resident after the user switches engines. The cost on switch-back
    /// is a fresh load (3-5 s once cached on disk), which is acceptable for a
    /// settings-driven action versus the memory savings on lower-RAM Macs.
    private func releaseInactiveEngineServices(active: Transcription) {
        if !(active is WhisperTranscriptionService) { _whisperService = nil }
        if !(active is Qwen3TranscriptionService)   { _qwen3Service = nil }
        if !(active is ParakeetTranscriptionService) { _parakeetService = nil }
    }

    private func observeEngineChanges() {
        engineCancellable = UserDefaults.standard
            .publisher(for: \.selectedEngine)
            .removeDuplicates()
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newEngine in
                guard let self else { return }
                let engine = newEngine ?? Constants.defaultEngine
                guard engine != self.activeEngine else { return }
                self.activeEngine = engine
                let newService: Transcription = engine == Constants.EngineID.qwen3
                    ? self.resolveQwen3FamilyService() : self.whisperService
                Logger.app.info("Engine changed to: \(engine)")
                self.releaseInactiveEngineServices(active: newService)
                Task {
                    await self.coordinator.switchEngine(to: newService)
                }
            }
    }

    private func observeQwen3ModelChanges() {
        qwen3ModelCancellable = UserDefaults.standard
            .publisher(for: \.selectedQwen3Model)
            .removeDuplicates()
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newModel in
                guard let self else { return }
                let model = newModel ?? Constants.defaultQwen3Model
                guard model != self.activeQwen3Model else { return }
                self.activeQwen3Model = model
                guard self.activeEngine == Constants.EngineID.qwen3 else { return }
                let newService = self.resolveQwen3FamilyService()
                Logger.app.info("Qwen3 sub-model changed to: \(model)")
                self.releaseInactiveEngineServices(active: newService)
                Task {
                    await self.coordinator.switchEngine(to: newService)
                }
            }
    }

    /// Reload WhisperKit when the user picks a different Whisper model in Settings.
    /// `coordinator.switchEngine` re-runs `loadModel` against the same service
    /// instance, which calls `WhisperKit(config)` with the new model name and lets
    /// ARC release the old CoreML kit.
    private func observeWhisperModelChanges() {
        whisperModelCancellable = UserDefaults.standard
            .publisher(for: \.selectedModel)
            .removeDuplicates()
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newModel in
                guard let self else { return }
                let model = newModel ?? Constants.defaultModel
                guard model != self.activeWhisperModel else { return }
                self.activeWhisperModel = model
                guard self.activeEngine == Constants.EngineID.whisperKit else { return }
                Logger.app.info("WhisperKit model changed to: \(model)")
                Task {
                    await self.coordinator.switchEngine(to: self.whisperService)
                }
            }
    }
}

// MARK: - KVO-compatible keys for UserDefaults

extension UserDefaults {
    @objc var selectedEngine: String? {
        string(forKey: Constants.Keys.selectedEngine)
    }

    @objc var selectedQwen3Model: String? {
        string(forKey: Constants.Keys.selectedQwen3Model)
    }

    @objc var selectedModel: String? {
        string(forKey: Constants.Keys.selectedModel)
    }
}
