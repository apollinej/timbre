import AVFoundation
import Foundation
import SwiftData

@Observable
final class TranscriptViewModel {
    var isPlaying = false
    var currentTime: TimeInterval = 0
    var waveformSamples: [Float] = []
    var isLoadingWaveform = false

    private var player: AVAudioPlayer?
    private var timer: Timer?

    var currentSegmentID: UUID? {
        guard let transcript = memo?.transcript else { return nil }
        return transcript.sortedSegments.last { $0.startTime <= currentTime }?.id
    }

    private(set) var memo: Memo?

    func load(memo: Memo) {
        self.memo = memo
        stop()
        loadWaveform(for: memo)
    }

    func play() {
        guard let memo, let url = memo.resolveBookmark() else { return }

        let accessing = url.startAccessingSecurityScopedResource()

        if player == nil || player?.url != url {
            player = try? AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
        }

        if accessing {
            // Keep resource accessible during playback
        }

        player?.currentTime = currentTime
        player?.play()
        isPlaying = true
        startTimer()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
    }

    func togglePlayback() {
        if isPlaying { pause() } else { play() }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentTime = 0
        stopTimer()
    }

    func seek(to time: TimeInterval) {
        currentTime = time
        player?.currentTime = time
        if !isPlaying { play() }
    }

    func seekToSegment(_ segment: Segment) {
        seek(to: segment.startTime)
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let player = self.player else { return }
            self.currentTime = player.currentTime
            if !player.isPlaying {
                self.isPlaying = false
                self.stopTimer()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func loadWaveform(for memo: Memo) {
        guard let url = memo.resolveBookmark() else { return }
        isLoadingWaveform = true
        Task {
            let samples = (try? await AudioUtilities.waveformSamples(for: url)) ?? []
            await MainActor.run {
                self.waveformSamples = samples
                self.isLoadingWaveform = false
            }
        }
    }

    deinit {
        timer?.invalidate()
        player?.stop()
    }
}
