import MapKit

/// Utility for mapping MapKit POI categories to our category name strings.
/// The actual category data (icons, colors) now comes from the backend via CategoryModel.
enum ActivityCategoryMapper {
    static func fromMapKit(_ poiCategory: MKPointOfInterestCategory) -> String? {
        switch poiCategory {
        case .restaurant: return "restaurant"
        case .cafe: return "cafe"
        case .brewery, .winery: return "bar"
        case .hotel: return "hotel"
        case .museum: return "museum"
        case .park, .nationalPark: return "park"
        case .beach: return "beach"
        case .airport: return "airport"
        case .store, .bakery: return "shopping"
        case .nightlife: return "nightlife"
        case .fitnessCenter, .marina, .stadium: return "sports"
        case .amusementPark, .aquarium, .movieTheater, .theater, .zoo: return "entertainment"
        case .publicTransport, .carRental, .evCharger, .gasStation, .parking: return "transport"
        case .hospital, .pharmacy: return "health"
        case .library, .school, .university: return "education"
        default:
            if #available(iOS 18.0, *) {
                switch poiCategory {
                case .golf, .tennis: return "sports"
                default: return nil
                }
            }
            return nil
        }
    }
}
