import Foundation

struct Award: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let color: String
}
