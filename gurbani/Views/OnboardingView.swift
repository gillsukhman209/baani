import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var selectedBani: Int = 2
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

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .fill(i == currentPage ? BaniTheme.accentColor : BaniTheme.trackColor)
                        .frame(width: i == currentPage ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            .padding(.bottom, 28)

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
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(BaniTheme.goldGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .background(BaniTheme.background.ignoresSafeArea())
    }

    private var page1: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(BaniTheme.accentColor.opacity(0.1))
                    .frame(width: 130, height: 130)
                Text("ੴ")
                    .font(.system(size: 64))
                    .foregroundStyle(BaniTheme.accentColor)
            }

            Text("Finally understand\nwhat you recite")
                .font(.system(size: 30, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(BaniTheme.gurmukhiColor)

            Text("Simple Gurbani helps you discover the meaning\nbehind every word — one tap at a time.")
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundStyle(BaniTheme.textSecondary)
                .padding(.horizontal, 36)
            Spacer()
            Spacer()
        }
    }

    private var page2: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 14) {
                HStack(spacing: 8) {
                    Text("ਸਤਿ")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(BaniTheme.gurmukhiColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(BaniTheme.accentColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Text("ਨਾਮੁ")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(BaniTheme.gurmukhiColor)
                    Text("ਕਰਤਾ")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(BaniTheme.gurmukhiColor)
                }

                VStack(spacing: 4) {
                    Text("sat")
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(BaniTheme.textSecondary)
                    Text("Truth — what is real and always true")
                        .font(.subheadline)
                        .foregroundStyle(BaniTheme.gurmukhiColor)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(BaniTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color(hex: 0xC9B99A).opacity(0.2), radius: 10, y: 5)
            }

            Text("Tap any word")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(BaniTheme.gurmukhiColor)

            Text("Every Gurmukhi word is tappable.\nSee its meaning instantly.")
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundStyle(BaniTheme.textSecondary)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }

    private var page3: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Which bani do you\nrecite daily?")
                .font(.system(size: 30, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(BaniTheme.gurmukhiColor)

            VStack(spacing: 10) {
                ForEach(preferredBanis, id: \.id) { bani in
                    Button {
                        selectedBani = bani.id
                    } label: {
                        HStack {
                            Text(bani.name)
                                .font(.system(size: 16))
                                .foregroundStyle(BaniTheme.gurmukhiColor)
                            Spacer()
                            Image(systemName: selectedBani == bani.id ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(selectedBani == bani.id ? BaniTheme.accentColor : BaniTheme.textSecondary)
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
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundStyle(BaniTheme.textSecondary)

            Spacer()
            Spacer()
        }
    }
}
