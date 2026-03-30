import SwiftUI

enum BaniTheme {
    // Colors
    static let saffron = Color(hex: 0xFF9933)
    static let navy = Color(hex: 0x1B2A4A)
    static let backgroundLight = Color(hex: 0xFAF8F5)
    static let backgroundDark = Color(hex: 0x1C1C1E)
    static let cardLight = Color.white
    static let cardDark = Color(hex: 0x2C2C2E)
    static let secondaryText = Color(hex: 0x8A8A8E)
    static let divider = Color(hex: 0xF0F0F0)
    static let trackGrey = Color(hex: 0xE5E5EA)

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

// Adaptive colors for dark mode
extension BaniTheme {
    static var background: Color {
        Color(light: backgroundLight, dark: backgroundDark)
    }

    static var cardBackground: Color {
        Color(light: cardLight, dark: cardDark)
    }

    static var gurmukhiColor: Color {
        Color(light: navy, dark: .white)
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
