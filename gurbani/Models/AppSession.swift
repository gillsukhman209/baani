import Foundation
import SwiftData

@Model
final class AppSession {
    @Attribute(.unique) var dateString: String
    var date: Date

    init(date: Date = .now) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateString = formatter.string(from: date)
        self.date = date
    }
}
