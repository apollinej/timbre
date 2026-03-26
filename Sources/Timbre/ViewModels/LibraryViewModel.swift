import Foundation
import SwiftData

@Observable
final class LibraryViewModel {
    var searchText = ""
    var sortOrder: SortOrder = .dateDescending

    enum SortOrder: String, CaseIterable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case titleAscending = "Title A-Z"
        case durationDescending = "Longest First"
    }

    func sorted(_ memos: [Memo]) -> [Memo] {
        let filtered = searchText.isEmpty
            ? memos
            : memos.filter { $0.title.localizedCaseInsensitiveContains(searchText) }

        return filtered.sorted { a, b in
            switch sortOrder {
            case .dateDescending: a.dateImported > b.dateImported
            case .dateAscending: a.dateImported < b.dateImported
            case .titleAscending: a.title.localizedCompare(b.title) == .orderedAscending
            case .durationDescending: a.duration > b.duration
            }
        }
    }
}
