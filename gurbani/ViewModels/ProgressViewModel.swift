import Foundation
import SwiftData

struct BaniProgress: Identifiable {
    let id: Int
    let name: String
    let linesRead: Int
    let totalLines: Int
    var percentage: Double {
        guard totalLines > 0 else { return 0 }
        return Double(linesRead) / Double(totalLines)
    }
}

@Observable
final class ProgressViewModel {
    var currentStreak = 0
    var totalWordsLearned = 0
    var totalLinesRead = 0
    var totalLines = 0
    var sessionDates: Set<String> = []
    var baniProgressList: [BaniProgress] = []

    var percentageRead: Double {
        guard totalLines > 0 else { return 0 }
        return Double(totalLinesRead) / Double(totalLines) * 100
    }

    var streakMotivation: String {
        switch currentStreak {
        case 0: "Open the app daily to build your streak"
        case 1...6: "Keep going — consistency is seva"
        case 7...29: "One week strong. Waheguru is watching"
        default: "\(currentStreak) days of daily practice. You are becoming the bani."
        }
    }

    func load(modelContext: ModelContext) {
        recordSession(modelContext: modelContext)

        let sessionDescriptor = FetchDescriptor<AppSession>()
        let sessions = (try? modelContext.fetch(sessionDescriptor)) ?? []
        sessionDates = Set(sessions.map(\.dateString))
        currentStreak = calculateStreak(from: sessions)

        let wordDescriptor = FetchDescriptor<WordCard>()
        let words = (try? modelContext.fetch(wordDescriptor)) ?? []
        totalWordsLearned = words.filter { $0.timesCorrect > 0 }.count

        let lineDescriptor = FetchDescriptor<BaniLine>()
        let lines = (try? modelContext.fetch(lineDescriptor)) ?? []
        totalLines = lines.count
        totalLinesRead = lines.filter(\.isRead).count

        // Per-bani progress
        let baniDescriptor = FetchDescriptor<Bani>(sortBy: [SortDescriptor(\.displayOrder)])
        let banis = (try? modelContext.fetch(baniDescriptor)) ?? []

        var progressList: [BaniProgress] = []
        for bani in banis {
            let baniID = bani.baniID
            let baniLines = lines.filter { $0.baniID == baniID }
            let readCount = baniLines.filter(\.isRead).count
            if !baniLines.isEmpty && readCount > 0 {
                progressList.append(BaniProgress(
                    id: bani.baniID,
                    name: bani.name,
                    linesRead: readCount,
                    totalLines: baniLines.count
                ))
            }
        }
        baniProgressList = progressList
    }

    private func recordSession(modelContext: ModelContext) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: .now)

        let descriptor = FetchDescriptor<AppSession>(
            predicate: #Predicate { $0.dateString == todayString }
        )
        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty {
            return
        }
        modelContext.insert(AppSession())
    }

    private func calculateStreak(from sessions: [AppSession]) -> Int {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let dates = Set(sessions.map(\.dateString))
        var streak = 0
        var checkDate = Date.now

        while true {
            let dateStr = formatter.string(from: checkDate)
            if dates.contains(dateStr) {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else {
                break
            }
        }
        return streak
    }
}
