import SwiftUI

struct ShareCardView: View {
    let gurmukhi: String
    let translation: String
    let baniName: String

    var body: some View {
        VStack(spacing: 0) {
            // Top warm gradient bar
            BaniTheme.goldGradient
                .frame(height: 6)

            VStack(spacing: 24) {
                Text("ੴ")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(hex: 0xD4943A))

                Text(gurmukhi)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color(hex: 0x2C1810))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)

                Rectangle()
                    .fill(Color(hex: 0xD4943A).opacity(0.3))
                    .frame(width: 60, height: 2)

                Text(translation)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: 0x8B7E74))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text(baniName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: 0xD4943A))
                    .textCase(.uppercase)
                    .tracking(1.5)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 36)

            HStack {
                Text("Bani")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: 0xD4943A))
                Spacer()
                Text("Understand what you recite")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: 0x8B7E74))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color(hex: 0xFDF2E3))
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color(hex: 0xC9B99A).opacity(0.2), radius: 16, y: 8)
        .frame(width: 340)
    }

    @MainActor
    func renderImage() -> UIImage {
        let renderer = ImageRenderer(content:
            self
                .padding(24)
                .background(Color(hex: 0xFFF8EF))
        )
        renderer.scale = 3.0
        return renderer.uiImage ?? UIImage()
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
