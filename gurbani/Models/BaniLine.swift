import Foundation
import SwiftData

@Model
final class BaniLine {
    @Attribute(.unique) var lineID: Int
    var baniID: Int
    var lineNo: Int
    var gurmukhi: String
    var unicode: String
    var transliteration: String
    var translation: String
    var isRead: Bool
    var pauriNumber: Int
    var sectionTitle: String
    var simpleTranslation: String?
    var punjabiTranslation: String?

    init(
        lineID: Int,
        baniID: Int,
        lineNo: Int,
        gurmukhi: String,
        unicode: String,
        transliteration: String,
        translation: String,
        isRead: Bool = false,
        pauriNumber: Int,
        sectionTitle: String = "",
        simpleTranslation: String? = nil,
        punjabiTranslation: String? = nil
    ) {
        self.lineID = lineID
        self.baniID = baniID
        self.lineNo = lineNo
        self.gurmukhi = gurmukhi
        self.unicode = unicode
        self.transliteration = transliteration
        self.translation = translation
        self.isRead = isRead
        self.pauriNumber = pauriNumber
        self.sectionTitle = sectionTitle
        self.simpleTranslation = simpleTranslation
        self.punjabiTranslation = punjabiTranslation
    }
}
