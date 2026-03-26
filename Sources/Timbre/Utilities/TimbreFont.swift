import CoreText
import SwiftUI

enum TimbreFont {
    /// Matches DotGothic16-Regular.ttf (Google Fonts).
    static let customName = "DotGothic16-Regular"

    static func register() {
        guard let url = Bundle.module.url(forResource: "DotGothic16-Regular", withExtension: "ttf") else {
            return
        }
        var error: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
    }

    static func font(size: CGFloat) -> Font {
        Font.custom(customName, size: size)
    }

    /// DotGothic16 is single-weight; this requests synthesized bold from the system.
    static func fontBold(size: CGFloat) -> Font {
        Font.custom(customName, size: size).weight(.bold)
    }
}
