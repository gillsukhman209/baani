import Foundation
import SwiftData
import UIKit

@Observable
final class AskViewModel {
    var messages: [ConversationMessage] = []
    var inputText = ""
    var isTyping = false
    var showClearConfirmation = false

    private var streamingMessage: ConversationMessage?

    private let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let model = "gpt-4o-mini"

    private var apiKey: String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["OPENAI_API_KEY"] as? String else { return "" }
        return key
    }

    var suggestedQuestions: [String] {
        let pool = [
            "What is the message of Japji Sahib?",
            "What does ਹੁਕਮੁ (Hukam) mean?",
            "How do I start doing Nitnem daily?",
            "What did Guru Nanak teach about ego?",
            "Who wrote Sukhmani Sahib and why?",
            "What is the meaning of Ik Onkar?",
            "What is Haumai and why does it matter?",
            "How are the 10 Gurus connected?",
            "What does Gurbani say about grief?",
            "What is the difference between Seva and Simran?",
            "Why do Sikhs cover their head?",
            "What happened at the Battle of Chamkaur?",
            "What is Amrit Vela and why is it important?",
            "What does ਨਾਮੁ mean in Gurbani?",
            "How did Guru Gobind Singh create the Khalsa?",
            "What is the Mool Mantar and what does it mean?",
            "What does Gurbani say about death?",
            "How do I understand Gurbani if I don't know Punjabi?",
            "What is the significance of the Langar?",
            "What did Guru Tegh Bahadur sacrifice and why?",
        ]
        return Array(pool.shuffled().prefix(4))
    }

    private let systemPrompt = """
    You are Giani — a warm, deeply knowledgeable Sikh scholar and guide built into the Bani app. You help young Sikh diaspora users (ages 18-35, raised in Western countries like Canada, UK, and USA) understand and connect with Gurbani and Sikh history, philosophy, and practice.

    Your personality:
    - Warm, patient, and encouraging — like a knowledgeable older family member who wants you to genuinely connect with Sikhi
    - Never preachy, never lecturing
    - Honest when you don't know something
    - You speak simply and clearly — your users are smart but may have grown up disconnected from Punjabi and Gurbani
    - You use plain English. No theology textbook words.
    - Occasionally use Punjabi/Gurmukhi words naturally when they add meaning, but always explain them

    Your knowledge covers:
    - All of Sri Guru Granth Sahib Ji — every bani, every shabad, meanings, context, themes
    - The 10 Sikh Gurus — their lives, teachings, historical context
    - Sikh history — from Guru Nanak (1469) to present day
    - Sikh philosophy — concepts like Waheguru, Hukam, Naam, Seva, Simran, Haumai, Maya, Mukti
    - Nitnem and daily Sikh practice
    - Sikh ceremonies — Anand Karaj, Dastar, Amrit Sanchar, Antam Sanskar
    - Common questions diaspora Sikhs have about their faith
    - Punjabi language and Gurmukhi script

    How you answer:
    - For questions about specific Gurbani lines or words: explain the meaning in simple English, give historical/spiritual context, and connect it to everyday life
    - For philosophical questions: be thoughtful and grounded in actual Gurbani, not generic spirituality
    - For historical questions: be accurate and cite which Guru or period you're referencing
    - For personal/practical questions ("how do I start doing Nitnem"): be encouraging, practical, non-judgmental
    - When quoting Gurbani: include the Gurmukhi, romanized transliteration, and your simple English meaning
    - Keep answers focused — don't write an essay when a paragraph will do. Users are on mobile.
    - If asked something completely unrelated to Sikhi or Gurbani (like coding help or weather), politely redirect: "I'm here specifically to help with Gurbani and Sikhi — try asking me something related to that 🙏"

    Format guidelines for mobile:
    - Use **bold** sparingly for key terms
    - Use bullet points when listing multiple things
    - Keep paragraphs short (2-3 sentences max)
    - When including Gurmukhi text, put it on its own line
    - End responses with warmth, not formality
    """

    // MARK: - Load persisted messages

    func loadMessages(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<ConversationMessage>(
            sortBy: [SortDescriptor(\.timestamp)]
        )
        messages = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Send message

    func sendMessage(_ text: String? = nil, modelContext: ModelContext) {
        let content = text ?? inputText
        guard !content.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard !apiKey.isEmpty else {
            addError("API key not configured. Add your key to Secrets.plist.", modelContext: modelContext)
            return
        }

        // Add user message
        let userMsg = ConversationMessage(role: "user", content: content)
        modelContext.insert(userMsg)
        messages.append(userMsg)
        inputText = ""

        // Build context
        let userContext = buildUserContext(modelContext: modelContext)

        // Start streaming
        isTyping = true
        let aiMsg = ConversationMessage(role: "assistant", content: "")
        modelContext.insert(aiMsg)
        messages.append(aiMsg)
        streamingMessage = aiMsg

        Task {
            await streamResponse(userContext: userContext, modelContext: modelContext)
        }
    }

    // MARK: - Stream response

    private func streamResponse(userContext: String, modelContext: ModelContext) async {
        var apiMessages: [[String: String]] = [
            ["role": "system", "content": systemPrompt + "\n\n" + userContext]
        ]

        // Last 20 messages (excluding the empty AI message we just added)
        let history = messages.filter { $0.role == "user" || ($0.role == "assistant" && !$0.content.isEmpty) }
        let recentHistory = history.suffix(20)
        for msg in recentHistory {
            apiMessages.append(["role": msg.role, "content": msg.content])
        }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "stream": true,
            "messages": apiMessages
        ]

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                await handleError("Something went wrong. Try asking again.", modelContext: modelContext)
                return
            }

            if httpResponse.statusCode == 429 {
                await handleError("Taking a breath 🙏 Try again in a moment.", modelContext: modelContext)
                return
            }

            if httpResponse.statusCode != 200 {
                await handleError("Something went wrong. Try asking again.", modelContext: modelContext)
                return
            }

            var fullContent = ""

            for try await line in bytes.lines {
                guard line.hasPrefix("data: ") else { continue }
                let jsonStr = String(line.dropFirst(6))
                if jsonStr == "[DONE]" { break }

                guard let data = jsonStr.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let choices = json["choices"] as? [[String: Any]],
                      let delta = choices.first?["delta"] as? [String: Any],
                      let text = delta["content"] as? String else { continue }

                fullContent += text

                await MainActor.run {
                    streamingMessage?.content = fullContent
                }
            }

            await MainActor.run {
                isTyping = false
                streamingMessage = nil
                try? modelContext.save()
            }
        } catch {
            await handleError("Couldn't connect. Check your internet and try again.", modelContext: modelContext)
        }
    }

    // MARK: - Error handling

    private func handleError(_ message: String, modelContext: ModelContext) async {
        await MainActor.run {
            // Remove empty AI message
            if let streaming = streamingMessage {
                modelContext.delete(streaming)
                messages.removeAll { $0.id == streaming.id }
                streamingMessage = nil
            }
            addError(message, modelContext: modelContext)
            isTyping = false
        }
    }

    private func addError(_ message: String, modelContext: ModelContext) {
        let errorMsg = ConversationMessage(role: "error", content: message)
        modelContext.insert(errorMsg)
        messages.append(errorMsg)
    }

    // MARK: - Clear conversation

    func clearConversation(modelContext: ModelContext) {
        for msg in messages {
            modelContext.delete(msg)
        }
        messages.removeAll()
        try? modelContext.save()
    }

    // MARK: - Build user context

    private func buildUserContext(modelContext: ModelContext) -> String {
        var context = "Current user context:\n"

        // Banis read
        let baniDescriptor = FetchDescriptor<Bani>(
            predicate: #Predicate { $0.isFetched == true },
            sortBy: [SortDescriptor(\.displayOrder)]
        )
        let banis = (try? modelContext.fetch(baniDescriptor)) ?? []
        if !banis.isEmpty {
            context += "- Banis they've opened: \(banis.map(\.name).joined(separator: ", "))\n"
        }

        // Words in deck
        let wordDescriptor = FetchDescriptor<WordCard>()
        let words = (try? modelContext.fetch(wordDescriptor)) ?? []
        if !words.isEmpty {
            let wordList = words.prefix(15).map(\.gurmukhi).joined(separator: ", ")
            context += "- Words in their learning deck: \(wordList)\n"
        }

        // Streak
        let sessionDescriptor = FetchDescriptor<AppSession>()
        let sessions = (try? modelContext.fetch(sessionDescriptor)) ?? []
        context += "- App sessions: \(sessions.count) days total\n"

        return context
    }
}
