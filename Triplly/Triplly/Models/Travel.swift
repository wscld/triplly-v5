import Foundation

struct Travel: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let description: String?
    let startDate: String?
    let endDate: String?
    let coverImageUrl: String?
    let latitude: FlexibleDouble?
    let longitude: FlexibleDouble?
    let ownerId: String?
    let owner: TravelOwner
    let createdAt: String?
    let isPublic: Bool?
    let externalId: String?
    let provider: String?
    var itineraries: [Itinerary]?

    var latitudeDouble: Double? {
        latitude?.value
    }

    var longitudeDouble: Double? {
        longitude?.value
    }
}

struct TravelOwner: Codable, Equatable, Hashable, Sendable {
    let id: String
    let name: String
    let email: String?
}

struct TravelListItem: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let title: String
    let description: String?
    let startDate: String?
    let endDate: String?
    let coverImageUrl: String?
    let latitude: FlexibleDouble?
    let longitude: FlexibleDouble?
    let ownerId: String?
    let owner: TravelOwner
    let createdAt: String?
    let isPublic: Bool?
    let role: TravelRole
    var itineraries: [Itinerary]?
    let members: [TravelMemberSummary]?

    var latitudeDouble: Double? {
        latitude?.value
    }

    var longitudeDouble: Double? {
        longitude?.value
    }
}

struct TravelMemberSummary: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let name: String
    let profilePhotoUrl: String?
}

enum TravelRole: String, Codable, Sendable {
    case owner
    case editor
    case viewer
}

// MARK: - Travel Member
struct TravelMember: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let userId: String
    let role: TravelRole
    let joinedAt: String
    let user: MemberUser
}

struct MemberUser: Codable, Equatable, Sendable {
    let id: String
    let name: String
    let email: String
    let profilePhotoUrl: String?
    let username: String?
}

// MARK: - Create/Update DTOs
struct CreateTravelRequest: Codable, Sendable {
    let title: String
    let description: String?
    let startDate: String?
    let endDate: String?
    let latitude: Double?
    let longitude: Double?
    let externalId: String?
    let provider: String?
}

struct UpdateTravelRequest: Codable, Sendable {
    let title: String?
    let description: String?
    let startDate: String?
    let endDate: String?
    let latitude: Double?
    let longitude: Double?
    let isPublic: Bool?
}

struct InviteMemberRequest: Codable, Sendable {
    let email: String
    let role: TravelRole
}

// MARK: - Helper Extensions
extension Travel {
    var formattedDateRange: String? {
        guard let start = startDate else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let startParsed = formatter.date(from: start) else { return nil }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "d MMM"

        if let end = endDate, let endParsed = formatter.date(from: end) {
            return "\(displayFormatter.string(from: startParsed)) - \(displayFormatter.string(from: endParsed))"
        }

        return displayFormatter.string(from: startParsed)
    }

    var isUpcoming: Bool {
        guard let end = endDate else { return true }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let endDate = formatter.date(from: end) else { return true }
        return endDate >= Date()
    }
}

extension TravelListItem {
    var formattedDateRange: String? {
        guard let start = startDate else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let startParsed = formatter.date(from: start) else { return nil }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "d MMM"

        if let end = endDate, let endParsed = formatter.date(from: end) {
            return "\(displayFormatter.string(from: startParsed)) - \(displayFormatter.string(from: endParsed))"
        }

        return displayFormatter.string(from: startParsed)
    }

    var isUpcoming: Bool {
        guard let end = endDate else { return true }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let endDate = formatter.date(from: end) else { return true }
        return endDate >= Date()
    }
}

// MARK: - Preview Data
extension Travel {
    static let preview = Travel(
        id: "1",
        title: "Tokyo Adventure",
        description: "Exploring Japan's capital",
        startDate: "2025-03-15",
        endDate: "2025-03-22",
        coverImageUrl: nil,
        latitude: FlexibleDouble(35.6762),
        longitude: FlexibleDouble(139.6503),
        ownerId: "1",
        owner: TravelOwner(id: "1", name: "John Doe", email: "john@example.com"),
        createdAt: ISO8601DateFormatter().string(from: Date()),
        isPublic: false,
        externalId: nil,
        provider: nil,
        itineraries: []
    )
}

extension TravelListItem {
    static let preview = TravelListItem(
        id: "1",
        title: "Tokyo Adventure",
        description: "Exploring Japan's capital",
        startDate: "2025-03-15",
        endDate: "2025-03-22",
        coverImageUrl: nil,
        latitude: FlexibleDouble(35.6762),
        longitude: FlexibleDouble(139.6503),
        ownerId: "1",
        owner: TravelOwner(id: "1", name: "John Doe", email: "john@example.com"),
        createdAt: ISO8601DateFormatter().string(from: Date()),
        isPublic: false,
        role: .owner,
        itineraries: [],
        members: [TravelMemberSummary(id: "1", name: "John Doe", profilePhotoUrl: nil)]
    )
}
