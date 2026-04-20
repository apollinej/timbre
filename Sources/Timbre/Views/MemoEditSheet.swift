import SwiftUI
import SwiftData

struct MemoEditSheet: View {
    @Bindable var memo: Memo
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var persons: [Person]
    @State private var personSearch = ""
    @State private var selectedPersons: [Person] = []

    var body: some View {
        VStack(spacing: 16) {
            Text("edit memo info")
                .font(TimbreFont.fontBold(size: 18))
                .foregroundStyle(Color(hex: "004878"))

            VStack(alignment: .leading, spacing: 12) {
                editField("name") {
                    TextField("memo title", text: $memo.title)
                        .textFieldStyle(.squareBorder)
                        .font(Theme.bodyFont)
                }

                editField("participants") {
                    participantsField
                }

                HStack(spacing: 12) {
                    editField("date") {
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { memo.dateRecorded ?? memo.dateImported },
                                set: { memo.dateRecorded = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                    }
                    editField("time") {
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { memo.dateRecorded ?? memo.dateImported },
                                set: { memo.dateRecorded = $0 }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }
                }

                editField("context") {
                    TextField(
                        "optional notes\u{2026}",
                        text: Binding(
                            get: { memo.context ?? "" },
                            set: { memo.context = $0.isEmpty ? nil : $0 }
                        )
                    )
                    .textFieldStyle(.squareBorder)
                    .font(Theme.bodyFont)
                }
            }

            HStack {
                Spacer()
                TimbrePill("done", style: .primary) {
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
        .padding(24)
        .frame(width: 420)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.chromeGradient)
        )
        .textCase(.lowercase)
    }

    // MARK: - Participants field

    private var participantsField: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !selectedPersons.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(selectedPersons) { person in
                        personChip(person)
                    }
                }
            }

            TextField("search people\u{2026}", text: $personSearch)
                .textFieldStyle(.squareBorder)
                .font(Theme.bodyFont)

            if !personSearch.isEmpty {
                personResults
            }
        }
    }

    private func personChip(_ person: Person) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(hex: person.colorHex))
                .frame(width: 10, height: 10)
            Text(person.canonicalName.lowercased())
                .font(Theme.smallMetaFont)
                .foregroundStyle(Color(hex: "044060"))
            Button {
                selectedPersons.removeAll { $0.id == person.id }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color(hex: "0080C0"))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color(hex: person.colorHex).opacity(0.15)))
    }

    private var personResults: some View {
        let filtered = persons.filter { p in
            p.matchesAlias(personSearch) &&
            !selectedPersons.contains(where: { $0.id == p.id })
        }
        return VStack(alignment: .leading, spacing: 2) {
            ForEach(filtered.prefix(5)) { person in
                Button {
                    selectedPersons.append(person)
                    personSearch = ""
                } label: {
                    HStack(spacing: 6) {
                        Circle().fill(Color(hex: person.colorHex)).frame(width: 8, height: 8)
                        Text(person.canonicalName).font(Theme.bodyFont)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            if filtered.isEmpty {
                Button {
                    let newPerson = Person(
                        canonicalName: personSearch,
                        colorHex: SpeakerColors.hex(for: persons.count)
                    )
                    modelContext.insert(newPerson)
                    selectedPersons.append(newPerson)
                    personSearch = ""
                } label: {
                    Text("+ create \"\(personSearch)\"")
                        .font(Theme.captionFont)
                        .foregroundStyle(Color(hex: "0088FF"))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func editField<Content: View>(
        _ label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Theme.captionFont)
                .foregroundStyle(Color(hex: "2090C8"))
            content()
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color(hex: "0080C0").opacity(0.2))
                        )
                )
        }
    }
}
