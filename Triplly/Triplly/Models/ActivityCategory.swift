import MapKit

/// Utility for mapping MapKit POI categories to our category name strings.
/// The actual category data (icons, colors) now comes from the backend via CategoryModel.
enum ActivityCategoryMapper {
    static func fromMapKit(_ poiCategory: MKPointOfInterestCategory) -> String? {
        switch poiCategory {
        case .restaurant: return "restaurant"
        case .cafe: return "cafe"
        case .hotel: return "hotel"
        case .museum: return "museum"
        case .park, .nationalPark: return "park"
        case .beach: return "beach"
        case .airport: return "airport"
        case .store: return "shopping"
        case .fitnessCenter, .marina, .stadium: return "sports"
        case .amusementPark, .aquarium, .movieTheater, .theater, .zoo: return "entertainment"
        case .publicTransport, .gasStation, .parking: return "transport"
        case .hospital, .pharmacy: return "health"
        case .library, .school, .university: return "education"
        default:
            if #available(iOS 18.0, *) {
                return fromMapKitIOS18(poiCategory)
            }
            return nil
        }
    }

    @available(iOS 18.0, *)
    private static func fromMapKitIOS18(_ poiCategory: MKPointOfInterestCategory) -> String? {
        switch poiCategory {
        case .brewery, .winery: return "bar"
        case .bakery: return "shopping"
        case .nightlife: return "nightlife"
        case .carRental, .evCharger: return "transport"
        case .golf, .tennis: return "sports"
        default: return nil
        }
    }
}
