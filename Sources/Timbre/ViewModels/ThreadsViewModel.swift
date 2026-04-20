import Foundation
import SwiftData

@MainActor @Observable
final class ThreadsViewModel {
    enum TimeFilter: String, CaseIterable {
        case week = "last week"
        case month = "30 days"
        case quarter = "90 days"
        case all = "all"
    }

    var timeFilter: TimeFilter = .all
    var selectedPersonIDs: Set<UUID> = []
    var showResolved = false

    func filtered(_ items: [AnalysisItem], memos: [Memo]) -> [AnalysisItem] {
        var result = items

        // Time filter
        if timeFilter != .all {
            let cutoff: Date
            switch timeFilter {
            case .week: cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
            case .month: cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now)!
            case .quarter: cutoff = Calendar.current.date(byAdding: .day, value: -90, to: .now)!
            case .all: cutoff = .distantPast
            }
            result = result.filter { $0.dateCreated >= cutoff }
        }

        // Person filter
        if !selectedPersonIDs.isEmpty {
            result = result.filter { item in
                if let assignee = item.assignee {
                    return selectedPersonIDs.contains(assignee.id)
                }
                return false
            }
        }

        // Resolved filter
        if !showResolved {
            result = result.filter { !$0.isResolved }
        }

        return result.sorted { $0.dateCreated > $1.dateCreated }
    }

    func memoTitle(for item: AnalysisItem, memos: [Memo]) -> String? {
        guard let memoID = item.sourceMemoID else { return nil }
        return memos.first { $0.id == memoID }?.title
    }
}
