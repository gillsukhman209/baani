import Foundation

struct WordEntry: Sendable {
    let gurmukhi: String
    let transliteration: String
    let meaning: String
}

enum WordDictionary {
    static let entries: [String: WordEntry] = {
        let words: [WordEntry] = [
            WordEntry(gurmukhi: "ਸਤਿ", transliteration: "sat", meaning: "Truth — what is real and always true"),
            WordEntry(gurmukhi: "ਨਾਮੁ", transliteration: "naam", meaning: "God's name — the way we connect to the Divine"),
            WordEntry(gurmukhi: "ਕਰਤਾ", transliteration: "kartaa", meaning: "The Creator — the one who made everything"),
            WordEntry(gurmukhi: "ਪੁਰਖੁ", transliteration: "purakh", meaning: "The Supreme Being — present in all of creation"),
            WordEntry(gurmukhi: "ਨਿਰਭਉ", transliteration: "nirbhau", meaning: "Completely fearless, afraid of nothing at all"),
            WordEntry(gurmukhi: "ਨਿਰਵੈਰੁ", transliteration: "nirvair", meaning: "Without hate — holds no grudge against anyone"),
            WordEntry(gurmukhi: "ਅਕਾਲ", transliteration: "akaal", meaning: "Exists outside of time, never-ending"),
            WordEntry(gurmukhi: "ਮੂਰਤਿ", transliteration: "moorat", meaning: "Form — God's presence that we can experience"),
            WordEntry(gurmukhi: "ਅਜੂਨੀ", transliteration: "ajoonee", meaning: "Never born, never dies — beyond the cycle of life and death"),
            WordEntry(gurmukhi: "ਸੈਭੰ", transliteration: "saibhan", meaning: "Self-created — exists on its own, needs nothing"),
            WordEntry(gurmukhi: "ਗੁਰਪ੍ਰਸਾਦਿ", transliteration: "gurprasaad", meaning: "Only through the Guru's blessing and kindness"),
            WordEntry(gurmukhi: "ਆਦਿ", transliteration: "aad", meaning: "Since the very beginning — before anything existed"),
            WordEntry(gurmukhi: "ਜੁਗਾਦਿ", transliteration: "jugaad", meaning: "Through every age and era of time"),
            WordEntry(gurmukhi: "ਹੋਸੀ", transliteration: "hosee", meaning: "Will always be true — forever into the future"),
            WordEntry(gurmukhi: "ਸੋਚੈ", transliteration: "sochai", meaning: "By thinking — even endless thinking can't reach God"),
            WordEntry(gurmukhi: "ਚੁਪੈ", transliteration: "chupai", meaning: "By staying silent — even complete silence won't do it"),
            WordEntry(gurmukhi: "ਭੁਖਿਆ", transliteration: "bhukhiaa", meaning: "The hungry ones — those who are still wanting"),
            WordEntry(gurmukhi: "ਭੁਖ", transliteration: "bhukh", meaning: "Hunger — deep craving or longing"),
            WordEntry(gurmukhi: "ਸਚੁ", transliteration: "sach", meaning: "Truth — the ultimate reality, God"),
            WordEntry(gurmukhi: "ਹੁਕਮਿ", transliteration: "hukam", meaning: "God's will — the divine command that runs everything"),
            WordEntry(gurmukhi: "ਹੁਕਮੀ", transliteration: "hukmee", meaning: "Under God's command — everything follows this order"),
            WordEntry(gurmukhi: "ਗੁਰੂ", transliteration: "guroo", meaning: "The Guru — the teacher who brings us from darkness to light"),
            WordEntry(gurmukhi: "ਵਾਹਿਗੁਰੂ", transliteration: "vaahiguroo", meaning: "Waheguru — wonderful God, our word for the Divine"),
            WordEntry(gurmukhi: "ਜਪੁ", transliteration: "jap", meaning: "Reciting with focus — meditating on God's name"),
            WordEntry(gurmukhi: "ਸਾਹਿਬੁ", transliteration: "saahib", meaning: "Master, Lord — the one in charge of everything"),
            WordEntry(gurmukhi: "ਨਾਨਕ", transliteration: "naanak", meaning: "Guru Nanak — the founder of Sikhi, the first Guru"),
            WordEntry(gurmukhi: "ਸਭ", transliteration: "sabh", meaning: "All — everyone, everything, the whole creation"),
            WordEntry(gurmukhi: "ਮੰਨੈ", transliteration: "mannai", meaning: "By truly believing — when you accept it in your heart"),
            WordEntry(gurmukhi: "ਸੁਣਿਐ", transliteration: "suniai", meaning: "By truly listening — when you hear with your whole being"),
            WordEntry(gurmukhi: "ਪਵਣੁ", transliteration: "pavan", meaning: "The wind, the air — the breath that gives us life"),
        ]
        var dict: [String: WordEntry] = [:]
        for word in words {
            dict[word.gurmukhi] = word
        }
        return dict
    }()

    static func lookup(_ word: String) -> WordEntry? {
        if let entry = entries[word] {
            return entry
        }
        let cleaned = word
            .replacingOccurrences(of: "।", with: "")
            .replacingOccurrences(of: "॥", with: "")
            .trimmingCharacters(in: .whitespaces)
        return entries[cleaned]
    }
}
