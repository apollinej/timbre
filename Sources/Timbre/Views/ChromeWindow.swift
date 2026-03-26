import SwiftUI

// MARK: - Brushed metal (cool chrome with optional blue cast)

struct BrushedMetal: View {
    var baseColor: Color = Color(hex: "B0D0E8")
    var intensity: Double = 0.42

    var body: some View {
        Canvas { context, size in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(baseColor)
            )

            let lineCount = Int(size.height)
            for y in 0..<lineCount {
                let seed = Double(y) * 0.71
                let noise = sin(seed * 12.9898 + 78.233)
                let frac = (noise * 43758.5453).truncatingRemainder(dividingBy: 1.0)
                let alpha = abs(frac) * intensity

                let isLight = frac > 0
                let lineColor = isLight
                    ? Color.white.opacity(alpha * 0.75)
                    : Color(hex: "0060A0").opacity(alpha * 0.22)

                let rect = CGRect(x: 0, y: CGFloat(y), width: size.width, height: 1)
                context.fill(Path(rect), with: .color(lineColor))
            }
        }
    }
}

// MARK: - Chrome window shell (vintage QuickTime / brushed Aqua)

struct ChromeWindow<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .leading) {
                BrushedMetal(baseColor: Color(hex: "A8D0F0"), intensity: 0.38)

                VStack {
                    Rectangle().fill(Color.white.opacity(0.55)).frame(height: 1)
                    Spacer()
                    Rectangle().fill(Color(hex: "2068A0").opacity(0.2)).frame(height: 1)
                }

                HStack(spacing: 10) {
                    AquaTrafficLights(size: 11, spacing: 5)
                        .padding(.leading, 10)

                    Spacer()

                    HStack(spacing: 6) {
                        PixelStar(color: Color(hex: "00E8FF"))
                        Text("timbre")
                            .font(TimbreFont.fontBold(size: 16))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "004878"), Color(hex: "0088D0")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .white.opacity(0.6), radius: 0, y: 1)
                        PixelStar(color: Color(hex: "00FF88"))
                    }

                    Spacer()

                    // Balance traffic lights
                    Color.clear.frame(width: 52, height: 1)
                }
            }
            .frame(height: 38)

            Rectangle().fill(Color(hex: "004060").opacity(0.25)).frame(height: 1)

            ZStack(alignment: .bottomTrailing) {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                ChromeCornerGrip()
                    .offset(x: -2, y: -2)
                    .allowsHitTesting(false)
            }

            Rectangle().fill(Color.white.opacity(0.45)).frame(height: 1)
            ZStack {
                BrushedMetal(baseColor: Color(hex: "98C8E8"), intensity: 0.32)
            }
            .frame(height: 7)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "88B8E0"), Color(hex: "70A8D8")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.75),
                            Color(hex: "40C0FF").opacity(0.6),
                            Color(hex: "2060A0"),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
        )
        .padding(2)
        .textCase(.lowercase)
    }
}

// MARK: - Embossed button (glossy chrome)

struct EmbossedButtonStyle: ButtonStyle {
    var isSmall: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TimbreFont.font(size: isSmall ? 13 : 15))
            .padding(.horizontal, isSmall ? 12 : 18)
            .padding(.vertical, isSmall ? 6 : 8)
            .background(
                ZStack {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: configuration.isPressed
                                    ? [Color(hex: "80C8F0"), Color(hex: "60B0E0")]
                                    : [Color(hex: "F0FCFF"), Color(hex: "A0D8F8")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: configuration.isPressed
                                    ? [Color(hex: "006090").opacity(0.35), Color.white.opacity(0.25)]
                                    : [Color.white.opacity(0.95), Color(hex: "0080C0").opacity(0.35)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
            )
            .foregroundStyle(Color(hex: "044060"))
            .shadow(color: Color(hex: "00C8FF").opacity(configuration.isPressed ? 0 : 0.25), radius: 4, y: 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

// MARK: - Bubble transport buttons (glossy jelly)

struct BubbleButton: View {
    let icon: String
    let size: CGFloat
    var color: Color = Color(hex: "0088FF")
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(hex: "004070").opacity(0.2))
                    .frame(width: size, height: size)
                    .offset(y: 1.5)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.95), color, Color(hex: "0060C0")],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: size * 0.85
                        )
                    )
                    .frame(width: size, height: size)

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.75), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(width: size * 0.72, height: size * 0.42)
                    .offset(y: -size * 0.14)

                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.9), color.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .frame(width: size, height: size)

                Image(systemName: icon)
                    .font(.system(size: size * 0.38, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: Color(hex: "00FFFF").opacity(0.4), radius: 2, y: 0)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sunken content well

struct ChromeInset<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color(hex: "004878").opacity(0.45),
                                Color(hex: "0080C0").opacity(0.2),
                                Color.white.opacity(0.55),
                                Color.white.opacity(0.35),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
    }
}
