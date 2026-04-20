import Foundation
import SwiftData

@Model
final class MemoAnalysis {
    var id: UUID
    var summary: String?
    var detailedNotes: String?
    @Relationship(deleteRule: .cascade) var actionItems: [AnalysisItem]
    @Relationship(deleteRule: .cascade) var openThreads: [AnalysisItem]
    @Relationship(deleteRule: .cascade) var keyDecisions: [AnalysisItem]
    var dateAnalyzed: Date
    var analysisModelUsed: String
    var isStale: Bool

    init(analysisModelUsed: String) {
        self.id = UUID()
        self.actionItems = []
        self.openThreads = []
        self.keyDecisions = []
        self.dateAnalyzed = .now
        self.analysisModelUsed = analysisModelUsed
        self.isStale = false
    }
}
