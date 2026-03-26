import SwiftUI

struct WaveformView: View {
    let samples: [Float]
    var progress: Double = 0
    /// Called with a fraction 0…1 when the user clicks/drags the waveform.
    var onSeek: ((Double) -> Void)?

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

                // Playhead position in pixels
                let playheadX = geo.size.width * progress

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

                    let color: Color = x <= playheadX
                        ? Color(hex: "00D8FF")
                        : Color(hex: "B0E8FF")

                    context.fill(Path(rect), with: .color(color))
                }

                // Playhead line
                if progress > 0 && progress < 1 {
                    let lineRect = CGRect(
                        x: playheadX - 0.5,
                        y: 0,
                        width: 1,
                        height: geo.size.height
                    )
                    context.fill(
                        Path(lineRect),
                        with: .color(Color.white.opacity(0.7))
                    )
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let frac = max(0, min(1, value.location.x / geo.size.width))
                        onSeek?(frac)
                    }
            )
        }
        .frame(height: 52)
        .background(
            LinearGradient(
                colors: [Color(hex: "044060").opacity(0.85), Color(hex: "0868A0")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .retroInset()
    }
}
