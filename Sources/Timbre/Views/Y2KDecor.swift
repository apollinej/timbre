import SwiftUI

// MARK: - Classic Mac OS X “traffic lights” (decorative)

struct AquaTrafficLights: View {
    var size: CGFloat = 12
    var spacing: CGFloat = 6

    var body: some View {
        HStack(spacing: spacing) {
            AquaGlossDot(fill: Color(hex: "FF5A52"), size: size)
            AquaGlossDot(fill: Color(hex: "FFBD2E"), size: size)
            AquaGlossDot(fill: Color(hex: "28C840"), size: size)
        }
    }
}

private struct AquaGlossDot: View {
    let fill: Color
    var size: CGFloat = 12

    var body: some View {
        ZStack {
            Circle()
                .fill(fill)
                .frame(width: size, height: size)
                .shadow(color: fill.opacity(0.5), radius: 1, y: 0.5)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.88), Color.clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size * 0.9
                    )
                )
                .frame(width: size * 0.55, height: size * 0.55)
                .offset(x: -size * 0.12, y: -size * 0.12)
            Circle()
                .strokeBorder(Color.black.opacity(0.18), lineWidth: 0.5)
                .frame(width: size, height: size)
        }
    }
}

// MARK: - QuickTime-style corner grip ridges

struct ChromeCornerGrip: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.35),
                                Color(hex: "7090B0").opacity(0.5),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat(14 - i * 4), height: 2)
            }
        }
        .padding(4)
    }
}

// MARK: - Tiny pixel “star” charm

struct PixelStar: View {
    var color: Color = Color(hex: "00E8FF")
    var body: some View {
        Canvas { context, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let px: CGFloat = 1
            let pts: [(CGFloat, CGFloat)] = [
                (0, -4), (1, -1), (4, 0), (1, 1), (0, 4), (-1, 1), (-4, 0), (-1, -1),
            ]
            for (dx, dy) in pts {
                let r = CGRect(x: c.x + dx * px - px / 2, y: c.y + dy * px - px / 2, width: px, height: px)
                context.fill(Path(r), with: .color(color))
            }
            context.fill(Path(CGRect(x: c.x - px / 2, y: c.y - px / 2, width: px, height: px)), with: .color(.white))
        }
        .frame(width: 12, height: 12)
        .drawingGroup()
    }
}

// MARK: - Light CRT-style scanlines (whimsy, very subtle)

struct SubtleScanlines: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let h: CGFloat = 2
                var y: CGFloat = 0
                while y < size.height {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                    context.fill(Path(rect), with: .color(Color.black.opacity(0.04)))
                    y += h
                }
            }
            .allowsHitTesting(false)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Dithered pixel border (1px steps)

struct PixelatedFrame: ViewModifier {
    var color: Color = Color(hex: "00B8FF")

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    let step: CGFloat = 4
                    Canvas { context, _ in
                        var x: CGFloat = 0
                        while x < w {
                            let r = CGRect(x: x, y: 0, width: 2, height: 2)
                            context.fill(Path(r), with: .color(color.opacity(0.6)))
                            x += step
                        }
                        x = 0
                        while x < w {
                            let r = CGRect(x: x, y: h - 2, width: 2, height: 2)
                            context.fill(Path(r), with: .color(color.opacity(0.6)))
                            x += step
                        }
                        var y: CGFloat = 0
                        while y < h {
                            let r = CGRect(x: 0, y: y, width: 2, height: 2)
                            context.fill(Path(r), with: .color(color.opacity(0.45)))
                            y += step
                        }
                        y = 0
                        while y < h {
                            let r = CGRect(x: w - 2, y: y, width: 2, height: 2)
                            context.fill(Path(r), with: .color(color.opacity(0.45)))
                            y += step
                        }
                    }
                }
            )
    }
}

extension View {
    func pixelatedFrame(color: Color = Color(hex: "00B8FF")) -> some View {
        modifier(PixelatedFrame(color: color))
    }
}
