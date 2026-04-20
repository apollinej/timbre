import SwiftUI

struct PersonRenameSheet: View {
    let person: Person
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            Text("rename speaker")
                .font(TimbreFont.fontBold(size: 17))
                .foregroundStyle(Color(hex: "044060"))

            Text("applies across all memos with this speaker")
                .font(Theme.captionFont)
                .foregroundStyle(Color(hex: "0088C8"))

            TextField("name", text: $text)
                .textFieldStyle(.squareBorder)
                .font(TimbreFont.font(size: 15))
                .focused($isFocused)
                .onSubmit { save() }

            HStack {
                TimbrePill("discard", style: .secondary) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                TimbrePill("save", style: .primary) { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(minWidth: 380)
        .background(
            LinearGradient(
                colors: [Color(hex: "F0FCFF"), Color(hex: "D0E8FF")],
                startPoint: .top, endPoint: .bottom
            )
        )
        .textCase(.lowercase)
        .onAppear {
            text = person.canonicalName
            isFocused = true
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSave(trimmed)
        dismiss()
    }
}
