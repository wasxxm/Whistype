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
    private var recordingTimer: Timer?
    private var autoPasteEnabled: Bool {
        UserDefaults.standard.bool(forKey: "autoPasteEnabled")
    }
    private var maxRecordingSeconds: Int {
        let value = UserDefaults.standard.integer(forKey: "maxRecordingSeconds")
        return value > 0 ? value : Constants.defaultMaxRecordingSeconds
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
        do {
            try await transcriptionService.loadModel(name: modelName)
            isModelLoaded = true
        } catch {
            print("[FreeWhisper] Model load error: \(error)")
            state = .error(message: "Failed to load model: \(error.localizedDescription)")
            scheduleDismiss(after: 10.0)
        }
    }

    func toggle() {
        switch state {
        case .idle:
            startRecording()
        case .recording:
            stopRecordingAndTranscribe()
        default:
            break
        }
    }

    private func setupHotkey() {
        hotkeyService.onToggle = { [weak self] in
            Task { @MainActor in
                self?.toggle()
            }
        }
        hotkeyService.register()
    }

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
            startRecordingTimer()
        } catch {
            state = .error(message: error.localizedDescription)
            scheduleDismiss(after: Constants.errorDismissDelay)
        }
    }

    private func stopRecordingAndTranscribe() {
        guard case .recording(let startTime) = state else { return }

        recordingTimer?.invalidate()
        recordingTimer = nil

        let samples = audioRecorder.stopRecording()
        let duration = Date.now.timeIntervalSince(startTime)
        state = .transcribing

        Task {
            do {
                let text = try await transcriptionService.transcribe(samples: samples)
                state = .done(text: text)
                handleTranscriptionResult(text: text, duration: duration)
                scheduleDismiss(after: Constants.doneDismissDelay)
            } catch {
                state = .error(message: error.localizedDescription)
                scheduleDismiss(after: Constants.errorDismissDelay)
            }
        }
    }

    private func handleTranscriptionResult(text: String, duration: Double) {
        if autoPasteEnabled && permissions.accessibilityGranted {
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

    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(maxRecordingSeconds),
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                self?.stopRecordingAndTranscribe()
            }
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
