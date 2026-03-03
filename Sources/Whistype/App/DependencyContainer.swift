import Foundation

@MainActor
final class DependencyContainer {
    let audioRecorder: AudioRecording
    let transcriptionService: Transcription
    let hotkeyService: HotkeyBinding
    let pasteService: OutputPasting
    let permissions: PermissionsChecking
    let coordinator: TranscriptionCoordinator

    init() {
        let recorder = AudioRecorderService()
        let engine = UserDefaults.standard.string(forKey: "selectedEngine") ?? Constants.defaultEngine
        let transcription: Transcription = engine == "qwen3-asr"
            ? Qwen3TranscriptionService()
            : WhisperTranscriptionService()
        let hotkey = HotkeyService()
        let paste = PasteService()
        let perms = PermissionsManager()

        self.audioRecorder = recorder
        self.transcriptionService = transcription
        self.hotkeyService = hotkey
        self.pasteService = paste
        self.permissions = perms

        self.coordinator = TranscriptionCoordinator(
            audioRecorder: recorder,
            transcriptionService: transcription,
            hotkeyService: hotkey,
            pasteService: paste,
            permissions: perms
        )
    }
}
