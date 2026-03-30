import SwiftUI

struct WordDetailSheet: View {
    let word: WordEntry?
    let rawWord: String
    let sectionContext: String
    let lineContext: String
    let isInDeck: Bool
    let onAddToReview: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Context line
            if !sectionContext.isEmpty || !lineContext.isEmpty {
                HStack(spacing: 4) {
                    if !sectionContext.isEmpty {
                        Text("from \(sectionContext)")
                    }
                    if !sectionContext.isEmpty && !lineContext.isEmpty {
                        Text("·")
                    }
                    if !lineContext.isEmpty {
                        Text(lineContext)
                            .lineLimit(1)
                    }
                }
                .font(.system(size: 12))
                .foregroundStyle(BaniTheme.secondaryText)
                .padding(.top, 20)
                .padding(.horizontal, BaniTheme.screenPadding)
            }

            // Large Gurmukhi word
            Text(word?.gurmukhi ?? rawWord)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(BaniTheme.gurmukhiColor)
                .padding(.top, 24)

            if let word {
                // Transliteration
                Text(word.transliteration)
                    .font(.system(size: 18))
                    .italic()
                    .foregroundStyle(BaniTheme.secondaryText)
                    .padding(.top, 8)

                // Meaning
                Text(word.meaning)
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .padding(.top, 8)
                    .padding(.horizontal, 32)

                // Divider
                Rectangle()
                    .fill(BaniTheme.divider)
                    .frame(height: 0.5)
                    .padding(.horizontal, 32)
                    .padding(.top, 24)

                // Deck status
                if isInDeck {
                    Label("Added to deck", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(BaniTheme.saffron)
                        .padding(.top, 20)
                } else {
                    Button {
                        onAddToReview()
                    } label: {
                        Label("Add to Review Deck", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BaniTheme.saffron)
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.title)
                        .foregroundStyle(.quaternary)
                    Text("Meaning coming soon")
                        .font(.subheadline)
                        .foregroundStyle(BaniTheme.secondaryText)
                }
                .padding(.top, 24)
            }

            Spacer()
        }
    }
}
