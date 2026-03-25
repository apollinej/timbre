import SwiftUI

struct SpeakerBadge: View {
    let speaker: Speaker?
    @State private var isEditing = false
    @State private var editedName = ""

    var body: some View {
        Text(speaker?.name ?? "Unknown")
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill((speaker?.color ?? .gray).opacity(0.2))
            )
            .foregroundStyle(speaker?.color ?? .gray)
            .onTapGesture(count: 2) {
                editedName = speaker?.displayName ?? ""
                isEditing = true
            }
            .popover(isPresented: $isEditing) {
                VStack(spacing: 8) {
                    Text("Rename Speaker")
                        .font(.headline)
                    TextField("Name", text: $editedName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 160)
                        .onSubmit {
                            speaker?.displayName = editedName.isEmpty ? nil : editedName
                            isEditing = false
                        }
                    HStack {
                        Button("Cancel") { isEditing = false }
                        Button("Save") {
                            speaker?.displayName = editedName.isEmpty ? nil : editedName
                            isEditing = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
    }
}
