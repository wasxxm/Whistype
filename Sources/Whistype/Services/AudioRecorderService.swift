import Accelerate
import AVFoundation
import Combine
import Foundation

final class AudioRecorderService: AudioRecording {
    var audioLevelPublisher: AnyPublisher<Float, Never> {
        audioLevelSubject.eraseToAnyPublisher()
    }

    private let audioLevelSubject = PassthroughSubject<Float, Never>()
    private let engine = AVAudioEngine()
    private let samplesLock = NSLock()
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

        samplesLock.lock()
        samples = []
        samples.reserveCapacity(Int(targetSampleRate) * 60)
        samplesLock.unlock()

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

        samplesLock.lock()
        let captured = samples
        samples = []
        samplesLock.unlock()

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

        let count = Int(outputBuffer.frameLength)
        let bufferPointer = UnsafeBufferPointer(start: channelData, count: count)

        var rms: Float = 0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(count))
        audioLevelSubject.send(rms)

        samplesLock.lock()
        samples.append(contentsOf: bufferPointer)
        samplesLock.unlock()
    }
}
