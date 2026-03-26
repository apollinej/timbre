import Foundation
import SwiftData

@Model
final class Folder {
    var id: UUID
    var name: String
    var dateCreated: Date
    var sortIndex: Int
    @Relationship(deleteRule: .nullify, inverse: \Memo.folder)
    var memos: [Memo]

    init(name: String, sortIndex: Int = 0) {
        self.id = UUID()
        self.name = name
        self.dateCreated = .now
        self.sortIndex = sortIndex
        self.memos = []
    }
}
