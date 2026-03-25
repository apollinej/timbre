import SwiftUI

struct SegmentRow: View {
    let segment: Segment
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SpeakerBadge(speaker: segment.speaker)

            VStack(alignment: .leading, spacing: 4) {
                Text(segment.durationText)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()

                Text(segment.text)
                    .font(.body)
                    .textSelection(.enabled)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? Color.accentColor.opacity(0.08) : .clear)
        )
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}
