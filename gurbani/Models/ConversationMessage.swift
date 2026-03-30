import Foundation
import SwiftData

@Model
final class ConversationMessage {
    var id: UUID
    var role: String
    var content: String
    var timestamp: Date

    init(role: String, content: String, timestamp: Date = .now) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }

    var isUser: Bool { role == "user" }
    var isAssistant: Bool { role == "assistant" }
    var isError: Bool { role == "error" }
}
