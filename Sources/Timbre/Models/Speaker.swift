import Foundation
import SwiftData

@Model
final class Speaker {
    var id: UUID
    var label: String
    var displayName: String?
    var colorHex: String

    init(
        label: String,
        displayName: String? = nil,
        colorHex: String
    ) {
        self.id = UUID()
        self.label = label
        self.displayName = displayName
        self.colorHex = colorHex
    }

    var effectiveName: String {
        displayName ?? label
    }
}
