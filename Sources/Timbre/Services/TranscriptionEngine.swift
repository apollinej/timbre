import Foundation
import WhisperKit
import SpeakerKit

private final class CancelFlag: @unchecked Sendable {
    var value = false
}

actor TranscriptionEngine {
    private var whisperKit: WhisperKit?
    private var speakerKit: SpeakerKit?
    private let cancelFlag = CancelFlag()

    enum EngineError: LocalizedError {
        case modelNotLoaded
        case transcriptionFailed(String)
        case cancelled

        var errorDescription: String? {
            switch self {
            case .modelNotLoaded:
                "Whisper model not loaded. Select a model in Settings."
            case .transcriptionFailed(let reason):
                "Transcription failed: \(reason)"
            case .cancelled:
                "Transcription was cancelled."
            }
        }
    }

    func loadModel(_ model: WhisperModel) async throws {
        whisperKit = try await WhisperKit(
            WhisperKitConfig(model: model.name)
        )
    }

    func cancel() {
        cancelFlag.value = true
    }

    func transcribe(
        audioPath: String,
        onProgress: @Sendable @escaping (Double) -> Void
    ) async throws -> TimbreTranscriptionResult {
        cancelFlag.value = false

        guard let whisperKit else {
            throw EngineError.modelNotLoaded
        }

        onProgress(0.05)

        // Transcribe with word timestamps (needed for speaker diarization)
        let decodeOptions = DecodingOptions(wordTimestamps: true)

        let results: [TranscriptionResult] = try await whisperKit.transcribe(
            audioPath: audioPath,
            decodeOptions: decodeOptions,
            callback: { [cancelFlag] progress in
                onProgress(min(0.1 + Double(progress.windowId) * 0.05, 0.7))
                return !cancelFlag.value
            }
        )

        guard !cancelFlag.value else { throw EngineError.cancelled }

        guard let firstResult = results.first else {
            throw EngineError.transcriptionFailed("No results returned")
        }

        // Speaker diarization
        onProgress(0.75)
        let diarizedSegments = try await diarize(
            audioPath: audioPath,
            transcriptionResults: results,
            onProgress: { p in onProgress(0.75 + p * 0.2) }
        )

        onProgress(1.0)

        return TimbreTranscriptionResult(
            segments: diarizedSegments,
            language: firstResult.language
        )
    }

    private func diarize(
        audioPath: String,
        transcriptionResults: [TranscriptionResult],
        onProgress: @Sendable @escaping (Double) -> Void
    ) async throws -> [TimbreSegment] {
        // Load audio for diarization
        let audioArray = try AudioProcessor.loadAudioAsFloatArray(
            fromPath: audioPath
        )

        // Try loading SpeakerKit if not already loaded
        if speakerKit == nil {
            do {
                speakerKit = try await SpeakerKit(PyannoteConfig())
            } catch {
                // SpeakerKit unavailable — return segments without speaker info
                return segmentsWithoutSpeakers(transcriptionResults)
            }
        }

        guard let speakerKit else {
            return segmentsWithoutSpeakers(transcriptionResults)
        }

        onProgress(0.3)

        let diarizationResult = try await speakerKit.diarize(
            audioArray: audioArray
        )

        onProgress(0.7)

        // Merge diarization with transcription
        let speakerSegments = diarizationResult.addSpeakerInfo(
            to: transcriptionResults
        )

        onProgress(1.0)

        // Flatten [[SpeakerSegment]] → [TimbreSegment]
        return speakerSegments.flatMap { group in
            group.map { seg in
                TimbreSegment(
                    text: seg.text.trimmingCharacters(
                        in: CharacterSet.whitespaces
                    ),
                    startTime: TimeInterval(seg.startTime),
                    endTime: TimeInterval(seg.endTime),
                    speakerId: seg.speaker.speakerId
                )
            }
        }
    }

    private func segmentsWithoutSpeakers(
        _ results: [TranscriptionResult]
    ) -> [TimbreSegment] {
        results.flatMap { result in
            result.segments.map { seg in
                TimbreSegment(
                    text: seg.text.trimmingCharacters(
                        in: CharacterSet.whitespaces
                    ),
                    startTime: TimeInterval(seg.start),
                    endTime: TimeInterval(seg.end),
                    speakerId: nil
                )
            }
        }
    }
}

// MARK: - Result types

struct TimbreSegment {
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let speakerId: Int?
}

struct TimbreTranscriptionResult {
    let segments: [TimbreSegment]
    let language: String?
}
