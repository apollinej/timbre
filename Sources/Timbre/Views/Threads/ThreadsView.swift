import SwiftUI
import SwiftData

struct ThreadsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [AnalysisItem]
    @Query(sort: \Memo.dateImported, order: .reverse) private var memos: [Memo]
    @Query private var persons: [Person]
    @State private var vm = ThreadsViewModel()
    let onGoHome: () -> Void
    let onOpenMemo: (Memo) -> Void

    private var questionItems: [AnalysisItem] {
        vm.filtered(allItems.filter { $0.itemType == "thread" }, memos: memos)
    }
    private var decisionItems: [AnalysisItem] {
        vm.filtered(allItems.filter { $0.itemType == "decision" }, memos: memos)
    }
    private var actionItems: [AnalysisItem] {
        vm.filtered(allItems.filter { $0.itemType == "action" }, memos: memos)
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                headerBanner
                filterBar
                columns
            }
        }
    }

    private var background: some View {
        ZStack { Theme.playerFaceGradient; SubtleScanlines() }
    }

    // MARK: - Header

    private var headerBanner: some View {
        ZStack {
            BrushedMetal(baseColor: Color(hex: "B0E0F8"), intensity: 0.32)
            VStack {
                Rectangle().fill(Color.white.opacity(0.55)).frame(height: 1)
                Spacer()
                Rectangle().fill(Color(hex: "0080C0").opacity(0.18)).frame(height: 1)
            }
            Text("debrief")
                .font(TimbreFont.fontBold(size: 22))
                .foregroundStyle(Color(hex: "004878"))
            HStack {
                Spacer()
                HomeButton(action: onGoHome).padding(.trailing, 12)
            }
        }
        .frame(height: 48)
    }

    // MARK: - Filters (matching scan page)

    private var filterBar: some View {
        HStack(spacing: 8) {
            // Person chips
            if !persons.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(persons) { person in
                            TimbrePersonChip(
                                person: person,
                                isSelected: vm.selectedPersonIDs.contains(person.id)
                            ) {
                                if vm.selectedPersonIDs.contains(person.id) {
                                    vm.selectedPersonIDs.remove(person.id)
                                } else {
                                    vm.selectedPersonIDs.insert(person.id)
                                }
                            }
                        }
                    }
                }
            }

            Spacer()

            // Time pills
            ForEach(ThreadsViewModel.TimeFilter.allCases, id: \.self) { tf in
                TimbreTogglePill(
                    label: tf.rawValue,
                    isSelected: vm.timeFilter == tf
                ) { vm.timeFilter = tf }
            }

            // Resolved toggle
            TimbreTogglePill(
                label: "resolved",
                isSelected: vm.showResolved
            ) { vm.showResolved.toggle() }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [Color(hex: "D8F4FF"), Color(hex: "C8ECFF")],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    // MARK: - Three columns

    private var columns: some View {
        HStack(spacing: 0) {
            column("open questions", items: questionItems)
            columnDivider
            column("key decisions", items: decisionItems)
            columnDivider
            column("action items", items: actionItems)
        }
    }

    private func column(
        _ title: String,
        items: [AnalysisItem]
    ) -> some View {
        VStack(spacing: 0) {
            // Simple header
            HStack(spacing: 6) {
                Text(title)
                    .font(TimbreFont.fontBold(size: 13))
                    .foregroundStyle(Color(hex: "0088FF"))
                if !items.isEmpty {
                    Text("\(items.count)")
                        .font(TimbreFont.font(size: 11))
                        .foregroundStyle(Color(hex: "0088FF"))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(
                            Capsule().fill(Color(hex: "0088FF").opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            Rectangle()
                .fill(Color(hex: "40C8FF").opacity(0.25))
                .frame(height: 1)

            // Items
            if items.isEmpty {
                VStack {
                    Spacer()
                    Text("none")
                        .font(TimbreFont.font(size: 13))
                        .foregroundStyle(Color(hex: "2090C8"))
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items) { item in
                            ThreadItemRow(
                                item: item,
                                memoTitle: vm.memoTitle(for: item, memos: memos),
                                onToggleResolved: {
                                    item.isResolved.toggle()
                                    try? modelContext.save()
                                },
                                onOpenMemo: {
                                    if let id = item.sourceMemoID,
                                       let memo = memos.first(where: { $0.id == id }) {
                                        onOpenMemo(memo)
                                    }
                                }
                            )
                            Rectangle()
                                .fill(Color(hex: "40C8FF").opacity(0.15))
                                .frame(height: 1)
                                .padding(.horizontal, 8)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var columnDivider: some View {
        Rectangle()
            .fill(Color(hex: "40C8FF").opacity(0.3))
            .frame(width: 1)
    }
}
