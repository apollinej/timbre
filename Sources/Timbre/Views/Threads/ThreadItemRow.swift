import SwiftUI

struct ThreadItemRow: View {
    let item: AnalysisItem
    let memoTitle: String?
    let onToggleResolved: () -> Void
    let onOpenMemo: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button(action: onToggleResolved) {
                Image(systemName: item.isResolved
                    ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(
                        item.isResolved
                            ? Color(hex: "00E070")
                            : Color(hex: "0088C8")
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 5) {
                Text(item.text)
                    .font(Theme.bodyFont)
                    .foregroundStyle(
                        item.isResolved
                            ? Color(hex: "2090C8").opacity(0.4)
                            : Color(hex: "043050")
                    )
                    .strikethrough(item.isResolved)
                    .lineLimit(3)

                HStack(spacing: 8) {
                    if let title = memoTitle {
                        Button(action: onOpenMemo) {
                            HStack(spacing: 3) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 10))
                                Text(title)
                                    .font(TimbreFont.font(size: 11))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(Color(hex: "0088FF"))
                        }
                        .buttonStyle(.plain)
                    }

                    if let person = item.assignee {
                        Text(person.effectiveName.lowercased())
                            .font(TimbreFont.fontBold(size: 11))
                            .foregroundStyle(Color(hex: person.colorHex))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color(hex: person.colorHex).opacity(0.15)))
                    }

                    Spacer()

                    Text(item.dateCreated.formatted(date: .abbreviated, time: .omitted))
                        .font(TimbreFont.font(size: 11))
                        .foregroundStyle(Color(hex: "2090C8"))
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .opacity(item.isResolved ? 0.6 : 1.0)
    }
}
