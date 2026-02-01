import SwiftUI
import MapKit
import Combine

// MARK: - Search Completer Delegate
@MainActor
final class SearchCompleterDelegate: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var completions: [MKLocalSearchCompletion] = []
    @Published var isSearching = false

    let completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        completer.resultTypes = [.address, .pointOfInterest]
        super.init()
        completer.delegate = self
    }

    func update(query: String) {
        if query.isEmpty {
            completions = []
            isSearching = false
            completer.cancel()
        } else {
            isSearching = true
            completer.queryFragment = query
        }
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results
        Task { @MainActor in
            self.completions = results
            self.isSearching = false
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.completions = []
            self.isSearching = false
        }
    }
}

// MARK: - Place Search View
struct PlaceSearchView: View {
    @Binding var selectedPlace: PlaceResult?
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @StateObject private var completerDelegate = SearchCompleterDelegate()
    @State private var previewPlace: PlaceResult?
    @State private var isResolving = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search for a place...", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            completerDelegate.update(query: "")
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
                .onChange(of: searchText) { _, newValue in
                    completerDelegate.update(query: newValue)
                }

                // Results
                if completerDelegate.isSearching || isResolving {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.appPrimary))
                    Spacer()
                } else if completerDelegate.completions.isEmpty && !searchText.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No results found")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else if completerDelegate.completions.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Search for a place")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else {
                    List(completerDelegate.completions, id: \.self) { completion in
                        Button {
                            resolveCompletion(completion)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.appPrimary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(completion.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)

                                    Text(completion.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Search Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $previewPlace) { place in
                PlacePreviewSheet(place: place) {
                    previewPlace = nil
                    selectedPlace = place
                    dismiss()
                }
            }
        }
    }

    private func resolveCompletion(_ completion: MKLocalSearchCompletion) {
        isResolving = true
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        Task {
            defer { isResolving = false }
            do {
                let response = try await search.start()
                guard let mapItem = response.mapItems.first else { return }

                let coordinate = mapItem.placemark.coordinate
                let name = mapItem.name ?? completion.title
                let address = [
                    mapItem.placemark.locality,
                    mapItem.placemark.administrativeArea,
                    mapItem.placemark.country
                ]
                    .compactMap { $0 }
                    .joined(separator: ", ")

                let externalId = "\(name)_\(String(format: "%.5f", coordinate.latitude))_\(String(format: "%.5f", coordinate.longitude))"
                let category = mapItem.pointOfInterestCategory.flatMap { ActivityCategory.fromMapKit($0) }

                previewPlace = PlaceResult(
                    id: externalId,
                    name: name,
                    address: address.isEmpty ? completion.subtitle : address,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    externalId: externalId,
                    provider: "apple",
                    category: category?.rawValue
                )
            } catch {
                print("DEBUG: Failed to resolve place: \(error)")
            }
        }
    }
}

// MARK: - Place Result
struct PlaceResult: Identifiable, Equatable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let externalId: String
    let provider: String
    let category: String?
}

// MARK: - Place Preview Sheet
struct PlacePreviewSheet: View {
    let place: PlaceResult
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var checkIns: [CheckIn] = []
    @State private var reviews: [PlaceReview] = []
    @State private var checkInCount: Int = 0
    @State private var totalReviews: Int = 0
    @State private var averageRating: Double?
    @State private var isLoadingSocial = true
    @State private var showingAllCheckIns = false
    @State private var showingAllReviews = false
    @State private var foundPlaceId: String?
    @State private var selectedProfileUsername: String?

    private let previewLimit = 5

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Map preview
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )), annotationItems: [place]) { (p: PlaceResult) in
                        MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude)) {
                            ZStack {
                                Circle()
                                    .fill(Color.appPrimary)
                                    .frame(width: 32, height: 32)
                                    .shadow(color: Color.appPrimary.opacity(0.4), radius: 6, y: 3)
                                Image(systemName: "mappin")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Place info
                    VStack(alignment: .leading, spacing: 12) {
                        Text(place.name)
                            .font(.title2.weight(.bold))

                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(Color.appPrimary)
                            Text(place.address)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "globe")
                                .foregroundStyle(Color.appPrimary)
                            Text(String(format: "%.5f, %.5f", place.latitude, place.longitude))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Stats
                    if !isLoadingSocial && (checkInCount > 0 || averageRating != nil) {
                        HStack(spacing: 0) {
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("\(checkInCount)")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                }
                                Text("Check-ins")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)

                            Divider().frame(height: 40)

                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.orange)
                                    if let avg = averageRating {
                                        Text(String(format: "%.1f", avg))
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                    } else {
                                        Text("—")
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Text("Rating")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }

                    // Check-ins section
                    if !checkIns.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Check-ins")
                                    .font(.headline)
                                Spacer()
                                if checkInCount > previewLimit, foundPlaceId != nil {
                                    Button {
                                        showingAllCheckIns = true
                                    } label: {
                                        Text("View All (\(checkInCount))")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(Color.appPrimary)
                                    }
                                }
                            }
                            .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(checkIns) { checkIn in
                                        if let user = checkIn.user {
                                            Button {
                                                if let username = user.username {
                                                    selectedProfileUsername = username
                                                }
                                            } label: {
                                                VStack(spacing: 6) {
                                                    MiniAvatar(
                                                        name: user.name,
                                                        imageUrl: user.profilePhotoUrl,
                                                        size: 40
                                                    )
                                                    Text(user.name.components(separatedBy: " ").first ?? user.name)
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                        .lineLimit(1)
                                                }
                                                .frame(width: 56)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Reviews section
                    if !reviews.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Reviews")
                                    .font(.headline)
                                Spacer()
                                if totalReviews > previewLimit, foundPlaceId != nil {
                                    Button {
                                        showingAllReviews = true
                                    } label: {
                                        Text("View All (\(totalReviews))")
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(Color.appPrimary)
                                    }
                                }
                            }
                            .padding(.horizontal)

                            LazyVStack(spacing: 12) {
                                ForEach(reviews) { review in
                                    ReviewRow(review: review) { username in
                                        selectedProfileUsername = username
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Confirm button
                    Button {
                        onConfirm()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Select This Place")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.appPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Place Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task {
            await loadPlaceData()
        }
        .sheet(isPresented: $showingAllCheckIns) {
            if let placeId = foundPlaceId {
                AllCheckInsSheet(placeId: placeId)
            }
        }
        .sheet(isPresented: $showingAllReviews) {
            if let placeId = foundPlaceId {
                AllReviewsSheet(placeId: placeId)
            }
        }
        .sheet(isPresented: Binding(
            get: { selectedProfileUsername != nil },
            set: { if !$0 { selectedProfileUsername = nil } }
        )) {
            if let username = selectedProfileUsername {
                NavigationStack {
                    PublicProfileView(username: username)
                }
            }
        }
    }

    private func loadPlaceData() async {
        isLoadingSocial = true
        do {
            let response = try await APIClient.shared.lookupPlace(
                externalId: place.externalId,
                provider: place.provider,
                name: place.name,
                latitude: place.latitude,
                longitude: place.longitude
            )
            foundPlaceId = response.place?.id
            checkIns = response.checkIns
            reviews = response.reviews
            checkInCount = response.totalCheckIns ?? response.checkIns.count
            totalReviews = response.totalReviews ?? response.reviews.count
            averageRating = response.place?.averageRating?.value
        } catch {
            print("DEBUG: Failed to load place social data: \(error)")
        }
        isLoadingSocial = false
    }
}

#Preview {
    PlaceSearchView(selectedPlace: .constant(nil))
}
