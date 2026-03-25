import SwiftUI

struct WaveformView: View {
    let samples: [Float]
    let currentTime: TimeInterval
    let duration: TimeInterval

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let barWidth = max(1, width / CGFloat(max(samples.count, 1)))
            let progress = duration > 0 ? currentTime / duration : 0

            ZStack(alignment: .leading) {
                // Background waveform
                HStack(alignment: .center, spacing: 1) {
                    ForEach(Array(samples.enumerated()), id: \.offset) { _, sample in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.secondary.opacity(0.3))
                            .frame(
                                width: max(1, barWidth - 1),
                                height: max(2, CGFloat(sample) * height * 0.9)
                            )
                    }
                }

                // Progress overlay
                HStack(alignment: .center, spacing: 1) {
                    ForEach(Array(samples.enumerated()), id: \.offset) { index, sample in
                        let barProgress = CGFloat(index) / CGFloat(max(samples.count - 1, 1))
                        RoundedRectangle(cornerRadius: 1)
                            .fill(barProgress <= progress ? Color.accentColor : .clear)
                            .frame(
                                width: max(1, barWidth - 1),
                                height: max(2, CGFloat(sample) * height * 0.9)
                            )
                    }
                }
            }
        }
    }
}
