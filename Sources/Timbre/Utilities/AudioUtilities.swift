import AVFoundation
import Foundation

enum AudioUtilities {
    /// Supported audio file extensions
    static let supportedExtensions: Set<String> = [
        "m4a", "wav", "mp3", "flac", "aac", "caf", "aiff"
    ]

    static func isSupported(_ url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }

    /// Extract duration and creation date from an audio file
    static func metadata(for url: URL) async throws -> (duration: TimeInterval, dateRecorded: Date?) {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let creationDate = try? await asset.load(.creationDate)
        let date = try? await creationDate?.load(.dateValue)
        return (duration.seconds, date)
    }

    /// Extract waveform samples from audio file for visualization
    static func waveformSamples(for url: URL, count: Int = 200) async throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let frameCount = AVAudioFrameCount(file.length)

        guard frameCount > 0, let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameCount
        ) else {
            return Array(repeating: 0, count: count)
        }

        try file.read(into: buffer)

        guard let channelData = buffer.floatChannelData?[0] else {
            return Array(repeating: 0, count: count)
        }

        let samplesPerBucket = Int(frameCount) / count
        guard samplesPerBucket > 0 else {
            return Array(repeating: 0, count: count)
        }

        var waveform: [Float] = []
        waveform.reserveCapacity(count)

        for i in 0..<count {
            let start = i * samplesPerBucket
            let end = min(start + samplesPerBucket, Int(frameCount))
            var maxAmplitude: Float = 0
            for j in start..<end {
                let amplitude = abs(channelData[j])
                if amplitude > maxAmplitude {
                    maxAmplitude = amplitude
                }
            }
            waveform.append(maxAmplitude)
        }

        return waveform
    }
}
