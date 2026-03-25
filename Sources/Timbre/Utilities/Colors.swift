import SwiftUI

enum SpeakerColors {
    static let palette: [String] = [
        "007AFF", // Blue
        "FF9500", // Orange
        "34C759", // Green
        "AF52DE", // Purple
        "FF2D55", // Pink
        "5AC8FA", // Teal
        "FFCC00", // Yellow
        "FF3B30", // Red
    ]

    static func color(for index: Int) -> String {
        palette[index % palette.count]
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
