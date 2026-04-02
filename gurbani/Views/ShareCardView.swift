import SwiftUI

struct ShareCardView: View {
    let gurmukhi: String
    let translation: String
    let baniName: String

    var body: some View {
        VStack(spacing: 0) {
            // Top decorative bar
            BaniTheme.accentGradient
                .frame(height: 6)

            VStack(spacing: 24) {
                // Ik Onkar symbol
                Text("ੴ")
                    .font(.system(size: 28))
                    .foregroundStyle(BaniTheme.amber)

                // Gurmukhi text
                Text(gurmukhi)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(BaniTheme.deepPlum)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)

                // Divider line
                Rectangle()
                    .fill(BaniTheme.amber.opacity(0.3))
                    .frame(width: 60, height: 2)

                // Translation
                Text(translation)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: 0x6B7280))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                // Source
                Text(baniName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BaniTheme.amber)
                    .textCase(.uppercase)
                    .tracking(1.5)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 36)

            // Footer
            HStack {
                Text("Bani")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(BaniTheme.amber)
                Spacer()
                Text("Understand what you recite")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: 0x9CA3AF))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color(hex: 0xFAF8F4))
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
        .frame(width: 340)
    }

    // Render the card to a UIImage for sharing
    @MainActor
    func renderImage() -> UIImage {
        let renderer = ImageRenderer(content:
            self
                .padding(20)
                .background(Color(hex: 0xF5F3EE))
        )
        renderer.scale = 3.0
        return renderer.uiImage ?? UIImage()
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
