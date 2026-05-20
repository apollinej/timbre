import Foundation
import SwiftData

@Model
final class AnalysisItem {
    var id: UUID
    var text: String
    var assignee: Person?
    var isResolved: Bool
    var dateCreated: Date
    var sourceMemoID: UUID?
    /// "action", "thread", or "decision" — used by Threads view for cross-memo queries
    var itemType: String?
    /// User-written answer for a question/decision, or note when completing
    /// an action. Persisted to the .md file as `> quote` under the bullet.
    var resolution: String?

    init(
        text: String,
        assignee: Person? = nil,
        sourceMemoID: UUID? = nil,
        itemType: String? = nil
    ) {
        self.id = UUID()
        self.text = text
        self.assignee = assignee
        self.isResolved = false
        self.dateCreated = .now
        self.sourceMemoID = sourceMemoID
        self.itemType = itemType
        self.resolution = nil
    }
}
