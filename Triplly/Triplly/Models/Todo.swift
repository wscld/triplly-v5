import Foundation

struct Todo: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let travelId: String
    let title: String
    var isCompleted: Bool
    let createdAt: String
    let updatedAt: String

}

// MARK: - Create/Update DTOs
struct CreateTodoRequest: Codable, Sendable {
    let travelId: String
    let title: String
}

struct UpdateTodoRequest: Codable, Sendable {
    let title: String?
    let isCompleted: Bool?
}

// MARK: - Preview Data
extension Todo {
    static let preview = Todo(
        id: "1",
        travelId: "1",
        title: "Book flights",
        isCompleted: false,
        createdAt: ISO8601DateFormatter().string(from: Date()),
        updatedAt: ISO8601DateFormatter().string(from: Date())
    )

    static let previewList: [Todo] = [
        Todo(id: "1", travelId: "1", title: "Book flights", isCompleted: true,
             createdAt: ISO8601DateFormatter().string(from: Date()),
             updatedAt: ISO8601DateFormatter().string(from: Date())),
        Todo(id: "2", travelId: "1", title: "Reserve hotel", isCompleted: true,
             createdAt: ISO8601DateFormatter().string(from: Date()),
             updatedAt: ISO8601DateFormatter().string(from: Date())),
        Todo(id: "3", travelId: "1", title: "Get travel insurance", isCompleted: false,
             createdAt: ISO8601DateFormatter().string(from: Date()),
             updatedAt: ISO8601DateFormatter().string(from: Date())),
        Todo(id: "4", travelId: "1", title: "Pack bags", isCompleted: false,
             createdAt: ISO8601DateFormatter().string(from: Date()),
             updatedAt: ISO8601DateFormatter().string(from: Date()))
    ]
}
