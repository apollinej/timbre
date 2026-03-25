import Foundation
import WhisperKit
import SpeakerKit

struct TranscriptionProgress: Sendable {
    let fractionCompleted: Double
    let currentSegmentText: String?
}

struct TranscribedSegment: Sendable {
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let speakerLabel: String
    let confidence: Float?
}

actor TranscriptionEngine {
    private var whisperKit: WhisperKit?
    private var speakerKit: SpeakerKit?

    func transcribe(
        audioURL: URL,
        modelName: String,
        onProgress: @escaping @Sendable (TranscriptionProgress) -> Void
    ) async throws -> [TranscribedSegment] {
        // 1. Initialize WhisperKit if needed
        if whisperKit == nil {
            let config = WhisperKitConfig(model: modelName)
            whisperKit = try await WhisperKit(config)
        }

        // 2. Initialize SpeakerKit if needed
        if speakerKit == nil {
            speakerKit = try await SpeakerKit(PyannoteConfig())
        }

        guard let whisper = whisperKit, let speaker = speakerKit else {
            throw TranscriptionError.initializationFailed
        }

        // 3. Load audio
        let audioArray = try AudioProcessor.loadAudioAsFloatArray(fromPath: audioURL.path)

        // 4. Transcribe
        onProgress(TranscriptionProgress(fractionCompleted: 0.1, currentSegmentText: "Transcribing…"))

        let transcription = try await whisper.transcribe(audioArray: audioArray)

        onProgress(TranscriptionProgress(fractionCompleted: 0.7, currentSegmentText: "Identifying speakers…"))

        // 5. Diarize
        let diarization = try await speaker.diarize(audioArray: audioArray)

        onProgress(TranscriptionProgress(fractionCompleted: 0.9, currentSegmentText: "Merging results…"))

        // 6. Merge speaker info with transcription
        let speakerSegments = diarization.addSpeakerInfo(to: transcription)

        // 7. Map to our model
        var results: [TranscribedSegment] = []
        for segment in speakerSegments {
            let transcribed = TranscribedSegment(
                text: segment.text.trimmingCharacters(in: .whitespacesAndNewlines),
                startTime: Double(segment.start),
                endTime: Double(segment.end),
                speakerLabel: segment.speaker ?? "Unknown",
                confidence: nil
            )
            if !transcribed.text.isEmpty {
                results.append(transcribed)
            }
        }

        onProgress(TranscriptionProgress(fractionCompleted: 1.0, currentSegmentText: nil))

        return results
    }

    func reset() {
        whisperKit = nil
        speakerKit = nil
    }
}

enum TranscriptionError: LocalizedError {
    case initializationFailed
    case audioLoadFailed
    case cancelled

    var errorDescription: String? {
        switch self {
        case .initializationFailed: "Failed to initialize transcription models."
        case .audioLoadFailed: "Failed to load audio file."
        case .cancelled: "Transcription was cancelled."
        }
    }
}
