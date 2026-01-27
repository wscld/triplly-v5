import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: Date

    enum MessageRole: String, Codable {
        case user
        case assistant
    }

    init(id: String = UUID().uuidString, role: MessageRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

struct CompanionResponse: Codable {
    let response: String
    let timestamp: String
}

struct CompanionRequest: Encodable {
    let message: String
    let conversationHistory: [[String: String]]?
}
