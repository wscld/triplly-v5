import Foundation

struct CheckIn: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let placeId: String
    let userId: String
    let activityId: String?
    let createdAt: String?
    let user: CheckInUser?
    let place: Place?
}

struct CheckInUser: Codable, Equatable, Sendable {
    let id: String
    let name: String
    let profilePhotoUrl: String?
}

struct CreateCheckInRequest: Codable, Sendable {
    let activityId: String
}
