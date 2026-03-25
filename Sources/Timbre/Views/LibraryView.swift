import SwiftUI
import SwiftData

struct LibraryView: View {
    let memos: [Memo]
    @Binding var selectedMemo: Memo?
    @State private var viewModel = LibraryViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var memoToDelete: Memo?

    var body: some View {
        List(selection: $selectedMemo) {
            ForEach(viewModel.filteredMemos(memos)) { memo in
                MemoRow(memo: memo, viewModel: viewModel)
                    .tag(memo)
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            memoToDelete = memo
                        }
                    }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $viewModel.searchText, prompt: "Search memos")
        .navigationTitle("Library")
        .alert("Delete Memo?", isPresented: .init(
            get: { memoToDelete != nil },
            set: { if !$0 { memoToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let memo = memoToDelete {
                    if selectedMemo == memo { selectedMemo = nil }
                    viewModel.deleteMemo(memo, from: modelContext)
                }
                memoToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                memoToDelete = nil
            }
        } message: {
            Text("This will permanently remove the memo and its transcript.")
        }
        .overlay {
            if memos.isEmpty {
                ContentUnavailableView {
                    Label("No Memos", systemImage: "waveform")
                } description: {
                    Text("Import a voice memo to get started.")
                }
            }
        }
    }
}

private struct MemoRow: View {
    let memo: Memo
    let viewModel: LibraryViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(memo.title)
                .font(.headline)
                .lineLimit(1)

            HStack(spacing: 8) {
                Text(viewModel.formattedDuration(memo.duration))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(viewModel.formattedDate(memo.dateImported))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            statusBadge
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch memo.status {
        case .imported:
            Label("Ready", systemImage: "circle")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .transcribing(let progress):
            HStack(spacing: 4) {
                ProgressView(value: progress)
                    .frame(width: 60)
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        case .completed:
            Label("Transcribed", systemImage: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(.green)
        case .failed:
            Label("Failed", systemImage: "exclamationmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(.red)
        }
    }
}
