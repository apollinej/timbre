import SwiftUI

enum Theme {
    // MARK: - Frutiger Aero / vintage Mac player palette (vibrant blue, green, chrome, white)

    static let chromeDark = Color(hex: "3A5A78")
    static let chromeMid = Color(hex: "6CA0D0")
    static let chromeLight = Color(hex: "B0E0FF")
    static let chromeHighlight = Color(hex: "F0FCFF")

    static let windowBg = Color(hex: "C8E8FF")
    static let sidebarBg = Color(hex: "90D0F0")
    static let transcriptBg = Color(hex: "E0F8FF")

    static let textPrimary = Color(hex: "044060")
    static let textSecondary = Color(hex: "0870B0")
    static let textDim = Color(hex: "2090C8")

    static let accent = Color(hex: "0088FF")
    static let accentLight = Color(hex: "40D0FF")
    static let limePop = Color(hex: "00F088")
    static let limeDeep = Color(hex: "00C060")

    static let aquaBlue = Color(hex: "00B4FF")
    static let iceWhite = Color(hex: "FAFFFF")

    static let speakerPalette: [String] = [
        "0080FF",
        "00D0A0",
        "20C0FF",
        "00E868",
        "4080FF",
        "00FFC8",
        "0090E0",
        "60FF90",
    ]

    // MARK: - Gradients

    static let chromeGradient = LinearGradient(
        colors: [
            Color(hex: "E8F8FF"),
            Color(hex: "B8E0F8"),
            Color(hex: "D0F0FF"),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let iridescent = LinearGradient(
        colors: [
            Color(hex: "E0F8FF"),
            Color(hex: "C8F0FF"),
            Color(hex: "D8FFF0"),
            Color(hex: "B8E8FF"),
            Color(hex: "E0FFFF"),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let iridescentSubtle = LinearGradient(
        colors: [
            Color(hex: "F0FCFF"),
            Color(hex: "D8F4FF"),
            Color(hex: "E8FFF8"),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let darkChrome = LinearGradient(
        colors: [
            Color(hex: "5080A8"),
            Color(hex: "306890"),
            Color(hex: "184868"),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let playerFaceGradient = LinearGradient(
        colors: [
            Color(hex: "F8FFFF"),
            Color(hex: "D0F0FF"),
            Color(hex: "E8FFF8"),
            Color(hex: "C8E8FF"),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Fonts (DotGothic16 — register in TimbreApp)

    static let largeTitleFont = TimbreFont.fontBold(size: 20)
    static let titleFont = TimbreFont.fontBold(size: 17)
    static let bodyFont = TimbreFont.font(size: 15)
    static let captionFont = TimbreFont.font(size: 13)
    static let badgeFont = TimbreFont.font(size: 13)
    static let smallMetaFont = TimbreFont.font(size: 12)

    static let cornerRadius: CGFloat = 10
    static let borderWidth: CGFloat = 1
}

struct RetroBevel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.65),
                                Color.clear,
                                Color(hex: "0060A0").opacity(0.25),
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
                                Color(hex: "004070").opacity(0.35),
                                Color.clear,
                                Color.white.opacity(0.5),
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
