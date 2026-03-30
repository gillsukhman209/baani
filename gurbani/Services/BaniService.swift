import Foundation
import SwiftData

// MARK: - Bundled JSON line structure

struct BundledLine: Codable {
    let verseId: Int
    let baniID: Int
    let lineNo: Int
    let gurmukhi: String
    let unicode: String
    let transliteration: String
    let translation: String
    let pauriNumber: Int
    let sectionTitle: String
    let simpleTranslation: String?
    let punjabiTranslation: String?
}

// MARK: - API Response (fallback only)

struct BaniAPIResponse: Codable, Sendable {
    let verses: [BaniVerse]
}

struct BaniVerse: Codable, Sendable {
    let header: Int
    let paragraph: Int?
    let verse: VerseDetail
}

struct VerseDetail: Codable, Sendable {
    let verseId: Int
    let verse: VerseText
    let translation: Translation?
    let transliteration: Transliteration?
    let lineNo: Int?
    let pageNo: Int?
}

struct VerseText: Codable, Sendable {
    let gurmukhi: String
    let unicode: String
}

struct Translation: Codable, Sendable {
    let en: EnglishTranslation?
}

struct EnglishTranslation: Codable, Sendable {
    let bdb: String?
    let spiegel: String?
    let ms: String?
}

struct Transliteration: Codable, Sendable {
    let english: String?
    let en: String?
}

// MARK: - BaniService

@Observable
final class BaniService {
    var isLoading = false
    var errorMessage: String?
    var isFetchingBani = false

    private let baseURL = "https://api.banidb.com/v2"

    // Cached bundled data — loaded once from JSON
    private var bundledLines: [Int: [BundledLine]]?

    // MARK: - Load bundled JSON

    private func loadBundledData() -> [Int: [BundledLine]] {
        if let cached = bundledLines { return cached }

        guard let url = Bundle.main.url(forResource: "BundledTranslations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let lines = try? JSONDecoder().decode([BundledLine].self, from: data) else {
            return [:]
        }

        var grouped: [Int: [BundledLine]] = [:]
        for line in lines {
            grouped[line.baniID, default: []].append(line)
        }
        bundledLines = grouped
        return grouped
    }

    // MARK: - Seed Curated Bani List

    func seedBaniList(modelContext: ModelContext) {
        let catalogVersionKey = "baniCatalogVersion"
        let storedVersion = UserDefaults.standard.integer(forKey: catalogVersionKey)

        if storedVersion == BaniCatalog.version {
            let descriptor = FetchDescriptor<Bani>()
            if let count = try? modelContext.fetchCount(descriptor), count == BaniCatalog.all.count {
                return
            }
        }

        let descriptor = FetchDescriptor<Bani>()
        if let existing = try? modelContext.fetch(descriptor) {
            for bani in existing {
                if !BaniCatalog.allowedIDs.contains(bani.baniID) {
                    let baniID = bani.baniID
                    let lineDescriptor = FetchDescriptor<BaniLine>(
                        predicate: #Predicate { $0.baniID == baniID }
                    )
                    if let lines = try? modelContext.fetch(lineDescriptor) {
                        for line in lines { modelContext.delete(line) }
                    }
                }
                modelContext.delete(bani)
            }
        }

        for (index, entry) in BaniCatalog.all.enumerated() {
            let bani = Bani(
                baniID: entry.id,
                name: entry.name,
                gurmukhi: entry.gurmukhi,
                unicode: entry.unicode,
                transliteration: entry.transliteration,
                timeOfDay: entry.time,
                durationMinutes: entry.duration,
                baniDescription: entry.description,
                displayOrder: index,
                author: entry.author
            )
            modelContext.insert(bani)
        }

        try? modelContext.save()
        UserDefaults.standard.set(BaniCatalog.version, forKey: catalogVersionKey)
    }

    // MARK: - Load Bani (from bundled JSON, fallback to API)

    func fetchBani(id baniID: Int, modelContext: ModelContext) async {
        // Already cached in SwiftData?
        let checkDescriptor = FetchDescriptor<BaniLine>(
            predicate: #Predicate { $0.baniID == baniID }
        )
        if let count = try? modelContext.fetchCount(checkDescriptor), count > 0 {
            markBaniFetched(baniID: baniID, modelContext: modelContext)
            return
        }

        isFetchingBani = true

        // Try bundled JSON first (instant, no network)
        let bundled = loadBundledData()
        if let lines = bundled[baniID], !lines.isEmpty {
            for bundledLine in lines {
                let compositeID = baniID * 100000 + bundledLine.verseId
                let line = BaniLine(
                    lineID: compositeID,
                    baniID: baniID,
                    lineNo: bundledLine.lineNo,
                    gurmukhi: bundledLine.gurmukhi,
                    unicode: bundledLine.unicode,
                    transliteration: bundledLine.transliteration,
                    translation: bundledLine.translation,
                    pauriNumber: bundledLine.pauriNumber,
                    sectionTitle: bundledLine.sectionTitle,
                    simpleTranslation: bundledLine.simpleTranslation,
                    punjabiTranslation: bundledLine.punjabiTranslation
                )
                modelContext.insert(line)
            }
            try? modelContext.save()
            markBaniFetched(baniID: baniID, modelContext: modelContext)
            isFetchingBani = false
            return
        }

        // Fallback: fetch from BaniDB API (only if bundled data missing)
        do {
            let url = URL(string: "\(baseURL)/banis/\(baniID)")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(BaniAPIResponse.self, from: data)

            var sectionNumber = 0
            var lastParagraph: Int?
            var contentPauriCount = 0
            var headerCount = 0

            for verse in response.verses {
                let paragraph = verse.paragraph ?? 0

                if paragraph != lastParagraph {
                    sectionNumber += 1
                    lastParagraph = paragraph
                    if verse.header == 1 {
                        headerCount += 1
                    } else {
                        contentPauriCount += 1
                    }
                }

                let title: String
                if verse.header == 1 {
                    title = headerCount == 1 ? "Salutation" : ""
                } else {
                    title = "Pauri \(contentPauriCount)"
                }

                let compositeID = baniID * 100000 + verse.verse.verseId

                let line = BaniLine(
                    lineID: compositeID,
                    baniID: baniID,
                    lineNo: verse.verse.lineNo ?? 0,
                    gurmukhi: verse.verse.verse.gurmukhi,
                    unicode: verse.verse.verse.unicode,
                    transliteration: verse.verse.transliteration?.en
                        ?? verse.verse.transliteration?.english
                        ?? "",
                    translation: verse.verse.translation?.en?.bdb ?? "",
                    pauriNumber: sectionNumber,
                    sectionTitle: title
                )
                modelContext.insert(line)
            }

            try modelContext.save()
            markBaniFetched(baniID: baniID, modelContext: modelContext)
            isFetchingBani = false
        } catch {
            isFetchingBani = false
        }
    }

    private func markBaniFetched(baniID: Int, modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Bani>(
            predicate: #Predicate { $0.baniID == baniID }
        )
        if let bani = try? modelContext.fetch(descriptor).first {
            bani.isFetched = true
        }
    }
}
