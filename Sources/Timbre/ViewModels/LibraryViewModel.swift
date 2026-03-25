import Foundation
import SwiftData

@Observable
final class LibraryViewModel {
    var searchText = ""

    func filteredMemos(_ memos: [Memo]) -> [Memo] {
        guard !searchText.isEmpty else { return memos }
        let query = searchText.lowercased()
        return memos.filter { memo in
            memo.title.lowercased().contains(query) ||
            memo.transcript?.fullText.lowercased().contains(query) == true
        }
    }

    func deleteMemo(_ memo: Memo, from context: ModelContext) {
        context.delete(memo)
        try? context.save()
    }

    func formattedDuration(_ duration: TimeInterval) -> String {
        TimeFormatter.format(duration)
    }

    func formattedDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
}
