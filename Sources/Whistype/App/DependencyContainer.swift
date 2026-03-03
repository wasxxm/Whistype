import Combine
import Foundation

@MainActor
final class DependencyContainer {
    let audioRecorder: AudioRecording
    let hotkeyService: HotkeyBinding
    let pasteService: OutputPasting
    let permissions: PermissionsChecking
    let coordinator: TranscriptionCoordinator

    private var _whisperService: WhisperTranscriptionService?
    private var _qwen3Service: Qwen3TranscriptionService?
    private var engineCancellable: AnyCancellable?
    private var activeEngine: String

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
        self.activeEngine = engine

        // Only create the service for the selected engine
        let initialService: Transcription
        if engine == "qwen3-asr" {
            let service = Qwen3TranscriptionService()
            _qwen3Service = service
            initialService = service
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
    }

    private func observeEngineChanges() {
        engineCancellable = UserDefaults.standard
            .publisher(for: \.selectedEngine)
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] newEngine in
                guard let self else { return }
                let engine = newEngine ?? Constants.defaultEngine
                guard engine != self.activeEngine else { return }
                self.activeEngine = engine
                let newService: Transcription = engine == "qwen3-asr"
                    ? self.qwen3Service : self.whisperService
                NSLog("[Whistype] Engine changed to: %@", engine)
                Task {
                    await self.coordinator.switchEngine(to: newService)
                }
            }
    }
}

// MARK: - KVO-compatible key for selectedEngine

extension UserDefaults {
    @objc var selectedEngine: String? {
        string(forKey: Constants.Keys.selectedEngine)
    }
}
