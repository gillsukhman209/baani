import Foundation
import SwiftData

extension Notification.Name {
    static let simpleTranslationsReady = Notification.Name("simpleTranslationsReady")
    static let askAboutLine = Notification.Name("askAboutLine")
}

// Lightweight struct to pass data out of ModelContext
private struct LineData: Sendable {
    let lineID: Int
    let translation: String
    let unicode: String
}

actor TranslationService {
    static let shared = TranslationService()

    private let apiKey: String = {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["OPENAI_API_KEY"] as? String else {
            return ""
        }
        return key
    }()
    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let model = "gpt-4o-mini"

    private let systemPrompt = """
    You translate Gurbani lines for young Sikh diaspora users (18-35, Western countries).

    Return ONLY a JSON object with two keys, no other text:
    {"english": "...", "punjabi": "..."}

    For the "english" value:
    - Simple, modern English a friend would use
    - No theology words like "Personified", "Primal", "Undying", "Immaculate"
    - Use: "The Creator", "God", "always existed", "never dies" etc.
    - Keep it SHORT — same length as the original line
    - Just the translation, no explanations

    For the "punjabi" value:
    - Modern spoken Punjabi in Gurmukhi script
    - The kind of Punjabi a young person in Canada/UK would understand
    - Not the archaic Gurbani Punjabi — everyday conversational Punjabi
    - Keep it the same length as the English

    Examples:
    Input: "Creative Being Personified. No Fear. No Hatred."
    Output: {"english": "The Creator of everything. Without fear. Without hate.", "punjabi": "ਸਭ ਕੁਝ ਬਣਾਉਣ ਵਾਲਾ। ਬਿਨਾ ਡਰ। ਬਿਨਾ ਨਫ਼ਰਤ।"}

    Input: "True In The Primal Beginning. True Throughout The Ages."
    Output: {"english": "True since before time began. True through every era.", "punjabi": "ਸਮੇਂ ਤੋਂ ਪਹਿਲਾਂ ਤੋਂ ਸੱਚ। ਹਰ ਯੁੱਗ ਵਿੱਚ ਸੱਚ।"}
    """

    private var isRunning = false

    struct TranslationResult: Sendable {
        let english: String
        let punjabi: String
    }

    // MARK: - Translate a single line via OpenAI (returns both English + Punjabi)

    func translate(scholarTranslation: String, gurmukhi: String) async -> TranslationResult? {
        guard !apiKey.isEmpty else { return nil }
        guard !scholarTranslation.isEmpty else { return nil }

        let userMessage = "Translate this Gurbani line:\nEnglish (scholarly): \(scholarTranslation)\nGurmukhi: \(gurmukhi)"

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 250,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userMessage]
            ]
        ]

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return nil }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let choices = json?["choices"] as? [[String: Any]]
            let message = choices?.first?["message"] as? [String: Any]
            guard let text = message?["content"] as? String else { return nil }

            // Parse JSON response
            let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let jsonData = cleaned.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String],
                  let english = parsed["english"],
                  let punjabi = parsed["punjabi"] else {
                // Fallback: treat entire response as English only
                return TranslationResult(english: cleaned, punjabi: "")
            }

            return TranslationResult(english: english, punjabi: punjabi)
        } catch {
            return nil
        }
    }

    // MARK: - Background translation pipeline

    func translateBani(baniID: Int, container: ModelContainer) async {
        guard !apiKey.isEmpty else { return }

        // Create our own ModelContext on this actor's thread
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<BaniLine>(
            predicate: #Predicate { $0.baniID == baniID && $0.simpleTranslation == nil },
            sortBy: [SortDescriptor(\.lineID)]
        )
        guard let lines = try? context.fetch(descriptor), !lines.isEmpty else { return }

        // Extract data we need for API calls
        var lineDataList: [LineData] = []
        for line in lines {
            guard !line.translation.isEmpty else { continue }
            lineDataList.append(LineData(lineID: line.lineID, translation: line.translation, unicode: line.unicode))
        }

        // Process in batches of 10
        let batchSize = 10
        var translatedAny = false

        for batchStart in stride(from: 0, to: lineDataList.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, lineDataList.count)
            let batch = lineDataList[batchStart..<batchEnd]

            for lineData in batch {
                var result: TranslationResult?
                for _ in 0..<2 {
                    result = await translate(
                        scholarTranslation: lineData.translation,
                        gurmukhi: lineData.unicode
                    )
                    if result != nil { break }
                }

                if let translation = result {
                    let lineID = lineData.lineID
                    let fetchDescriptor = FetchDescriptor<BaniLine>(
                        predicate: #Predicate { $0.lineID == lineID }
                    )
                    if let line = try? context.fetch(fetchDescriptor).first {
                        line.simpleTranslation = translation.english
                        if !translation.punjabi.isEmpty {
                            line.punjabiTranslation = translation.punjabi
                        }
                        translatedAny = true
                    }
                }
            }

            try? context.save()

            // Notify UI that new translations are available
            if translatedAny {
                await MainActor.run {
                    NotificationCenter.default.post(name: .simpleTranslationsReady, object: baniID)
                }
            }

            if batchEnd < lineDataList.count {
                try? await Task.sleep(for: .milliseconds(500))
            }
        }

        // Final save and notify
        try? context.save()
        if translatedAny {
            await MainActor.run {
                NotificationCenter.default.post(name: .simpleTranslationsReady, object: baniID)
            }
        }
    }

    // MARK: - Translate all banis in priority order

    func translateAllBanis(container: ModelContainer) async {
        guard !apiKey.isEmpty else { return }
        guard !isRunning else { return }
        isRunning = true

        let context = ModelContext(container)
        let priorityIDs = [2, 21, 23, 9]
        let allIDs = BaniCatalog.all.map(\.id)
        let remainingIDs = allIDs.filter { !priorityIDs.contains($0) }
        let orderedIDs = priorityIDs + remainingIDs

        for baniID in orderedIDs {
            let checkDescriptor = FetchDescriptor<BaniLine>(
                predicate: #Predicate { $0.baniID == baniID }
            )
            guard let count = try? context.fetchCount(checkDescriptor), count > 0 else { continue }

            await translateBani(baniID: baniID, container: container)
        }

        isRunning = false
    }
}
