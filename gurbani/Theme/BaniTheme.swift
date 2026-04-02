import SwiftUI

enum BaniTheme {
    // New vibrant palette
    static let amber = Color(hex: 0xF59E0B)        // Warm golden amber — primary accent
    static let deepPlum = Color(hex: 0x2D1B4E)     // Rich purple-black for text
    static let coral = Color(hex: 0xEF6461)         // Warm coral for alerts/highlights
    static let teal = Color(hex: 0x14B8A6)          // Fresh teal for success states
    static let lavender = Color(hex: 0x8B5CF6)      // Soft purple accent

    static let backgroundLight = Color(hex: 0xFCFBF8)
    static let backgroundDark = Color(hex: 0x121015)
    static let cardLight = Color.white
    static let cardDark = Color(hex: 0x1E1A24)
    static let secondaryText = Color(hex: 0x9CA3AF)
    static let divider = Color(hex: 0xF0ECE6)
    static let trackGrey = Color(hex: 0xE5E1D8)

    // Gradient
    static let accentGradient = LinearGradient(
        colors: [amber, Color(hex: 0xD97706)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Legacy alias so existing code doesn't break
    static let saffron = amber
    static let navy = deepPlum

    // Typography sizes
    static let gurmukhiSizeSmall: CGFloat = 22
    static let gurmukhiSizeMedium: CGFloat = 28
    static let gurmukhiSizeLarge: CGFloat = 34
    static let transliterationSize: CGFloat = 15
    static let translationSize: CGFloat = 14
    static let sectionHeaderSize: CGFloat = 11

    // Spacing
    static let screenPadding: CGFloat = 20
    static let cornerRadius: CGFloat = 16
    static let sheetCornerRadius: CGFloat = 24
}

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}

extension BaniTheme {
    static var background: Color {
        Color(light: backgroundLight, dark: backgroundDark)
    }

    static var cardBackground: Color {
        Color(light: cardLight, dark: cardDark)
    }

    static var gurmukhiColor: Color {
        Color(light: deepPlum, dark: .white)
    }
}

extension Color {
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

extension View {
    func baniCard() -> some View {
        self
            .padding()
            .background(BaniTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: BaniTheme.cornerRadius))
            .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }
}
