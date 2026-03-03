import Combine
import Foundation

protocol AudioRecording: AnyObject {
    var audioLevelPublisher: AnyPublisher<Float, Never> { get }
    func startRecording() throws
    func stopRecording() -> [Float]
}
