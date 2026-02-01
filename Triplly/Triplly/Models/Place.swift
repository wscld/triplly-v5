import Foundation

struct Place: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let latitude: FlexibleDouble
    let longitude: FlexibleDouble
    let address: String?
    let externalId: String?
    let provider: String?
    let category: String?
    let createdAt: String?
    let checkInCount: Int?
    let averageRating: FlexibleDouble?

    var latitudeDouble: Double { latitude.value }
    var longitudeDouble: Double { longitude.value }
}
