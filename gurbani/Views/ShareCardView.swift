import SwiftUI
import UIKit

struct ShareCardView: View {
    let gurmukhi: String
    let translation: String
    let punjabiTranslation: String?
    let baniName: String

    var body: some View {
        VStack(spacing: 0) {
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

                // Punjabi translation (if included)
                if let punjabi = punjabiTranslation, !punjabi.isEmpty {
                    Text(punjabi)
                        .font(.system(size: 17))
                        .foregroundStyle(Color(hex: 0x5A4E44))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                // English translation
                Text(translation)
                    .font(.system(size: 15))
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

            // Single footer line
            Text("Simple Gurbani App")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: 0xD4943A))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: 0xFDF2E3))
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .frame(width: 340)
    }

    @MainActor
    func renderImage() -> UIImage {
        let renderer = ImageRenderer(content:
            self
                .padding(24)
                .background(Color(hex: 0xFFF8EF))
        )
        renderer.scale = 2.0
        return renderer.uiImage ?? UIImage()
    }
}

func shareViaUIKit(image: UIImage) {
    let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)

    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let rootVC = windowScene.windows.first?.rootViewController else { return }

    var topVC = rootVC
    while let presented = topVC.presentedViewController {
        topVC = presented
    }

    activityVC.popoverPresentationController?.sourceView = topVC.view
    topVC.present(activityVC, animated: true)
}
