import Foundation
import CoreLocation

struct Activity: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let travelId: String
    let itineraryId: String?
    let title: String
    let description: String?
    let orderIndex: Double
    let latitude: FlexibleDouble
    let longitude: FlexibleDouble
    let googlePlaceId: String?
    let createdAt: String?
    let startTime: String?
    var comments: [ActivityComment]?
    let address: String?
    let createdById: String?
    let createdBy: ActivityCreator?

    var latitudeDouble: Double {
        latitude.value
    }

    var longitudeDouble: Double {
        longitude.value
    }
}

struct ActivityCreator: Codable, Equatable, Sendable {
    let id: String
    let name: String
    let email: String
}

// MARK: - Create/Update DTOs
struct CreateActivityRequest: Codable, Sendable {
    let travelId: String
    let itineraryId: String?
    let title: String
    let description: String?
    let latitude: Double
    let longitude: Double
    let googlePlaceId: String?
    let address: String?
    let startTime: String?
}

struct UpdateActivityRequest: Codable, Sendable {
    let title: String?
    let description: String?
    let startTime: String?
    let address: String?
}

struct ReorderActivityRequest: Encodable, Sendable {
    let activityId: String
    let afterActivityId: String?
    let beforeActivityId: String?

    // Custom encoding to explicitly include null values instead of omitting them
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(activityId, forKey: .activityId)
        try container.encode(afterActivityId, forKey: .afterActivityId)
        try container.encode(beforeActivityId, forKey: .beforeActivityId)
    }

    private enum CodingKeys: String, CodingKey {
        case activityId, afterActivityId, beforeActivityId
    }
}

struct AssignActivityRequest: Encodable, Sendable {
    let itineraryId: String?

    // Custom encoding to explicitly include null value instead of omitting it
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(itineraryId, forKey: .itineraryId)
    }

    private enum CodingKeys: String, CodingKey {
        case itineraryId
    }
}

// MARK: - Helper Extensions
extension Activity {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitudeDouble, longitude: longitudeDouble)
    }

    var formattedTime: String? {
        guard let time = startTime else { return nil }

        // Time comes as "HH:mm" or "HH:mm:ss"
        let formatter = DateFormatter()
        formatter.dateFormat = time.count > 5 ? "HH:mm:ss" : "HH:mm"

        guard let parsedTime = formatter.date(from: time) else { return nil }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "h:mm a"

        return displayFormatter.string(from: parsedTime)
    }

    var isWishlist: Bool {
        itineraryId == nil
    }
}

// MARK: - Preview Data
extension Activity {
    static let preview = Activity(
        id: "1",
        travelId: "1",
        itineraryId: "1",
        title: "Tokyo Tower",
        description: "Visit the iconic tower",
        orderIndex: 0.0,
        latitude: FlexibleDouble(35.6586),
        longitude: FlexibleDouble(139.7454),
        googlePlaceId: nil,
        createdAt: ISO8601DateFormatter().string(from: Date()),
        startTime: "10:00",
        comments: [],
        address: "4-2-8 Shibakoen, Minato City, Tokyo",
        createdById: "1",
        createdBy: ActivityCreator(id: "1", name: "John Doe", email: "john@example.com")
    )
}
