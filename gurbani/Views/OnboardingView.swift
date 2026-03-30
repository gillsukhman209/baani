import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var selectedBani: Int = 2 // Default to Japji Sahib
    let onComplete: (Int) -> Void

    private let preferredBanis: [(id: Int, name: String)] = [
        (2,  "Japji Sahib"),
        (21, "Rehras Sahib"),
        (23, "Kirtan Sohila"),
        (9,  "Chaupai Sahib"),
        (31, "Sukhmani Sahib"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                page1.tag(0)
                page2.tag(1)
                page3.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i == currentPage ? BaniTheme.saffron : BaniTheme.trackGrey)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 24)

            // Button
            Button {
                if currentPage < 2 {
                    withAnimation { currentPage += 1 }
                } else {
                    UserDefaults.standard.set(true, forKey: "hasOnboarded")
                    UserDefaults.standard.set(selectedBani, forKey: "preferredBani")
                    onComplete(selectedBani)
                }
            } label: {
                Text(currentPage < 2 ? "Continue" : "Begin")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(BaniTheme.saffron)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .background(BaniTheme.background)
    }

    // MARK: - Page 1

    private var page1: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("ੴ")
                .font(.system(size: 72))
                .foregroundStyle(BaniTheme.saffron)

            Text("Finally understand\nwhat you recite")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(BaniTheme.gurmukhiColor)

            Text("Bani helps you discover the meaning behind every word of Gurbani — one tap at a time.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(BaniTheme.secondaryText)
                .padding(.horizontal, 40)
            Spacer()
            Spacer()
        }
    }

    // MARK: - Page 2

    private var page2: some View {
        VStack(spacing: 24) {
            Spacer()

            // Mock tappable word illustration
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text("ਸਤਿ")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(BaniTheme.gurmukhiColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(BaniTheme.saffron.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Text("ਨਾਮੁ")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(BaniTheme.gurmukhiColor)
                    Text("ਕਰਤਾ")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(BaniTheme.gurmukhiColor)
                }

                // Meaning bubble
                VStack(spacing: 4) {
                    Text("sat")
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(BaniTheme.secondaryText)
                    Text("True; truth; existence")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(BaniTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            }

            Text("Tap any word")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(BaniTheme.gurmukhiColor)

            Text("Every Gurmukhi word in every bani is tappable. See its meaning, transliteration, and save it to your review deck.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(BaniTheme.secondaryText)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Page 3

    private var page3: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Which bani do you\nrecite daily?")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(BaniTheme.gurmukhiColor)

            VStack(spacing: 10) {
                ForEach(preferredBanis, id: \.id) { bani in
                    Button {
                        selectedBani = bani.id
                    } label: {
                        HStack {
                            Text(bani.name)
                                .font(.body)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: selectedBani == bani.id ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(selectedBani == bani.id ? BaniTheme.saffron : BaniTheme.secondaryText)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(BaniTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 32)

            Text("We'll start you here. You can explore\nall banis anytime.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(BaniTheme.secondaryText)

            Spacer()
            Spacer()
        }
    }
}
