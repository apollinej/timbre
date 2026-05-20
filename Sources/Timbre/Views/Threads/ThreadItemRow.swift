import SwiftUI

struct ThreadItemRow: View {
    let item: AnalysisItem
    let memoTitle: String?
    /// Tap on the meeting chip at bottom-left — opens the memo in the analyze view.
    let onOpenMemo: () -> Void
    /// Tap "answer" on a question/decision — opens the answer sheet.
    let onAnswer: () -> Void
    /// Tap "complete" on an action — marks done and triggers the dolphin celebration.
    let onComplete: () -> Void

    private var isAction: Bool { item.itemType == "action" }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.text)
                .font(Theme.bodyFont)
                .foregroundStyle(
                    item.isResolved
                        ? Color(hex: "2090C8").opacity(0.5)
                        : Color(hex: "043050")
                )
                .strikethrough(item.isResolved)
                .lineLimit(4)

            if let res = item.resolution?.trimmingCharacters(in: .whitespacesAndNewlines),
               !res.isEmpty {
                resolutionBlock(res)
            }

            HStack(spacing: 8) {
                meetingChip
                if let person = item.assignee {
                    Text(person.effectiveName.lowercased())
                        .font(TimbreFont.fontBold(size: 11))
                        .foregroundStyle(Color(hex: person.colorHex))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color(hex: person.colorHex).opacity(0.15)))
                }
                Spacer()
                actionButton
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .opacity(item.isResolved ? 0.7 : 1.0)
    }

    private func resolutionBlock(_ res: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Rectangle()
                .fill(Color(hex: "0088FF").opacity(0.35))
                .frame(width: 2)
            Text(res)
                .font(Theme.bodyFont)
                .italic()
                .foregroundStyle(Color(hex: "0468A0"))
                .lineLimit(4)
        }
        .padding(.leading, 4)
    }

    @ViewBuilder
    private var meetingChip: some View {
        if let title = memoTitle {
            Button(action: onOpenMemo) {
                HStack(spacing: 3) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text(title)
                        .font(TimbreFont.fontBold(size: 10))
                        .lineLimit(1)
                }
                .foregroundStyle(Color(hex: "0088FF"))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(
                        LinearGradient(
                            colors: [Color(hex: "F0FCFF"), Color(hex: "C8E8FF")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                )
                .overlay(
                    Capsule().strokeBorder(Color(hex: "0080C0").opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if item.isResolved {
            HStack(spacing: 3) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10, weight: .bold))
                Text(isAction ? "completed" : "answered")
                    .font(TimbreFont.fontBold(size: 10))
            }
            .foregroundStyle(Color(hex: "00A058"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color(hex: "00E070").opacity(0.15)))
        } else {
            Button {
                if isAction { onComplete() } else { onAnswer() }
            } label: {
                Text(isAction ? "complete" : "answer")
                    .font(TimbreFont.fontBold(size: 10))
                    .foregroundStyle(Color(hex: "0088FF"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                colors: [Color(hex: "F0FCFF"), Color(hex: "A0D8F8")],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    )
                    .overlay(
                        Capsule().strokeBorder(Color(hex: "0080C0").opacity(0.35), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}
