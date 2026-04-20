import Foundation
import SwiftData

@Model
final class Workspace {
    var id: UUID
    var name: String
    var cloudKitShareID: String?
    var isOwner: Bool
    var dateCreated: Date

    init(name: String, isOwner: Bool = true) {
        self.id = UUID()
        self.name = name
        self.isOwner = isOwner
        self.dateCreated = .now
    }
}
