import SwiftUI

/// Modal that pops up when the user taps "answer" on an open question
/// or key decision. Free-text response is saved as the item's
/// `resolution` and marks it resolved. Persists to the .md file as a
/// `> blockquote` nested under the bullet.
struct AnswerSheet: View {
    let item: AnalysisItem
    @Binding var draft: String
    let onSave: () -> Void
    let onCancel: () -> Void

    private var heading: String {
        item.itemType == "decision" ? "respond to decision" : "answer this question"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(heading)
                    .font(TimbreFont.fontBold(size: 16))
                    .foregroundStyle(Color(hex: "044060"))
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: "0088C8"))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Text(item.text)
                .font(Theme.bodyFont)
                .foregroundStyle(Color(hex: "043050"))
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

            TextEditor(text: $draft)
                .font(.system(size: 13))
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: 200)
                .background(Color.white.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color(hex: "0080C0").opacity(0.3))
                )
                .padding(.horizontal, 16)

            HStack {
                Text("saved to the meeting's .md file and marked resolved.")
                    .font(TimbreFont.font(size: 11))
                    .foregroundStyle(Color(hex: "2090C8"))
                Spacer()
                TimbrePill("save", style: .primary, action: onSave)
            }
            .padding(16)
        }
        .frame(width: 520, height: 380)
        .background(Theme.iridescentSubtle)
    }
}
