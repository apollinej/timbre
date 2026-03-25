import Foundation
import SwiftData
import SwiftUI

@Model
final class Speaker {
    var id: UUID
    var label: String
    var displayName: String?
    var colorHex: String

    init(label: String, colorHex: String) {
        self.id = UUID()
        self.label = label
        self.displayName = nil
        self.colorHex = colorHex
    }

    var name: String {
        displayName ?? label
    }

    var color: Color {
        Color(hex: colorHex)
    }
}
