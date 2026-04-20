import SwiftUI

struct ScanCardGrid: View {
    let memos: [Memo]
    let onSelect: (Memo) -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14),
                ],
                spacing: 14
            ) {
                ForEach(memos) { memo in
                    ScanCard(memo: memo) { onSelect(memo) }
                }
            }
            .padding(14)
        }
    }
}

struct ScanCard: View {
    let memo: Memo
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(memo.title)
                    .font(TimbreFont.fontBold(size: 14))
                    .foregroundStyle(Color(hex: "044060"))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Participants
                if let segs = memo.transcript?.segments {
                    let speakers = uniqueSpeakers(from: segs)
                    if !speakers.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(speakers.prefix(4)) { spk in
                                HStack(spacing: 3) {
                                    Circle()
                                        .fill(Color(hex: spk.colorHex))
                                        .frame(width: 6, height: 6)
                                    Text(spk.effectiveName.lowercased())
                                        .font(TimbreFont.font(size: 10))
                                        .foregroundStyle(Color(hex: "044060"))
                                }
                            }
                        }
                    }
                }

                // Date & time
                Text(memo.displayDate.formatted(date: .abbreviated, time: .shortened))
                    .font(TimbreFont.font(size: 12))
                    .foregroundStyle(Color(hex: "0088C8"))

                // Context if any
                if let context = memo.context, !context.isEmpty {
                    Text(context)
                        .font(Theme.bodyFont)
                        .foregroundStyle(Color(hex: "2090C8"))
                        .lineLimit(2)
                        .italic()
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "F0FCFF"), Color(hex: "D8F0FF")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color(hex: "0080C0").opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color(hex: "004060").opacity(0.08), radius: 4, y: 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScanCardPressStyle())
    }

    private func uniqueSpeakers(from segments: [Segment]) -> [Speaker] {
        var seen = Set<UUID>()
        var result: [Speaker] = []
        for seg in segments {
            if let s = seg.speaker, !seen.contains(s.id) {
                seen.insert(s.id)
                result.append(s)
            }
        }
        return result
    }
}

struct ScanCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(
                color: Color(hex: "00C8FF").opacity(configuration.isPressed ? 0.3 : 0),
                radius: 6, y: 0
            )
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
