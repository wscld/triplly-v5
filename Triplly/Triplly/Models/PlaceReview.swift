import Foundation

struct PlaceReview: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let placeId: String
    let userId: String
    let rating: Int
    let content: String
    let createdAt: String?
    let user: CheckInUser?
}

struct CreateReviewRequest: Codable, Sendable {
    let placeId: String
    let rating: Int
    let content: String
}
