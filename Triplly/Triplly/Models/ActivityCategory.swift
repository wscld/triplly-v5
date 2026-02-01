import SwiftUI
import MapKit

enum ActivityCategory: String, CaseIterable, Identifiable, Sendable {
    case restaurant
    case cafe
    case bar
    case hotel
    case museum
    case park
    case beach
    case airport
    case shopping
    case nightlife
    case landmark
    case sports
    case entertainment
    case transport
    case health
    case education
    case worship
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .restaurant: "Restaurant"
        case .cafe: "Café"
        case .bar: "Bar"
        case .hotel: "Hotel"
        case .museum: "Museum"
        case .park: "Park"
        case .beach: "Beach"
        case .airport: "Airport"
        case .shopping: "Shopping"
        case .nightlife: "Nightlife"
        case .landmark: "Landmark"
        case .sports: "Sports"
        case .entertainment: "Entertainment"
        case .transport: "Transport"
        case .health: "Health"
        case .education: "Education"
        case .worship: "Place of Worship"
        case .other: "Other"
        }
    }

    var icon: String {
        switch self {
        case .restaurant: "fork.knife"
        case .cafe: "cup.and.saucer.fill"
        case .bar: "wineglass.fill"
        case .hotel: "bed.double.fill"
        case .museum: "building.columns.fill"
        case .park: "leaf.fill"
        case .beach: "beach.umbrella.fill"
        case .airport: "airplane"
        case .shopping: "bag.fill"
        case .nightlife: "moon.stars.fill"
        case .landmark: "mappin.circle.fill"
        case .sports: "figure.run"
        case .entertainment: "theatermasks.fill"
        case .transport: "tram.fill"
        case .health: "cross.case.fill"
        case .education: "graduationcap.fill"
        case .worship: "building.fill"
        case .other: "mappin"
        }
    }

    var color: Color {
        switch self {
        case .restaurant: Color(red: 234/255, green: 88/255, blue: 12/255)   // orange
        case .cafe: Color(red: 161/255, green: 98/255, blue: 7/255)          // brown
        case .bar: Color(red: 147/255, green: 51/255, blue: 234/255)         // purple
        case .hotel: Color(red: 37/255, green: 99/255, blue: 235/255)        // blue
        case .museum: Color(red: 124/255, green: 58/255, blue: 237/255)      // violet
        case .park: Color(red: 22/255, green: 163/255, blue: 74/255)         // green
        case .beach: Color(red: 6/255, green: 182/255, blue: 212/255)        // cyan
        case .airport: Color(red: 71/255, green: 85/255, blue: 105/255)      // slate
        case .shopping: Color(red: 219/255, green: 39/255, blue: 119/255)    // pink
        case .nightlife: Color(red: 79/255, green: 70/255, blue: 229/255)    // indigo
        case .landmark: Color(red: 225/255, green: 29/255, blue: 72/255)     // rose
        case .sports: Color(red: 5/255, green: 150/255, blue: 105/255)       // emerald
        case .entertainment: Color(red: 217/255, green: 119/255, blue: 6/255) // amber
        case .transport: Color(red: 13/255, green: 148/255, blue: 136/255)   // teal
        case .health: Color(red: 239/255, green: 68/255, blue: 68/255)       // red
        case .education: Color(red: 59/255, green: 130/255, blue: 246/255)   // sky
        case .worship: Color(red: 168/255, green: 162/255, blue: 158/255)    // stone
        case .other: Color(red: 107/255, green: 114/255, blue: 128/255)      // gray
        }
    }

    var backgroundColor: Color {
        color.opacity(0.15)
    }

    // MARK: - MapKit Mapping

    static func fromMapKit(_ poiCategory: MKPointOfInterestCategory) -> ActivityCategory? {
        switch poiCategory {
        case .restaurant: .restaurant
        case .cafe: .cafe
        case .brewery, .winery: .bar
        case .hotel: .hotel
        case .museum: .museum
        case .park, .nationalPark: .park
        case .beach: .beach
        case .airport: .airport
        case .store, .bakery: .shopping
        case .nightlife: .nightlife
        case .fitnessCenter, .golf, .marina,
             .stadium, .tennis: .sports
        case .amusementPark, .aquarium, .movieTheater, .theater, .zoo: .entertainment
        case .publicTransport, .carRental, .evCharger, .gasStation, .parking: .transport
        case .hospital, .pharmacy: .health
        case .library, .school, .university: .education
        default: nil
        }
    }

    /// Initialize from a raw string stored in the backend.
    static func from(_ rawValue: String?) -> ActivityCategory? {
        guard let rawValue else { return nil }
        return ActivityCategory(rawValue: rawValue)
    }
}
