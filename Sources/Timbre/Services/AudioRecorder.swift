import AVFoundation
import Foundation

@MainActor @Observable
final class AudioRecorder {
    enum State: Equatable {
        case idle
        case recording
        case paused
    }

    var state: State = .idle
    var elapsedTime: TimeInterval = 0
    var waveformSamples: [Float] = []

    private var engine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private(set) var tempURL: URL?
    private var timer: Timer?
    private var startDate: Date?
    private var accumulatedTime: TimeInterval = 0

    func startRecording() throws {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("timbre-rec-\(UUID().uuidString).m4a")
        tempURL = url

        // Write as WAV for simplicity — AudioImporter handles conversion
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: format.channelCount,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
        ]
        let wavURL = url.deletingPathExtension().appendingPathExtension("wav")
        tempURL = wavURL
        audioFile = try AVAudioFile(forWriting: wavURL, settings: settings)

        // Tap for waveform + writing
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) {
            [weak self] buffer, _ in
            guard let self else { return }
            try? self.audioFile?.write(from: buffer)
            let samples = self.extractPeaks(from: buffer)
            Task { @MainActor in
                self.waveformSamples.append(contentsOf: samples)
                // Keep buffer reasonable
                if self.waveformSamples.count > 2000 {
                    self.waveformSamples = Array(
                        self.waveformSamples.suffix(2000)
                    )
                }
            }
        }

        try engine.start()
        self.engine = engine
        state = .recording
        startDate = Date()
        accumulatedTime = 0
        startTimer()
    }

    func pauseRecording() {
        guard state == .recording else { return }
        engine?.pause()
        accumulatedTime = elapsedTime
        stopTimer()
        state = .paused
    }

    func resumeRecording() throws {
        guard state == .paused else { return }
        try engine?.start()
        startDate = Date()
        state = .recording
        startTimer()
    }

    /// Stops recording and returns the audio file URL
    func stopRecording() -> URL? {
        stopTimer()
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
        audioFile = nil
        state = .idle
        let url = tempURL
        tempURL = nil
        return url
    }

    func discardRecording() {
        let url = stopRecording()
        if let url { try? FileManager.default.removeItem(at: url) }
        elapsedTime = 0
        waveformSamples = []
    }

    private func extractPeaks(from buffer: AVAudioPCMBuffer) -> [Float] {
        guard let data = buffer.floatChannelData?[0] else { return [] }
        let count = Int(buffer.frameLength)
        let chunkSize = max(1, count / 4)
        var peaks: [Float] = []
        for i in stride(from: 0, to: count, by: chunkSize) {
            let end = min(i + chunkSize, count)
            var peak: Float = 0
            for j in i..<end {
                peak = max(peak, abs(data[j]))
            }
            peaks.append(peak)
        }
        return peaks
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) {
            [weak self] _ in
            Task { @MainActor in
                guard let self, self.state == .recording else { return }
                let elapsed = Date().timeIntervalSince(self.startDate ?? Date())
                self.elapsedTime = self.accumulatedTime + elapsed
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
