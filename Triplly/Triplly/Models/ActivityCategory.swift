import MapKit

/// Utility for mapping MapKit POI categories to our category name strings.
/// The actual category data (icons, colors) now comes from the backend via CategoryModel.
enum ActivityCategoryMapper {
    static func fromMapKit(_ poiCategory: MKPointOfInterestCategory) -> String? {
        // Use rawValue string comparison to avoid referencing iOS 18+ symbols
        // which would cause dyld crash on iOS 17 devices.
        let raw = poiCategory.rawValue

        switch raw {
        case MKPointOfInterestCategory.restaurant.rawValue: return "restaurant"
        case MKPointOfInterestCategory.cafe.rawValue: return "cafe"
        case MKPointOfInterestCategory.hotel.rawValue: return "hotel"
        case MKPointOfInterestCategory.museum.rawValue: return "museum"
        case MKPointOfInterestCategory.park.rawValue,
             MKPointOfInterestCategory.nationalPark.rawValue: return "park"
        case MKPointOfInterestCategory.beach.rawValue: return "beach"
        case MKPointOfInterestCategory.airport.rawValue: return "airport"
        case MKPointOfInterestCategory.store.rawValue: return "shopping"
        case MKPointOfInterestCategory.fitnessCenter.rawValue,
             MKPointOfInterestCategory.marina.rawValue,
             MKPointOfInterestCategory.stadium.rawValue: return "sports"
        case MKPointOfInterestCategory.amusementPark.rawValue,
             MKPointOfInterestCategory.aquarium.rawValue,
             MKPointOfInterestCategory.movieTheater.rawValue,
             MKPointOfInterestCategory.theater.rawValue,
             MKPointOfInterestCategory.zoo.rawValue: return "entertainment"
        case MKPointOfInterestCategory.publicTransport.rawValue,
             MKPointOfInterestCategory.gasStation.rawValue,
             MKPointOfInterestCategory.parking.rawValue: return "transport"
        case MKPointOfInterestCategory.hospital.rawValue,
             MKPointOfInterestCategory.pharmacy.rawValue: return "health"
        case MKPointOfInterestCategory.library.rawValue,
             MKPointOfInterestCategory.school.rawValue,
             MKPointOfInterestCategory.university.rawValue: return "education"
        // iOS 18+ categories matched by raw string — no symbol reference needed
        case "MKPOICategoryBakery": return "shopping"
        case "MKPOICategoryBrewery", "MKPOICategoryWinery": return "bar"
        case "MKPOICategoryNightlife": return "nightlife"
        case "MKPOICategoryCarRental", "MKPOICategoryEVCharger": return "transport"
        case "MKPOICategoryGolf", "MKPOICategoryTennis": return "sports"
        default: return nil
        }
    }
}
