import SwiftUI

struct SpeakerBadge: View {
    let speaker: Speaker?

    var body: some View {
        Text((speaker?.effectiveName ?? "???").lowercased())
            .font(Theme.badgeFont)
            .foregroundStyle(Color.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    Capsule()
                        .fill(
                            RadialGradient(
                                colors: [badgeColor.opacity(0.95), badgeColor.opacity(0.65)],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 48
                            )
                        )
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.55), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.85), badgeColor.opacity(0.35)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: badgeColor.opacity(0.45), radius: 4, y: 2)
    }

    private var badgeColor: Color {
        guard let hex = speaker?.colorHex else { return Color(hex: "0088FF") }
        return Color(hex: hex)
    }
}
