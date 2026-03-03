import AVFoundation
import Combine
import Foundation

final class AudioRecorderService: AudioRecording {
    var audioLevelPublisher: AnyPublisher<Float, Never> {
        audioLevelSubject.eraseToAnyPublisher()
    }

    private let audioLevelSubject = PassthroughSubject<Float, Never>()
    private let engine = AVAudioEngine()
    private var samples: [Float] = []
    private var isRecording = false
    private let targetSampleRate = Constants.audioSampleRate

    private lazy var targetFormat: AVAudioFormat = {
        AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false
        )!
    }()

    func startRecording() throws {
        guard !isRecording else { return }

        samples = []
        let inputNode = engine.inputNode
        let nativeFormat = inputNode.inputFormat(forBus: 0)

        guard nativeFormat.sampleRate > 0 else {
            throw AudioRecorderError.noInputDevice
        }

        guard let converter = AVAudioConverter(from: nativeFormat, to: targetFormat) else {
            throw AudioRecorderError.converterCreationFailed
        }

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nativeFormat) {
            [weak self] buffer, _ in
            guard let self else { return }
            self.processAudioBuffer(buffer, converter: converter, nativeFormat: nativeFormat)
        }

        engine.prepare()
        try engine.start()
        isRecording = true
    }

    func stopRecording() -> [Float] {
        guard isRecording else { return [] }

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRecording = false

        let captured = samples
        samples = []
        return captured
    }

    private func processAudioBuffer(
        _ buffer: AVAudioPCMBuffer,
        converter: AVAudioConverter,
        nativeFormat: AVAudioFormat
    ) {
        let ratio = targetSampleRate / nativeFormat.sampleRate
        let frameCount = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
        guard frameCount > 0 else { return }

        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: frameCount
        ) else { return }

        var conversionError: NSError?
        converter.convert(to: outputBuffer, error: &conversionError) { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        guard conversionError == nil,
            let channelData = outputBuffer.floatChannelData?[0]
        else { return }

        let frames = Array(
            UnsafeBufferPointer(
                start: channelData,
                count: Int(outputBuffer.frameLength)
            ))

        let rms = computeRMS(frames)
        audioLevelSubject.send(rms)
        samples.append(contentsOf: frames)
    }

    private func computeRMS(_ buffer: [Float]) -> Float {
        guard !buffer.isEmpty else { return 0 }
        let sumOfSquares = buffer.reduce(Float(0)) { $0 + $1 * $1 }
        return sqrt(sumOfSquares / Float(buffer.count))
    }
}

enum AudioRecorderError: LocalizedError {
    case noInputDevice
    case converterCreationFailed

    var errorDescription: String? {
        switch self {
        case .noInputDevice:
            return "No audio input device found."
        case .converterCreationFailed:
            return "Failed to create audio format converter."
        }
    }
}
