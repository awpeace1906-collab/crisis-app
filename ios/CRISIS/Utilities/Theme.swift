import SwiftUI

/// CV dark palette, ported 1:1 from the web app's tokens.css so native and
/// PWA builds read as the same product.
enum Theme {
    static let bg = Color(hex: 0x0a0e14)
    static let surface = Color(hex: 0x111720)
    static let surface2 = Color(hex: 0x182030)
    static let border = Color.white.opacity(0.08)

    static let teal = Color(hex: 0x00d4aa)
    static let blue = Color(hex: 0x2563eb)
    static let red = Color(hex: 0xe84c4c)
    static let amber = Color(hex: 0xf59e0b)
    static let purple = Color(hex: 0xa78bfa)

    static let text = Color(hex: 0xe8edf5)
    static let text2 = Color(hex: 0x8a9ab5)
    static let text3 = Color(hex: 0x4a5670)

    static func tint(_ name: String) -> Color { color(name).opacity(0.12) }

    static func color(_ name: String) -> Color {
        switch name {
        case "teal": return teal
        case "blue": return blue
        case "red": return red
        case "amber": return amber
        case "purple": return purple
        default: return teal
        }
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

/// Fonts: the same three families the web app pulls from Google Fonts —
/// Syne, Source Serif 4, IBM Plex Mono — bundled as real font files
/// (`Resources/Fonts/`, registered via `UIAppFonts` in project.yml) rather
/// than system-font stand-ins, for true visual parity with the PWA.
///
/// Syne and Source Serif 4 ship as variable fonts (wght axis, +opsz for the
/// serif). `Font.custom(name:size:).weight(_:)` interpolates a registered
/// variable font's weight axis automatically on iOS 16+, so one Font.custom
/// base name covers every weight the web app uses (Syne 400/600/700/800,
/// Source Serif 4 300/400/600). IBM Plex Mono ships as static per-weight
/// files instead (Google Fonts doesn't publish it as variable), so the
/// closest static weight is picked explicitly rather than interpolated.
enum AppFont {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .custom("Syne-Regular", size: size).weight(weight)
    }

    static func serif(_ size: CGFloat, italic: Bool = false, weight: Font.Weight = .regular) -> Font {
        let name = italic ? "SourceSerif4Italic-Italic" : "SourceSerif4Roman-Regular"
        return .custom(name, size: size).weight(weight)
    }

    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        let name: String
        switch weight {
        case .semibold, .bold, .heavy, .black: name = "IBMPlexMono-SemiBold"
        case .medium: name = "IBMPlexMono-Medium"
        default: name = "IBMPlexMono-Regular"
        }
        return .custom(name, size: size)
    }
}
