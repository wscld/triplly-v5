import Foundation

struct User: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let email: String
    let name: String
    let username: String?
    let profilePhotoUrl: String?
    let createdAt: String?
    let awards: [Award]?
}

// MARK: - Auth Response
struct AuthResponse: Codable, Sendable {
    let user: User
    let token: String
}

// MARK: - User Preview Data
extension User {
    static let preview = User(
        id: "1",
        email: "john@example.com",
        name: "John Doe",
        username: "johndoe",
        profilePhotoUrl: nil,
        createdAt: ISO8601DateFormatter().string(from: Date()),
        awards: [
            Award(id: "first_steps", name: "First Steps", icon: "figure.walk", description: "Every journey begins with a single step", color: "blue"),
            Award(id: "solo_adventurer", name: "Solo Adventurer", icon: "person.fill", description: "Brave enough to explore alone", color: "purple"),
        ]
    )
}
