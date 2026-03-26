import SwiftUI

// MARK: - Brushed Metal Texture (drawn procedurally like classic Mac OS X)

struct BrushedMetal: View {
    var baseColor: Color = Color(hex: "B8BCC8")
    var intensity: Double = 0.4

    var body: some View {
        Canvas { context, size in
            // Base fill
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(baseColor)
            )

            // Horizontal brush lines — the classic brushed aluminum look
            let lineCount = Int(size.height)
            for y in 0..<lineCount {
                // Pseudo-random using sine for deterministic "randomness"
                let seed = Double(y) * 0.7
                let noise = sin(seed * 12.9898 + 78.233)
                let frac = (noise * 43758.5453).truncatingRemainder(dividingBy: 1.0)
                let alpha = abs(frac) * intensity

                let isLight = frac > 0
                let lineColor = isLight
                    ? Color.white.opacity(alpha * 0.6)
                    : Color.black.opacity(alpha * 0.3)

                let rect = CGRect(x: 0, y: CGFloat(y), width: size.width, height: 1)
                context.fill(Path(rect), with: .color(lineColor))
            }
        }
    }
}

// MARK: - Chrome Window Shell

struct ChromeWindow<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom title bar with brushed metal
            ZStack {
                BrushedMetal(baseColor: Color(hex: "C0C4D0"), intensity: 0.35)

                // Top highlight
                VStack {
                    Rectangle().fill(Color.white.opacity(0.5)).frame(height: 1)
                    Spacer()
                    Rectangle().fill(Color.black.opacity(0.15)).frame(height: 1)
                }

                // Title
                Text("timbre")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(hex: "4A5060"))
            }
            .frame(height: 32)

            // Outer bevel
            Rectangle().fill(Color.black.opacity(0.2)).frame(height: 1)

            // Main content
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom chrome bar
            Rectangle().fill(Color.white.opacity(0.3)).frame(height: 1)
            ZStack {
                BrushedMetal(baseColor: Color(hex: "B8BCC8"), intensity: 0.3)
            }
            .frame(height: 6)
        }
        .background(Color(hex: "A8ACB8"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color(hex: "8890A0"),
                            Color(hex: "606878"),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
        )
        .padding(2)
    }
}

// MARK: - Embossed Button Style (3D raised look)

struct EmbossedButtonStyle: ButtonStyle {
    var isSmall: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: isSmall ? 10 : 12, weight: .medium))
            .padding(.horizontal, isSmall ? 8 : 14)
            .padding(.vertical, isSmall ? 4 : 6)
            .background(
                ZStack {
                    // Button face
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: configuration.isPressed
                                    ? [Color(hex: "A0A4B0"), Color(hex: "B0B4C0")]
                                    : [Color(hex: "D0D4E0"), Color(hex: "B8BCC8")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Bevel highlights
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(
                            LinearGradient(
                                colors: configuration.isPressed
                                    ? [Color.black.opacity(0.15), Color.white.opacity(0.2)]
                                    : [Color.white.opacity(0.6), Color.black.opacity(0.15)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
            )
            .foregroundStyle(Color(hex: "3A4050"))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Bubble Icon Button (round, glossy, 3D)

struct BubbleButton: View {
    let icon: String
    let size: CGFloat
    var color: Color = Color(hex: "78A8E0")
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Shadow
                Circle()
                    .fill(Color.black.opacity(0.15))
                    .frame(width: size, height: size)
                    .offset(y: 1)

                // Base
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.9), color],
                            center: .center,
                            startRadius: 0,
                            endRadius: size / 2
                        )
                    )
                    .frame(width: size, height: size)

                // Glossy highlight (top shine)
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.7), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(width: size * 0.7, height: size * 0.45)
                    .offset(y: -size * 0.12)

                // Inner border
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.4), color.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .frame(width: size, height: size)

                // Icon
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: color.opacity(0.5), radius: 1, y: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chrome Inset Panel (sunken area for content)

struct ChromeInset<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.25),
                                Color.black.opacity(0.1),
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.3),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
    }
}
