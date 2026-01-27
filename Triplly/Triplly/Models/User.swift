import Foundation

struct User: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let email: String
    let name: String
    let profilePhotoUrl: String?
    let createdAt: String?
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
        profilePhotoUrl: nil,
        createdAt: ISO8601DateFormatter().string(from: Date())
    )
}
