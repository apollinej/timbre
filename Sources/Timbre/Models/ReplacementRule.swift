import Foundation
import SwiftData

@Model
final class ReplacementRule {
    var id: UUID
    var original: String
    var replacement: String
    var scopeType: String
    var scopeMemoID: UUID?
    var dateCreated: Date
    var hitCount: Int

    init(
        original: String,
        replacement: String,
        scope: RuleScope = .global
    ) {
        self.id = UUID()
        self.original = original
        self.replacement = replacement
        self.dateCreated = .now
        self.hitCount = 0

        switch scope {
        case .global:
            self.scopeType = "global"
            self.scopeMemoID = nil
        case .memo(let memoID):
            self.scopeType = "memo"
            self.scopeMemoID = memoID
        }
    }

    var scope: RuleScope {
        if scopeType == "memo", let memoID = scopeMemoID {
            return .memo(memoID)
        }
        return .global
    }
}

enum RuleScope: Codable, Equatable {
    case global
    case memo(UUID)
}
