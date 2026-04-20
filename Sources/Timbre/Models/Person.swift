import Foundation
import SwiftData

@Model
final class Person {
    var id: UUID
    var canonicalName: String
    var aliasesData: Data
    var title: String?
    var email: String?
    var teamName: String?
    var colorHex: String
    var dateCreated: Date
    var workspaceID: UUID?
    var isMe: Bool

    init(
        canonicalName: String,
        aliases: [String] = [],
        colorHex: String,
        isMe: Bool = false
    ) {
        self.id = UUID()
        self.canonicalName = canonicalName
        self.aliasesData = (try? JSONEncoder().encode(aliases)) ?? Data()
        self.colorHex = colorHex
        self.dateCreated = .now
        self.isMe = isMe
    }

    var aliases: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: aliasesData)) ?? []
        }
        set {
            aliasesData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var effectiveName: String { canonicalName }

    func matchesAlias(_ query: String) -> Bool {
        let q = query.lowercased()
        if canonicalName.lowercased().contains(q) { return true }
        return aliases.contains { $0.lowercased().contains(q) }
    }
}
