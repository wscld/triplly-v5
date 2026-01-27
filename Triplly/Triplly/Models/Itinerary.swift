import Foundation

struct Itinerary: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let travelId: String
    let title: String
    let date: String?
    let orderIndex: Double
    var activities: [Activity]?
}

// MARK: - Create/Update DTOs
struct CreateItineraryRequest: Codable, Sendable {
    let travelId: String
    let title: String
    let date: String?
}

struct UpdateItineraryRequest: Codable, Sendable {
    let title: String?
    let date: String?
}

// MARK: - Helper Extensions
extension Itinerary {
    var formattedDate: String? {
        guard let dateStr = date else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let parsedDate = formatter.date(from: dateStr) else { return nil }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "EEE, d MMM"

        return displayFormatter.string(from: parsedDate)
    }

    var shortDate: String? {
        guard let dateStr = date else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let parsedDate = formatter.date(from: dateStr) else { return nil }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "d"

        return displayFormatter.string(from: parsedDate)
    }

    var dayOfWeek: String? {
        guard let dateStr = date else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let parsedDate = formatter.date(from: dateStr) else { return nil }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "EEE"

        return displayFormatter.string(from: parsedDate)
    }
}

// MARK: - Preview Data
extension Itinerary {
    static let preview = Itinerary(
        id: "1",
        travelId: "1",
        title: "Day 1 - Arrival",
        date: "2025-03-15",
        orderIndex: 0.0,
        activities: [Activity.preview]
    )
}
