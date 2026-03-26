import SwiftUI

/// Pixel dolphin swims across when transcription completes.
struct TranscriptCelebrationOverlay: View {
    let runID: UUID  // used by parent `.id(runID)` to reset animation
    var onFinished: () -> Void

    @State private var swimX: CGFloat = -100
    @State private var bounce: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .topLeading) {
                Color.clear

                PixelDolphin(scale: 3)
                    .offset(x: swimX, y: 28 + bounce)
            }
            .onAppear {
                swimX = -80
                bounce = 0
                withAnimation(.easeInOut(duration: 0.16).repeatCount(14, autoreverses: true)) {
                    bounce = 12
                }
                withAnimation(.easeInOut(duration: 2.35)) {
                    swimX = w + 60
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.45) {
                    onFinished()
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// 18×11 pixel dolphin.
private struct PixelDolphin: View {
    var scale: CGFloat = 1

    private let cols = 18
    private let rows = 11

    private var cells: [(Int, Int, Int)] {
        let b = 1, h = 2, e = 3
        var r: [(Int, Int, Int)] = []
        let pattern: [[Int]] = [
            [0, 0, 0, 0, 0, h, b, b, b, b, 0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, b, b, b, b, b, b, b, b, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, b, b, b, b, b, b, b, b, b, b, b, 0, 0, 0, 0],
            [0, 0, b, b, b, b, e, b, b, b, b, b, b, b, b, 0, 0, 0],
            [0, b, b, b, b, b, b, b, b, b, b, b, b, b, b, b, 0, 0],
            [0, b, b, b, b, b, b, b, b, b, b, b, b, b, h, b, b, 0],
            [0, 0, b, b, b, b, b, b, b, b, b, b, b, b, b, 0, 0, 0],
            [0, 0, 0, b, b, b, b, b, b, b, b, b, b, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, b, b, h, b, b, b, h, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, b, b, 0, 0, b, b, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, h, 0, 0, 0, 0, h, 0, 0, 0, 0, 0, 0, 0],
        ]
        for (y, row) in pattern.enumerated() {
            for (x, v) in row.enumerated() where v > 0 {
                r.append((x, y, v))
            }
        }
        return r
    }

    var body: some View {
        let px: CGFloat = scale
        Canvas { context, _ in
            for (x, y, v) in cells {
                let rect = CGRect(
                    x: CGFloat(x) * px,
                    y: CGFloat(y) * px,
                    width: px,
                    height: px
                )
                let color: Color = {
                    switch v {
                    case 2: return Color(hex: "E0FFFF")
                    case 3: return Color(hex: "044060")
                    default: return Color(hex: "00C8FF")
                    }
                }()
                context.fill(Path(rect), with: .color(color))
            }
        }
        .frame(width: CGFloat(cols) * px, height: CGFloat(rows) * px)
        .shadow(color: Color(hex: "0088FF").opacity(0.5), radius: 4, y: 2)
    }
}
