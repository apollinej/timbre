import SwiftUI

struct ScanListView: View {
    let memos: [Memo]
    let onSelect: (Memo) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(memos) { memo in
                    Button { onSelect(memo) } label: {
                        HStack(spacing: 12) {
                            Text(memo.title)
                                .font(TimbreFont.fontBold(size: 14))
                                .foregroundStyle(Color(hex: "044060"))
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(memo.formattedDuration)
                                .font(TimbreFont.font(size: 13))
                                .foregroundStyle(Color(hex: "0088C8"))

                            Text(memo.displayDate.formatted(
                                date: .abbreviated, time: .shortened
                            ))
                            .font(TimbreFont.font(size: 13))
                            .foregroundStyle(Color(hex: "0088C8"))
                            .frame(width: 120, alignment: .trailing)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Rectangle()
                        .fill(Color(hex: "40C8FF").opacity(0.25))
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 8)
        }
    }
}
