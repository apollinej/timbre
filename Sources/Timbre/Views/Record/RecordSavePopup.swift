import SwiftUI
import SwiftData

struct RecordSavePopup: View {
    @Bindable var vm: RecordViewModel
    let modelContext: ModelContext
    @Query private var persons: [Person]
    @State private var personSearch = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("save memo as")
                .font(TimbreFont.fontBold(size: 18))
                .foregroundStyle(Color(hex: "004878"))

            VStack(alignment: .leading, spacing: 12) {
                field("name") {
                    TextField("memo title", text: $vm.memoTitle)
                        .textFieldStyle(.squareBorder)
                        .font(Theme.bodyFont)
                }

                field("participants") {
                    VStack(alignment: .leading, spacing: 6) {
                        // Selected chips
                        if !vm.selectedPersons.isEmpty {
                            FlowLayout(spacing: 4) {
                                ForEach(vm.selectedPersons) { person in
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

                HStack(spacing: 12) {
                    field("date") {
                        DatePicker("", selection: $vm.memoDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    field("time") {
                        DatePicker("", selection: $vm.memoDate, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                }

                field("context") {
                    TextField("optional notes\u{2026}", text: $vm.memoContext)
                        .textFieldStyle(.squareBorder)
                        .font(Theme.bodyFont)
                }
            }

            HStack(spacing: 12) {
                TimbrePill("discard", style: .secondary) { vm.discard(); dismiss() }
                Spacer()
                TimbrePill("save", style: .primary) {
                    _ = vm.saveMemo(context: modelContext)
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
    }

    private func field<Content: View>(
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

    private func personChip(_ person: Person) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(hex: person.colorHex))
                .frame(width: 10, height: 10)
            Text(person.canonicalName.lowercased())
                .font(Theme.smallMetaFont)
                .foregroundStyle(Color(hex: "044060"))
            Button {
                vm.selectedPersons.removeAll { $0.id == person.id }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color(hex: "0080C0"))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(Color(hex: person.colorHex).opacity(0.15))
        )
    }

    private var personResults: some View {
        let filtered = persons.filter { p in
            p.matchesAlias(personSearch) &&
            !vm.selectedPersons.contains(where: { s in s.id == p.id })
        }
        return VStack(alignment: .leading, spacing: 2) {
            ForEach(filtered.prefix(5)) { person in
                Button {
                    vm.selectedPersons.append(person)
                    personSearch = ""
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: person.colorHex))
                            .frame(width: 8, height: 8)
                        Text(person.canonicalName)
                            .font(Theme.bodyFont)
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
                    vm.selectedPersons.append(newPerson)
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
}

/// Simple flow layout for person chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
