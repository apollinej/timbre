import SwiftUI

enum Theme {
    // MARK: - Core Palette (Y2K chrome / dark accents / iridescent)

    // Chrome shell
    static let chromeDark = Color(hex: "3A3A4A")
    static let chromeMid = Color(hex: "8888A0")
    static let chromeLight = Color(hex: "B8B8C8")
    static let chromeHighlight = Color(hex: "D8D8E8")

    // Backgrounds
    static let windowBg = Color(hex: "C8C4D8")
    static let sidebarBg = Color(hex: "B0ACC4")
    static let transcriptBg = Color(hex: "D4D0E0")

    // Text
    static let textPrimary = Color(hex: "1A1828")
    static let textSecondary = Color(hex: "5A5670")
    static let textDim = Color(hex: "8884A0")

    // Accent
    static let accent = Color(hex: "6A5ACD")  // Slate blue
    static let accentLight = Color(hex: "9890E0")

    // Active/highlight (iridescent-inspired)
    static let iridescentPink = Color(hex: "E8B0D0")
    static let iridescentBlue = Color(hex: "A0C0E8")
    static let iridescentLilac = Color(hex: "C8B8E8")

    // MARK: - Speaker Colors (cohesive cool-tone palette, NO orange/cyan)

    static let speakerPalette: [String] = [
        "7B68C8", // Deep lavender
        "C878A8", // Dusty rose
        "6888B8", // Steel blue
        "9878B8", // Plum
        "A8A0D0", // Periwinkle
        "B868A0", // Mauve
        "7898C0", // Slate
        "8878A8", // Violet grey
    ]

    // MARK: - Gradients

    static let chromeGradient = LinearGradient(
        colors: [
            Color(hex: "D0CCE0"),
            Color(hex: "B8B4C8"),
            Color(hex: "C4C0D4"),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let iridescent = LinearGradient(
        colors: [
            Color(hex: "D8D0F0"),
            Color(hex: "C8D8F0"),
            Color(hex: "E0D0E8"),
            Color(hex: "D0D8F0"),
            Color(hex: "D8C8E8"),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let iridescentSubtle = LinearGradient(
        colors: [
            Color(hex: "E0DCF0"),
            Color(hex: "D8E0F0"),
            Color(hex: "E8DCE8"),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let darkChrome = LinearGradient(
        colors: [
            Color(hex: "4A4660"),
            Color(hex: "3A3650"),
            Color(hex: "2E2A40"),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Fonts (monospace for that terminal/Winamp feel)

    static let titleFont = Font.system(size: 12, weight: .bold, design: .monospaced)
    static let bodyFont = Font.system(size: 12, design: .default)
    static let captionFont = Font.system(size: 10, design: .monospaced)
    static let badgeFont = Font.system(size: 10, weight: .bold, design: .monospaced)

    // MARK: - Geometry (sharp, not soft)

    static let cornerRadius: CGFloat = 2
    static let borderWidth: CGFloat = 1
}

// MARK: - Retro Border Modifier (1px inset bevel like classic UI)

struct RetroBevel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.clear,
                                Color.black.opacity(0.2),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

struct RetroInset: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.25),
                                Color.clear,
                                Color.white.opacity(0.4),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

extension View {
    func retroBevel() -> some View {
        modifier(RetroBevel())
    }

    func retroInset() -> some View {
        modifier(RetroInset())
    }
}
