import Foundation
import SwiftData
import SwiftUI

enum EnglishMode: String, CaseIterable {
    case off = "Off"
    case simple = "Simple"
    case scholar = "Scholar"
}

// Kept for backward compat with any remaining references
enum TranslationMode: String, CaseIterable {
    case simple = "Simple"
    case punjabi = "Punjabi"
    case scholar = "Scholar"
    case both = "Both"
}

// Flat item for the lazy list
enum ReadItem: Identifiable {
    case sectionHeader(id: String, title: String)
    case line(BaniLine)
    case divider(id: String)

    var id: String {
        switch self {
        case .sectionHeader(let id, _): id
        case .line(let line): "line-\(line.lineID)"
        case .divider(let id): id
        }
    }
}

@Observable
final class ReadViewModel {
    var items: [ReadItem] = []
    var selectedWord: WordEntry?
    var selectedRawWord: String?
    var selectedLineContext: String?
    var selectedSectionContext: String?
    var showWordSheet = false
    var totalLines = 0
    var readLines = 0
    var isWordInDeck = false
    var hasSimpleTranslations = false

    // New: two independent settings
    var englishMode: EnglishMode = .simple
    var showPunjabi: Bool = true

    // Legacy compat
    var translationMode: TranslationMode { .simple }

    var readProgress: Double {
        guard totalLines > 0 else { return 0 }
        return Double(readLines) / Double(totalLines)
    }

    var readPercentText: String {
        String(format: "%.0f%% read", readProgress * 100)
    }

    func loadPauris(baniID: Int, modelContext: ModelContext) {
        let descriptor = FetchDescriptor<BaniLine>(
            predicate: #Predicate { $0.baniID == baniID },
            sortBy: [SortDescriptor(\.lineID)]
        )
        guard let lines = try? modelContext.fetch(descriptor) else { return }

        totalLines = lines.count
        readLines = lines.filter(\.isRead).count
        hasSimpleTranslations = lines.contains { $0.simpleTranslation != nil }

        // Load settings
        let storedEnglish = UserDefaults.standard.string(forKey: "englishMode") ?? "Simple"
        englishMode = EnglishMode(rawValue: storedEnglish) ?? .simple
        showPunjabi = UserDefaults.standard.object(forKey: "showPunjabi") as? Bool ?? true

        // Flatten into a single list for LazyVStack
        var grouped: [Int: [BaniLine]] = [:]
        for line in lines {
            grouped[line.pauriNumber, default: []].append(line)
        }

        var flat: [ReadItem] = []
        let sortedKeys = grouped.keys.sorted()

        for (groupIdx, key) in sortedKeys.enumerated() {
            guard let sectionLines = grouped[key] else { continue }
            let title = sectionLines.first?.sectionTitle ?? ""

            if !title.isEmpty {
                if groupIdx > 0 { flat.append(.divider(id: "gap-\(key)")) }
                flat.append(.sectionHeader(id: "header-\(key)", title: title))
            } else if groupIdx > 0 {
                flat.append(.divider(id: "gap-\(key)"))
            }

            for (lineIdx, line) in sectionLines.enumerated() {
                flat.append(.line(line))
                if lineIdx < sectionLines.count - 1 {
                    flat.append(.divider(id: "div-\(line.lineID)"))
                }
            }
        }

        items = flat
    }

    func setEnglishMode(_ mode: EnglishMode) {
        englishMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "englishMode")
    }

    func setShowPunjabi(_ show: Bool) {
        showPunjabi = show
        UserDefaults.standard.set(show, forKey: "showPunjabi")
    }

    func tapWord(_ word: String, line: BaniLine) {
        let cleaned = word
            .replacingOccurrences(of: "।", with: "")
            .replacingOccurrences(of: "॥", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else { return }

        selectedRawWord = cleaned
        selectedWord = WordDictionary.lookup(cleaned)
        let linePreview = String(line.unicode.prefix(30))
        selectedLineContext = linePreview + (line.unicode.count > 30 ? "..." : "")
        selectedSectionContext = line.sectionTitle
        showWordSheet = true

        if !UserDefaults.standard.bool(forKey: "hasUsedWordTap") {
            UserDefaults.standard.set(true, forKey: "hasUsedWordTap")
        }
    }

    func markLineRead(_ line: BaniLine) {
        guard !line.isRead else { return }
        line.isRead = true
        readLines += 1
    }

    func checkWordInDeck(modelContext: ModelContext) {
        guard let entry = selectedWord else {
            isWordInDeck = false
            return
        }
        let gurmukhi = entry.gurmukhi
        let descriptor = FetchDescriptor<WordCard>(
            predicate: #Predicate { $0.gurmukhi == gurmukhi }
        )
        isWordInDeck = ((try? modelContext.fetchCount(descriptor)) ?? 0) > 0
    }

    func addToReviewDeck(modelContext: ModelContext) -> Bool {
        guard let entry = selectedWord else { return false }

        let gurmukhi = entry.gurmukhi
        let descriptor = FetchDescriptor<WordCard>(
            predicate: #Predicate { $0.gurmukhi == gurmukhi }
        )
        if let count = try? modelContext.fetchCount(descriptor), count > 0 {
            isWordInDeck = true
            return false
        }

        let card = WordCard(
            gurmukhi: entry.gurmukhi,
            transliteration: entry.transliteration,
            meaning: entry.meaning
        )
        modelContext.insert(card)
        isWordInDeck = true
        return true
    }
}
