import Combine
import Foundation
import SwiftData

@MainActor
final class TranscriptionCoordinator: ObservableObject {
    @Published private(set) var state: TranscriptionState = .idle
    @Published private(set) var audioLevel: Float = 0
    @Published private(set) var isModelLoaded = false
    @Published private(set) var loadingStatus: ModelLoadingStatus = .idle

    private let audioRecorder: AudioRecording
    private let transcriptionService: Transcription
    private let hotkeyService: HotkeyBinding
    private let pasteService: OutputPasting
    private let permissions: PermissionsChecking

    private var modelContainer: ModelContainer?
    private var cancellables = Set<AnyCancellable>()
    private var autoPasteEnabled: Bool {
        UserDefaults.standard.bool(forKey: "autoPasteEnabled")
    }

    init(
        audioRecorder: AudioRecording,
        transcriptionService: Transcription,
        hotkeyService: HotkeyBinding,
        pasteService: OutputPasting,
        permissions: PermissionsChecking
    ) {
        self.audioRecorder = audioRecorder
        self.transcriptionService = transcriptionService
        self.hotkeyService = hotkeyService
        self.pasteService = pasteService
        self.permissions = permissions

        setupHotkey()
        setupAudioLevelMonitor()
        setupLoadingStatusMonitor()
    }

    func setupModelContainer(_ container: ModelContainer) {
        self.modelContainer = container
    }

    func loadModel() async {
        let modelName = UserDefaults.standard.string(forKey: "selectedModel")
            ?? Constants.defaultModel
        NSLog("[FreeWhisper] Loading model: %@", modelName)
        do {
            try await transcriptionService.loadModel(name: modelName)
            isModelLoaded = true
            NSLog("[FreeWhisper] Model loaded, ready to transcribe")
        } catch {
            NSLog("[FreeWhisper] Model load error: %@", error.localizedDescription)
            state = .error(message: "Failed to load model: \(error.localizedDescription)")
            scheduleDismiss(after: Constants.errorDismissDelay)
        }
    }

    // MARK: - Push-to-talk

    private func setupHotkey() {
        hotkeyService.onKeyDown = { [weak self] in
            Task { @MainActor in
                self?.handleKeyDown()
            }
        }
        hotkeyService.onKeyUp = { [weak self] in
            Task { @MainActor in
                self?.handleKeyUp()
            }
        }
        hotkeyService.register()
    }

    private func handleKeyDown() {
        guard isModelLoaded else { return }
        guard case .idle = state else { return }
        startRecording()
    }

    private func handleKeyUp() {
        guard case .recording = state else { return }
        stopRecordingAndTranscribe()
    }

    // MARK: - Audio level monitor

    private func setupAudioLevelMonitor() {
        audioRecorder.audioLevelPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.audioLevel = level
            }
            .store(in: &cancellables)
    }

    private func setupLoadingStatusMonitor() {
        transcriptionService.loadingStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.loadingStatus = status
            }
            .store(in: &cancellables)
    }

    // MARK: - Recording

    private func startRecording() {
        if permissions.microphoneGranted {
            beginRecording()
        } else {
            Task {
                let granted = await permissions.requestMicrophone()
                if granted {
                    beginRecording()
                } else {
                    state = .error(message: "Microphone access required. Grant it in System Settings.")
                    scheduleDismiss(after: Constants.errorDismissDelay)
                }
            }
        }
    }

    private func beginRecording() {
        do {
            try audioRecorder.startRecording()
            state = .recording(startTime: .now)
            NSLog("[FreeWhisper] Recording started")
        } catch {
            state = .error(message: error.localizedDescription)
            scheduleDismiss(after: Constants.errorDismissDelay)
        }
    }

    private func stopRecordingAndTranscribe() {
        guard case .recording(let startTime) = state else { return }

        let samples = audioRecorder.stopRecording()
        let duration = Date.now.timeIntervalSince(startTime)
        state = .transcribing
        NSLog("[FreeWhisper] Recording stopped, transcribing %d samples (%.1fs)", samples.count, duration)

        Task {
            do {
                let text = try await transcriptionService.transcribe(samples: samples)
                state = .done(text: text)
                NSLog("[FreeWhisper] Transcription: %@", text)
                handleTranscriptionResult(text: text, duration: duration)
                scheduleDismiss(after: Constants.doneDismissDelay)
            } catch {
                NSLog("[FreeWhisper] Transcription error: %@", error.localizedDescription)
                state = .error(message: error.localizedDescription)
                scheduleDismiss(after: Constants.errorDismissDelay)
            }
        }
    }

    // MARK: - Result handling

    private func handleTranscriptionResult(text: String, duration: Double) {
        if autoPasteEnabled {
            pasteService.paste(text: text)
        } else {
            pasteService.copyToClipboard(text: text)
        }
        saveToHistory(text: text, duration: duration)
    }

    private func saveToHistory(text: String, duration: Double) {
        guard let modelContainer else { return }
        let record = TranscriptionRecord(text: text, durationSeconds: duration)
        let context = modelContainer.mainContext
        context.insert(record)
        trimHistory(context: context)
    }

    private func trimHistory(context: ModelContext) {
        let descriptor = FetchDescriptor<TranscriptionRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        guard let allRecords = try? context.fetch(descriptor),
            allRecords.count > Constants.maxHistoryCount
        else { return }

        for record in allRecords.dropFirst(Constants.maxHistoryCount) {
            context.delete(record)
        }
    }

    private func scheduleDismiss(after delay: TimeInterval) {
        Task {
            try? await Task.sleep(for: .seconds(delay))
            if case .done = state { state = .idle }
            if case .error = state { state = .idle }
        }
    }
}
