import Foundation
import SwiftData

@Model
final class WordCard {
    @Attribute(.unique) var gurmukhi: String
    var transliteration: String
    var meaning: String
    var interval: Int
    var nextReviewDate: Date
    var timesCorrect: Int
    var timesSeen: Int

    init(
        gurmukhi: String,
        transliteration: String,
        meaning: String,
        interval: Int = 1,
        nextReviewDate: Date = .now,
        timesCorrect: Int = 0,
        timesSeen: Int = 0
    ) {
        self.gurmukhi = gurmukhi
        self.transliteration = transliteration
        self.meaning = meaning
        self.interval = interval
        self.nextReviewDate = nextReviewDate
        self.timesCorrect = timesCorrect
        self.timesSeen = timesSeen
    }

    func markCorrect() {
        timesCorrect += 1
        timesSeen += 1
        // Progression: 1 → 3 → 7 → 14 → 30
        switch interval {
        case 1: interval = 3
        case 3: interval = 7
        case 7: interval = 14
        case 14: interval = 30
        default: break
        }
        nextReviewDate = Calendar.current.date(byAdding: .day, value: interval, to: .now) ?? .now
    }

    func markAgain() {
        timesSeen += 1
        interval = 1
        nextReviewDate = .now
    }
}
