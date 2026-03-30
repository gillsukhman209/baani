import Foundation
import SwiftData

enum TimeOfDay: String, Codable, CaseIterable {
    case morning = "Morning Prayers"
    case evening = "Evening Prayer"
    case night = "Night Prayer"

    var sortOrder: Int {
        switch self {
        case .morning: 0
        case .evening: 1
        case .night: 2
        }
    }

    var icon: String {
        switch self {
        case .morning: "sunrise"
        case .evening: "sunset"
        case .night: "moon.stars"
        }
    }
}

@Model
final class Bani {
    @Attribute(.unique) var baniID: Int
    var name: String
    var gurmukhi: String
    var unicode: String
    var transliteration: String
    var timeOfDay: String
    var durationMinutes: Int
    var baniDescription: String
    var displayOrder: Int
    var isFetched: Bool
    var author: String

    init(
        baniID: Int,
        name: String,
        gurmukhi: String,
        unicode: String,
        transliteration: String,
        timeOfDay: TimeOfDay,
        durationMinutes: Int,
        baniDescription: String,
        displayOrder: Int,
        author: String = "",
        isFetched: Bool = false
    ) {
        self.baniID = baniID
        self.name = name
        self.gurmukhi = gurmukhi
        self.unicode = unicode
        self.transliteration = transliteration
        self.timeOfDay = timeOfDay.rawValue
        self.durationMinutes = durationMinutes
        self.baniDescription = baniDescription
        self.displayOrder = displayOrder
        self.author = author
        self.isFetched = isFetched
    }

    var time: TimeOfDay {
        TimeOfDay(rawValue: timeOfDay) ?? .morning
    }
}

enum BaniCatalog {
    // Bump this when catalog data changes to force re-seed
    static let version = 3

    static let all: [(id: Int, name: String, gurmukhi: String, unicode: String, transliteration: String, time: TimeOfDay, duration: Int, description: String, author: String)] = [
        (2,  "Japji Sahib",         "jpujI swihb",         "ਜਪੁਜੀ ਸਾਹਿਬ",          "Japji Sahib",              .morning, 25, "The foundational morning prayer, first composition in Sri Guru Granth Sahib", "Guru Nanak Dev Ji"),
        (4,  "Jaap Sahib",          "jwpu swihb",          "ਜਾਪੁ ਸਾਹਿਬ",           "Jaap Sahib",                 .morning, 15, "Morning prayer praising God's many attributes", "Guru Gobind Singh Ji"),
        (6,  "Tav Prasad Savaiye",  "qÍ pRswid sv`Xy",    "ਤ੍ਵ ਪ੍ਰਸਾਦਿ ਸਵੱਯੇ",     "Tav Prasad Savaiye",      .morning, 5,  "Short morning prayer rejecting ritualism, affirming devotion to one God", "Guru Gobind Singh Ji"),
        (9,  "Chaupai Sahib",       "bynqI cOpeI swihb",  "ਬੇਨਤੀ ਚੌਪਈ ਸਾਹਿਬ",     "Chaupai Sahib",    .morning, 7,  "Prayer of protection and supplication from Dasam Granth", "Guru Gobind Singh Ji"),
        (10, "Anand Sahib",         "Anµdu swihb",        "ਅਨੰਦੁ ਸਾਹਿਬ",          "Anand Sahib",             .morning, 20, "Song of bliss, recited at the close of all Sikh ceremonies", "Guru Amar Das Ji"),
        (21, "Rehras Sahib",        "rhrwis swihb",       "ਰਹਰਾਸਿ ਸਾਹਿਬ",         "Rehras Sahib",             .evening, 20, "The evening prayer giving thanks for the day and seeking protection", "Multiple Gurus"),
        (23, "Kirtan Sohila",       "soihlw swihb",       "ਸੋਹਿਲਾ ਸਾਹਿਬ",         "Kirtan Sohila",              .night,   10, "The bedtime prayer recited before sleep and at funeral ceremonies", "Multiple Gurus"),
        (31, "Sukhmani Sahib",      "suKmnI swihb",       "ਸੁਖਮਨੀ ਸਾਹਿਬ",         "Sukhmani Sahib",           .morning, 90, "Extended psalm of peace, one of the most beloved banis", "Guru Arjan Dev Ji"),
        (90, "Asa Ki Vaar",         "Awsw dI vwr",        "ਆਸਾ ਦੀ ਵਾਰ",           "Asa Ki Vaar",             .morning, 45, "Morning ballad commonly sung in Gurdwaras", "Guru Nanak Dev Ji"),
        (3,  "Shabad Hazare",       "Sbd hzwry",          "ਸ਼ਬਦ ਹਜ਼ਾਰੇ",           "Shabad Hazare",             .morning, 10, "Hymns expressing deep longing for the Divine", "Guru Nanak Dev Ji"),
        (36, "Dukh Bhanjani Sahib", "duK BMjnI swihb",    "ਦੁਖ ਭੰਜਨੀ ਸਾਹਿਬ",      "Dukh Bhanjani Sahib",    .morning, 30, "Healing prayer recited for comfort during illness or hardship", "Multiple Gurus"),
        (27, "Barah Maha",          "bwrh mwhw mWJ",      "ਬਾਰਹ ਮਾਹਾ ਮਾਂਝ",       "Barah Maha",      .morning, 20, "Seasonal hymn describing the soul's longing for God through twelve months", "Guru Nanak Dev Ji"),
        (24, "Ardas",               "Ardwis",             "ਅਰਦਾਸ",                "Ardas",           .morning, 5,  "The formal Sikh prayer of supplication, recited at the close of every service", "Guru Gobind Singh Ji"),
    ]

    static let allowedIDs: Set<Int> = Set(all.map(\.id))
}
