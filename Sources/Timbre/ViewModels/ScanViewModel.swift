import Foundation
import SwiftData

@MainActor @Observable
final class ScanViewModel {
    enum ViewMode: String, CaseIterable {
        case card, list, calendar
        var icon: String {
            switch self {
            case .card: "square.grid.2x2"
            case .list: "list.bullet"
            case .calendar: "calendar"
            }
        }
    }

    enum TimeFilter: String, CaseIterable {
        case week = "last week"
        case month = "30 days"
        case quarter = "90 days"
        case all = "all"
    }

    enum SortOrder: String, CaseIterable {
        case recent = "most recent"
        case alphabetical = "a-z"
    }

    var viewMode: ViewMode = .card
    var timeFilter: TimeFilter = .all
    var sortOrder: SortOrder = .recent
    var keyword: String = ""
    /// Lowercased effective speaker names selected for filtering.
    var selectedSpeakerNames: Set<String> = []

    /// Selected memo for side panel
    var selectedMemo: Memo?

    func filtered(_ memos: [Memo]) -> [Memo] {
        var result = memos

        // Browse is the database view — every memo (recording) appears here
        // regardless of analysis state. Analysis is a derived layer surfaced
        // in Debrief, not a gate on visibility.

        // Time filter
        if timeFilter != .all {
            let cutoff: Date
            switch timeFilter {
            case .week: cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
            case .month: cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now)!
            case .quarter: cutoff = Calendar.current.date(byAdding: .day, value: -90, to: .now)!
            case .all: cutoff = .distantPast
            }
            result = result.filter { $0.displayDate >= cutoff }
        }

        // Keyword filter
        if !keyword.isEmpty {
            let q = keyword.lowercased()
            result = result.filter { memo in
                if memo.title.lowercased().contains(q) { return true }
                if let segs = memo.transcript?.segments {
                    return segs.contains { $0.text.lowercased().contains(q) }
                }
                return false
            }
        }

        // Speaker filter — match by lowercased effective speaker name.
        // Chips are derived from real segments, so names always intersect cleanly.
        if !selectedSpeakerNames.isEmpty {
            result = result.filter { memo in
                guard let segs = memo.transcript?.segments else { return false }
                return segs.contains { seg in
                    guard let s = seg.speaker else { return false }
                    return selectedSpeakerNames.contains(s.effectiveName.lowercased())
                }
            }
        }

        // Sort
        switch sortOrder {
        case .recent:
            result.sort { $0.displayDate > $1.displayDate }
        case .alphabetical:
            result.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }

        return result
    }

    func selectNext(in memos: [Memo]) {
        guard let current = selectedMemo,
              let idx = memos.firstIndex(where: { $0.id == current.id }),
              idx + 1 < memos.count else { return }
        selectedMemo = memos[idx + 1]
    }

    func selectPrevious(in memos: [Memo]) {
        guard let current = selectedMemo,
              let idx = memos.firstIndex(where: { $0.id == current.id }),
              idx > 0 else { return }
        selectedMemo = memos[idx - 1]
    }
}
