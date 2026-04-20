import SwiftUI

struct HomeView: View {
    let onNavigate: (NavigationRouter.Route) -> Void

    var body: some View {
        ZStack {
            background

            GeometryReader { geo in
                VStack(spacing: 0) {
                    // Wordmark — top area
                    wordmark
                        .frame(height: geo.size.height * 0.30)

                    Spacer().frame(height: geo.size.height * 0.06)

                    // 2x2 grid of capsule buttons
                    buttonGrid(
                        width: geo.size.width * 0.70,
                        height: geo.size.height * 0.48
                    )
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: 0)
                }
            }

            // Me button — bottom right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    BubbleButton(
                        icon: "person.crop.circle.fill",
                        size: 36,
                        color: Color(hex: "7090B0")
                    ) { onNavigate(.me) }
                }
            }
            .padding(20)
        }
    }

    private var background: some View {
        ZStack {
            Theme.playerFaceGradient
            LinearGradient(
                colors: [
                    Color.white.opacity(0.35), Color.clear,
                    Color(hex: "00FFFF").opacity(0.08), Color.clear,
                    Color.white.opacity(0.2),
                ],
                startPoint: .top, endPoint: .bottom
            )
            SubtleScanlines()
        }
    }

    private var wordmark: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("timbre")
                .font(TimbreFont.fontBold(size: 38))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "004878"), Color(hex: "0088D0")],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .shadow(color: Color(hex: "00E8FF").opacity(0.5), radius: 8, y: 0)
                .shadow(color: .white.opacity(0.6), radius: 0, y: 1)

            Text("what did you say again?")
                .font(Theme.captionFont)
                .foregroundStyle(Color(hex: "2090C8"))
        }
    }

    private func buttonGrid(width: CGFloat, height: CGFloat) -> some View {
        let spacing: CGFloat = 16
        let cardW = (width - spacing) / 2
        let cardH = (height - spacing) / 2

        return VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                homeButton("record", w: cardW, h: cardH) { onNavigate(.record) }
                homeButton("decode", w: cardW, h: cardH) { onNavigate(.analyze) }
            }
            HStack(spacing: spacing) {
                homeButton("browse", w: cardW, h: cardH) { onNavigate(.scan) }
                homeButton("debrief", w: cardW, h: cardH) { onNavigate(.threads) }
            }
        }
    }

    private func homeButton(
        _ label: String,
        w: CGFloat,
        h: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(TimbreFont.fontBold(size: 22))
                .foregroundStyle(Color(hex: "0088FF"))
                .frame(width: w, height: h)
                .background(
                    ZStack {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "F0FCFF"), Color(hex: "A0D8F8")],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.95),
                                        Color(hex: "0080C0").opacity(0.35),
                                    ],
                                    startPoint: .top, endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    }
                )
                .shadow(
                    color: Color(hex: "00C8FF").opacity(0.25),
                    radius: 4, y: 1
                )
        }
        .buttonStyle(HomeButtonPressStyle())
    }
}

struct HomeButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .offset(y: configuration.isPressed ? 1 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
