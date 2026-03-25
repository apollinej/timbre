import SwiftUI

struct PlaybackBar: View {
    let viewModel: TranscriptViewModel
    let duration: TimeInterval

    var body: some View {
        HStack(spacing: 16) {
            // Seek backward
            Button {
                let newTime = max(0, viewModel.currentTime - 10)
                viewModel.seek(to: newTime)
            } label: {
                Image(systemName: "gobackward.10")
            }
            .buttonStyle(.borderless)

            // Play/pause
            Button {
                viewModel.togglePlayback()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            .keyboardShortcut(.space, modifiers: [])

            // Seek forward
            Button {
                let newTime = min(duration, viewModel.currentTime + 10)
                viewModel.seek(to: newTime)
            } label: {
                Image(systemName: "goforward.10")
            }
            .buttonStyle(.borderless)

            // Time display
            Text(TimeFormatter.format(viewModel.currentTime))
                .monospacedDigit()
                .foregroundStyle(.secondary)

            // Progress slider
            Slider(
                value: Binding(
                    get: { viewModel.currentTime },
                    set: { viewModel.seek(to: $0) }
                ),
                in: 0...max(duration, 0.01)
            )

            Text(TimeFormatter.format(duration))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
