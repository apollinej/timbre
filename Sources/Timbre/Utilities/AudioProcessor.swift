import AVFoundation
import Foundation

enum AudioFileHelper {
    static let supportedExtensions: Set<String> = [
        "m4a", "wav", "mp3", "flac", "aac", "caf", "aiff"
    ]

    static func isSupported(_ url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }

    /// Extracts duration and metadata from an audio file
    static func metadata(for url: URL) async throws -> AudioMetadata {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)

        let fileSize = try FileManager.default
            .attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0

        let creationDate = try? FileManager.default
            .attributesOfItem(atPath: url.path)[.creationDate] as? Date

        return AudioMetadata(
            duration: durationSeconds,
            fileSize: fileSize,
            creationDate: creationDate
        )
    }

    /// Extracts waveform samples for visualization
    static func extractWaveform(
        from url: URL,
        sampleCount: Int = 200
    ) async throws -> [Float] {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let frameCount = AVAudioFrameCount(file.length)

        guard frameCount > 0 else { return [] }

        let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameCount
        )
        guard let buffer else { return [] }

        try file.read(into: buffer)

        guard let channelData = buffer.floatChannelData?[0] else { return [] }

        let samplesPerBucket = Int(frameCount) / sampleCount
        guard samplesPerBucket > 0 else { return [] }

        var waveform: [Float] = []
        waveform.reserveCapacity(sampleCount)

        for i in 0..<sampleCount {
            let start = i * samplesPerBucket
            let end = min(start + samplesPerBucket, Int(frameCount))
            var peak: Float = 0
            for j in start..<end {
                peak = max(peak, abs(channelData[j]))
            }
            waveform.append(peak)
        }

        return waveform
    }
}

struct AudioMetadata {
    let duration: TimeInterval
    let fileSize: Int64
    let creationDate: Date?
}
