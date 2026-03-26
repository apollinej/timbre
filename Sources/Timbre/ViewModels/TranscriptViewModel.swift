import AVFoundation
import Foundation
import SwiftData

@MainActor @Observable
final class TranscriptViewModel {
    var isPlaying = false
    var currentTime: TimeInterval = 0
    var waveformSamples: [Float] = []
    var isTranscribing = false
    var transcriptionError: String?
    /// Bumped to force SwiftUI re-render after speaker rename
    var speakerVersion = 0

    private var player: AVAudioPlayer?
    private var audioURL: URL?
    private var isAccessingSecurityScope = false
    private let engine = TranscriptionEngine()

    func loadAudio(from memo: Memo) async {
        // Release any previous security scope
        releaseAudioAccess()

        guard let url = resolveURL(for: memo) else {
            print("[Timbre] loadAudio: could not resolve URL for memo '\(memo.title)'")
            return
        }

        audioURL = url

        do {
            waveformSamples = try await AudioFileHelper.extractWaveform(from: url)
        } catch {
            print("[Timbre] loadAudio: waveform extraction failed: \(error)")
            waveformSamples = []
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            print("[Timbre] loadAudio: player ready, duration=\(player?.duration ?? 0)s")
        } catch {
            print("[Timbre] loadAudio: AVAudioPlayer init failed: \(error)")
            player = nil
        }
    }

    var isPlayerReady: Bool {
        player != nil
    }

    func startTranscription(
        memo: Memo,
        model: WhisperModel,
        context: ModelContext
    ) async {
        guard !isTranscribing else { return }
        isTranscribing = true
        transcriptionError = nil
        memo.status = .transcribing
        memo.transcriptionProgress = 0

        do {
            try await engine.loadModel(model)

            guard let url = audioURL ?? resolveURL(for: memo) else {
                throw TranscriptionEngine.EngineError
                    .transcriptionFailed("Cannot access audio file")
            }

            let result = try await engine.transcribe(
                audioPath: url.path
            ) { progress in
                Task { @MainActor in
                    memo.transcriptionProgress = progress
                }
            }

            saveTranscript(result, to: memo, model: model, context: context)
        } catch {
            memo.status = .failed(error: error.localizedDescription)
            transcriptionError = error.localizedDescription
        }

        isTranscribing = false
    }

    func cancelTranscription(memo: Memo) async {
        await engine.cancel()
        memo.status = .imported
        memo.transcriptionProgress = 0
        isTranscribing = false
    }

    func renameSpeaker(_ speaker: Speaker?, to name: String) {
        guard let speaker else { return }
        speaker.displayName = name.isEmpty ? nil : name
        // Bump version so SwiftUI re-renders merged blocks
        speakerVersion += 1
    }

    private func saveTranscript(
        _ result: TimbreTranscriptionResult,
        to memo: Memo,
        model: WhisperModel,
        context: ModelContext
    ) {
        var speakerMap: [Int: Speaker] = [:]
        var speakerIndex = 0

        for segment in result.segments {
            guard let id = segment.speakerId, speakerMap[id] == nil else {
                continue
            }
            let speaker = Speaker(
                label: "Speaker \(speakerIndex + 1)",
                colorHex: SpeakerColors.hex(for: speakerIndex)
            )
            context.insert(speaker)
            speakerMap[id] = speaker
            speakerIndex += 1
        }

        let segments = result.segments.map { seg in
            let segment = Segment(
                text: seg.text,
                startTime: seg.startTime,
                endTime: seg.endTime,
                speaker: seg.speakerId.flatMap { speakerMap[$0] },
                confidence: nil
            )
            context.insert(segment)
            return segment
        }

        let transcript = Transcript(
            segments: segments,
            modelUsed: model.name,
            language: result.language
        )
        context.insert(transcript)

        memo.transcript = transcript
        memo.status = .completed
        memo.transcriptionProgress = 1.0

        try? context.save()
        try? TranscriptDiskExport.writeMemoTranscriptIfNeeded(memo)
    }

    // MARK: - Playback

    func play() {
        guard let player else {
            print("[Timbre] play: no player available")
            return
        }
        player.currentTime = currentTime
        let success = player.play()
        print("[Timbre] play: started=\(success), time=\(currentTime)")
        isPlaying = true
        startTimeTracking()
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func togglePlayback() {
        if isPlaying { pause() } else { play() }
    }

    /// Ensures the player exists (waveform load can finish before the user hits play).
    func ensureAudioReady(memo: Memo) async {
        if player == nil {
            await loadAudio(from: memo)
        }
    }

    func togglePlayback(memo: Memo) async {
        await ensureAudioReady(memo: memo)
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func skipBy(memo: Memo, delta: TimeInterval) async {
        await ensureAudioReady(memo: memo)
        seek(to: max(0, min(duration, currentTime + delta)))
    }

    func jumpToAndPlay(memo: Memo, time: TimeInterval) async {
        await ensureAudioReady(memo: memo)
        seek(to: time)
        play()
    }

    func seek(to time: TimeInterval) {
        currentTime = time
        player?.currentTime = time
    }

    var duration: TimeInterval {
        player?.duration ?? 0
    }

    var playbackProgress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    private func resolveURL(for memo: Memo) -> URL? {
        // Try bookmark first, fall back to sourceURL
        if let bookmark = memo.audioBookmark {
            var stale = false
            if let url = try? URL(
                resolvingBookmarkData: bookmark,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            ) {
                isAccessingSecurityScope = url.startAccessingSecurityScopedResource()
                print("[timbre] resolveURL: bookmark ok, path=\(url.path)")
                return url
            }
            print("[timbre] resolveURL: bookmark failed, trying sourceURL")
        }

        // Direct file access (works when not sandboxed)
        let url = memo.sourceURL
        if FileManager.default.fileExists(atPath: url.path) {
            print("[timbre] resolveURL: using sourceURL: \(url.path)")
            return url
        }

        print("[timbre] resolveURL: file not found at \(url.path)")
        return nil
    }

    private func releaseAudioAccess() {
        if isAccessingSecurityScope, let url = audioURL {
            url.stopAccessingSecurityScopedResource()
            isAccessingSecurityScope = false
        }
        player?.stop()
        player = nil
        audioURL = nil
    }

    private func startTimeTracking() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            Task { @MainActor in
                guard self.isPlaying, let player = self.player else {
                    timer.invalidate()
                    return
                }
                self.currentTime = player.currentTime
                if !player.isPlaying {
                    self.isPlaying = false
                    timer.invalidate()
                }
            }
        }
    }
}
