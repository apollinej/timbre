import SwiftUI

struct SpeakerBadge: View {
    let speaker: Speaker?

    var body: some View {
        Text((speaker?.effectiveName ?? "???").lowercased())
            .font(Theme.badgeFont)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.25))
            .foregroundStyle(badgeColor)
            .overlay(
                Rectangle()
                    .strokeBorder(badgeColor.opacity(0.5), lineWidth: 1)
            )
    }

    private var badgeColor: Color {
        guard let hex = speaker?.colorHex else { return Theme.chromeMid }
        return Color(hex: hex)
    }
}
