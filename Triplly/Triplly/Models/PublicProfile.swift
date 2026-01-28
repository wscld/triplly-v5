import Foundation

struct PublicProfile: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let username: String?
    let profilePhotoUrl: String?
    let travels: [PublicTravel]
    let awards: [Award]?
}

struct PublicTravel: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let description: String?
    let startDate: String?
    let endDate: String?
    let coverImageUrl: String?
    let latitude: FlexibleDouble?
    let longitude: FlexibleDouble?
}

struct UsernameAvailability: Codable, Sendable {
    let available: Bool
    let reason: String?
}
