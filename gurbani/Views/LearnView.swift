import SwiftUI
import SwiftData

struct LearnView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hapticFeedback") private var hapticEnabled = true
    @State private var viewModel = LearnViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let card = viewModel.currentCard {
                    // Progress text
                    Text("Card \(viewModel.currentIndex + 1) of \(viewModel.dueCards.count)")
                        .font(.system(size: 13))
                        .foregroundStyle(BaniTheme.secondaryText)
                        .padding(.top, 16)

                    // Stats bar
                    HStack(spacing: 24) {
                        StatPill(label: "Learned", value: "\(viewModel.totalLearned)", icon: "checkmark.circle")
                        StatPill(label: "Due", value: "\(viewModel.totalDue)", icon: "clock")
                    }
                    .padding(.top, 12)

                    Spacer()

                    FlashcardView(
                        card: card,
                        isFlipped: viewModel.isFlipped,
                        hapticEnabled: hapticEnabled,
                        onFlip: { viewModel.flipCard(haptic: hapticEnabled) },
                        onGotIt: { viewModel.markGotIt(haptic: hapticEnabled) },
                        onAgain: { viewModel.markAgain(haptic: hapticEnabled) }
                    )

                    Spacer()

                } else if viewModel.hasCards && viewModel.currentIndex >= viewModel.dueCards.count {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 48))
                            .foregroundStyle(BaniTheme.saffron)
                        Text("All caught up!")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("You've reviewed all due cards.\nCome back later for more.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(BaniTheme.secondaryText)
                    }
                    Spacer()

                } else {
                    // Empty state — no cards
                    Spacer()
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(BaniTheme.saffron.opacity(0.1))
                                .frame(width: 120, height: 120)
                            Text("ੴ")
                                .font(.system(size: 48))
                                .foregroundStyle(BaniTheme.saffron)
                        }

                        Text("Your journey begins in the Read tab")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)

                        Text("Tap any Gurmukhi word to save it\nhere for daily review")
                            .font(.system(size: 15))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(BaniTheme.secondaryText)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, BaniTheme.screenPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(BaniTheme.background.ignoresSafeArea())
            .navigationTitle("Learn")
            .toolbarBackground(BaniTheme.background, for: .navigationBar)
            .onAppear { viewModel.loadCards(modelContext: modelContext) }
        }
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(BaniTheme.saffron)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(BaniTheme.secondaryText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(BaniTheme.cardBackground)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

// MARK: - Flashcard

struct FlashcardView: View {
    let card: WordCard
    let isFlipped: Bool
    let hapticEnabled: Bool
    let onFlip: () -> Void
    let onGotIt: () -> Void
    let onAgain: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                if !isFlipped {
                    // Front — navy card
                    VStack(spacing: 12) {
                        Spacer()
                        Text(card.gurmukhi)
                            .font(.system(size: 52, weight: .bold))
                            .foregroundStyle(.white)
                        Text(card.transliteration)
                            .font(.system(size: 16))
                            .italic()
                            .foregroundStyle(BaniTheme.saffron)
                        Spacer()
                        Text("Tap to reveal meaning")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.4))
                            .padding(.bottom, 16)
                    }
                } else {
                    // Back — navy card with meaning
                    VStack(spacing: 12) {
                        Spacer()
                        Text(card.gurmukhi)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                        Text(card.meaning)
                            .font(.system(size: 24))
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .background(BaniTheme.navy)
            .clipShape(RoundedRectangle(cornerRadius: BaniTheme.cornerRadius))
            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
            .onTapGesture {
                if !isFlipped {
                    withAnimation(.easeInOut(duration: 0.3)) { onFlip() }
                }
            }

            // Buttons
            if isFlipped {
                HStack(spacing: 16) {
                    Button {
                        withAnimation { onAgain() }
                    } label: {
                        Text("Again")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.5), lineWidth: 1.5)
                    )

                    Button {
                        withAnimation { onGotIt() }
                    } label: {
                        Text("Got it")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(BaniTheme.navy)
                    }
                    .background(BaniTheme.saffron)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}
