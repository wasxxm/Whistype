import Foundation

@MainActor
final class DependencyContainer: ObservableObject {
    let audioRecorder: AudioRecording
    let transcriptionService: Transcription
    let hotkeyService: HotkeyBinding
    let pasteService: OutputPasting
    let permissions: PermissionsChecking
    let coordinator: TranscriptionCoordinator

    init() {
        let recorder = AudioRecorderService()
        let transcription = WhisperTranscriptionService()
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
