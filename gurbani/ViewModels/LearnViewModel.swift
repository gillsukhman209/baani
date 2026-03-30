import Foundation
import SwiftData
import UIKit

@Observable
final class LearnViewModel {
    var dueCards: [WordCard] = []
    var currentIndex = 0
    var isFlipped = false
    var totalLearned = 0
    var totalDue = 0

    var currentCard: WordCard? {
        guard currentIndex < dueCards.count else { return nil }
        return dueCards[currentIndex]
    }

    var hasCards: Bool {
        !dueCards.isEmpty
    }

    func loadCards(modelContext: ModelContext) {
        let now = Date.now
        let allDescriptor = FetchDescriptor<WordCard>()
        let allCards = (try? modelContext.fetch(allDescriptor)) ?? []

        totalLearned = allCards.filter { $0.timesCorrect > 0 }.count

        dueCards = allCards.filter { $0.nextReviewDate <= now }
        totalDue = dueCards.count
        currentIndex = 0
        isFlipped = false
    }

    func flipCard(haptic: Bool) {
        isFlipped = true
        if haptic { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    }

    func markGotIt(haptic: Bool) {
        guard let card = currentCard else { return }
        card.markCorrect()
        if haptic { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        advance()
    }

    func markAgain(haptic: Bool) {
        guard let card = currentCard else { return }
        card.markAgain()
        dueCards.append(card)
        if haptic { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
        advance()
    }

    private func advance() {
        currentIndex += 1
        isFlipped = false
    }
}
