import SwiftUI

enum BaniTheme {
    // Primary palette — warm and alive
    static let gold = Color(hex: 0xD4943A)           // Warm golden honey
    static let espresso = Color(hex: 0x2C1810)        // Rich dark brown for text
    static let warmCream = Color(hex: 0xFFF8EF)       // Soft warm ivory bg
    static let parchment = Color(hex: 0xFDF2E3)       // Slightly deeper warm card bg
    static let terracotta = Color(hex: 0xC17B5A)      // Warm earthy accent
    static let sage = Color(hex: 0x6B8F71)            // Muted green for success
    static let rose = Color(hex: 0xD4726A)            // Soft warm red for alerts

    // Dark mode palette
    static let darkBg = Color(hex: 0x1A1612)          // Warm dark walnut
    static let darkCard = Color(hex: 0x2A2420)         // Warm dark card
    static let darkAccent = Color(hex: 0xE8A951)       // Brighter gold for dark mode

    // Neutrals
    static let textSecondary = Color(hex: 0x8B7E74)    // Warm grey
    static let dividerColor = Color(hex: 0xEDE5D8)     // Warm divider
    static let trackColor = Color(hex: 0xE5DDD0)       // Warm track

    // Gradients
    static let goldGradient = LinearGradient(
        colors: [Color(hex: 0xD4943A), Color(hex: 0xBF7B2A)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let warmGradient = LinearGradient(
        colors: [Color(hex: 0xFFF8EF), Color(hex: 0xFDF2E3)],
        startPoint: .top,
        endPoint: .bottom
    )

    // Aliases for backward compat
    static let saffron = gold
    static let amber = gold
    static let navy = espresso
    static let deepPlum = espresso
    static let coral = rose
    static let secondaryText = textSecondary
    static let divider = dividerColor
    static let trackGrey = trackColor

    // Typography
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
        Color(light: warmCream, dark: darkBg)
    }

    static var cardBackground: Color {
        Color(light: .white, dark: darkCard)
    }

    static var gurmukhiColor: Color {
        Color(light: espresso, dark: Color(hex: 0xFAF0E6))
    }

    static var accentColor: Color {
        Color(light: gold, dark: darkAccent)
    }

    static var inputBackground: Color {
        Color(light: parchment, dark: Color(hex: 0x352F2B))
    }

    static var accentGradient: LinearGradient {
        goldGradient
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
            .shadow(color: Color(hex: 0xC9B99A).opacity(0.15), radius: 8, y: 4)
    }
}
