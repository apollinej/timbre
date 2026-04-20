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

        // Word-level speaker assignment.
        //
        // The library's default addSpeakerInfo uses `.subsegment` strategy which
        // only splits transcription at silence gaps ≥ 150ms, then assigns ONE
        // speaker per sub-segment. Short interjections ("yeah", "right") that
        // overlap with a speaker's turn without a preceding silence get absorbed
        // into that speaker's sub-segment.
        //
        // Instead: flatten to words, look up each word's speaker from pyannote's
        // per-frame timeline (diarizationResult.segments), then group consecutive
        // same-speaker words into segments. This preserves short interjections.
        let allWords: [WordTiming] = transcriptionResults
            .flatMap { $0.segments }
            .compactMap { $0.words }
            .flatMap { $0 }
            .sorted { $0.start < $1.start }

        guard !allWords.isEmpty else {
            onProgress(1.0)
            return segmentsWithoutSpeakers(transcriptionResults)
        }

        let speakerTimeline = diarizationResult.segments

        func speakerAt(_ time: Float) -> Int? {
            // pyannote segment timeline — find the speaker window containing `time`
            speakerTimeline.first { seg in
                time >= seg.startTime && time <= seg.endTime
            }?.speaker.speakerId
        }

        var out: [TimbreSegment] = []
        var currentWords: [WordTiming] = []
        var currentSpeakerId: Int? = nil
        var hasCurrent = false

        for word in allWords {
            // midpoint of the word; falls back to start if duration is zero
            let probe = (word.start + word.end) / 2
            let sid = speakerAt(probe)

            if hasCurrent && sid == currentSpeakerId {
                currentWords.append(word)
            } else {
                if hasCurrent, !currentWords.isEmpty {
                    out.append(buildSegment(words: currentWords, speakerId: currentSpeakerId))
                }
                currentWords = [word]
                currentSpeakerId = sid
                hasCurrent = true
            }
        }
        if hasCurrent, !currentWords.isEmpty {
            out.append(buildSegment(words: currentWords, speakerId: currentSpeakerId))
        }

        onProgress(1.0)
        return out
    }

    private func buildSegment(
        words: [WordTiming],
        speakerId: Int?
    ) -> TimbreSegment {
        TimbreSegment(
            text: words.map { $0.word }.joined()
                .trimmingCharacters(in: .whitespaces),
            startTime: TimeInterval(words.first?.start ?? 0),
            endTime: TimeInterval(words.last?.end ?? 0),
            speakerId: speakerId
        )
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
