import Foundation

@MainActor
final class DependencyContainer {
    let audioRecorder: AudioRecording
    let hotkeyService: HotkeyBinding
    let pasteService: OutputPasting
    let permissions: PermissionsChecking
    let coordinator: TranscriptionCoordinator

    private let whisperService = WhisperTranscriptionService()
    private let qwen3Service = Qwen3TranscriptionService()
    private var engineObserver: NSObjectProtocol?
    private var activeEngine: String = UserDefaults.standard.string(forKey: "selectedEngine") ?? Constants.defaultEngine

    init() {
        let recorder = AudioRecorderService()
        let hotkey = HotkeyService()
        let paste = PasteService()
        let perms = PermissionsManager()

        self.audioRecorder = recorder
        self.hotkeyService = hotkey
        self.pasteService = paste
        self.permissions = perms

        let engine = UserDefaults.standard.string(forKey: "selectedEngine") ?? Constants.defaultEngine
        let initialService: Transcription = engine == "qwen3-asr" ? qwen3Service : whisperService

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
        engineObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleEngineChange()
        }
    }

    private func handleEngineChange() {
        let engine = UserDefaults.standard.string(forKey: "selectedEngine") ?? Constants.defaultEngine
        guard engine != activeEngine else { return }
        activeEngine = engine
        let newService: Transcription = engine == "qwen3-asr" ? qwen3Service : whisperService
        NSLog("[Whistype] Engine changed to: %@", engine)
        Task {
            await coordinator.switchEngine(to: newService)
        }
    }
}
