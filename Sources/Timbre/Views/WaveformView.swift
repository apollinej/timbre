import SwiftUI

struct WaveformView: View {
    let samples: [Float]
    var progress: Double = 0

    var body: some View {
        GeometryReader { geo in
            let barWidth: CGFloat = 2
            let spacing: CGFloat = 1
            let totalBarWidth = barWidth + spacing
            let barCount = min(samples.count, Int(geo.size.width / totalBarWidth))
            let midY = geo.size.height / 2

            Canvas { context, _ in
                guard barCount > 0 else { return }
                let step = max(1, samples.count / barCount)

                for i in 0..<barCount {
                    let sampleIndex = min(i * step, samples.count - 1)
                    let amplitude = CGFloat(samples[sampleIndex])
                    let barHeight = max(1, amplitude * geo.size.height * 0.85)
                    let x = CGFloat(i) * totalBarWidth

                    let rect = CGRect(
                        x: x,
                        y: midY - barHeight / 2,
                        width: barWidth,
                        height: barHeight
                    )

                    let barProgress = Double(i) / Double(barCount)
                    let color: Color = barProgress <= progress
                        ? Theme.accent
                        : Theme.chromeLight

                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
        .frame(height: 40)
        .background(Theme.chromeDark.opacity(0.08))
        .retroInset()
    }
}
