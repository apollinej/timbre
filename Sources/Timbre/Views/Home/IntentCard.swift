import SwiftUI

struct IntentCard: View {
    let label: String
    let action: () -> Void

    @State private var isPressed = false

    // Text ~20% smaller than timbre title (38pt) = ~30pt, bright blue
    private let textSize: CGFloat = 30

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(TimbreFont.fontBold(size: textSize))
                .foregroundStyle(Color(hex: "0088FF"))
                .shadow(color: .white.opacity(0.6), radius: 0, y: 1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(cardBackground)
                // 3D depth: outer shadow lifts card off surface
                .shadow(
                    color: Color(hex: "003050").opacity(isPressed ? 0.1 : 0.4),
                    radius: isPressed ? 2 : 8,
                    y: isPressed ? 1 : 5
                )
                // Inner glow when not pressed
                .shadow(
                    color: Color(hex: "00C8FF").opacity(isPressed ? 0 : 0.15),
                    radius: isPressed ? 0 : 12,
                    y: 0
                )
                // Press: scale down + snap back with spring
                .scaleEffect(isPressed ? 0.96 : 1.0)
                // Slight vertical shift to simulate physical press
                .offset(y: isPressed ? 2 : 0)
                .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        // TODO: whimsy — add subtle sparkle on hover
    }

    private var cardBackground: some View {
        ZStack {
            // Base gradient — slightly darker when pressed
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: isPressed
                            ? [Color(hex: "A0C8E8"), Color(hex: "80B0D8"), Color(hex: "70A0D0")]
                            : [Color(hex: "D0EEFF"), Color(hex: "A0D0F0"), Color(hex: "88C0E8")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Brushed metal texture
            BrushedMetal(baseColor: Color(hex: "B0D8F0"), intensity: 0.25)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            // Cyan border
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color(hex: "00E8FF").opacity(isPressed ? 0.3 : 0.6),
                            Color(hex: "0088FF").opacity(isPressed ? 0.15 : 0.3),
                        ],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )

            // Top highlight — fades when pressed (light source simulation)
            VStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isPressed ? 0.15 : 0.5),
                                Color.clear,
                            ],
                            startPoint: .top, endPoint: .center
                        )
                    )
                    .frame(height: 40)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Bottom inner shadow when pressed (simulates physical depth)
            if isPressed {
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.clear, Color(hex: "004060").opacity(0.1)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(height: 30)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}
