import SwiftUI
import MapKit

// MARK: - Place Search View
struct PlaceSearchView: View {
    @Binding var selectedPlace: PlaceResult?
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var searchResults: [PlaceResult] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var previewPlace: PlaceResult?

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
                        .onSubmit {
                            performSearch()
                        }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            searchResults = []
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
                    // Cancel previous search
                    searchTask?.cancel()

                    if newValue.isEmpty {
                        searchResults = []
                    } else {
                        // Debounce search
                        searchTask = Task {
                            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
                            if !Task.isCancelled {
                                await search()
                            }
                        }
                    }
                }

                // Results
                if isSearching {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.appPrimary))
                    Spacer()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No results found")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else if searchResults.isEmpty {
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
                    List(searchResults) { result in
                        Button {
                            previewPlace = result
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.appPrimary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)

                                    Text(result.address)
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

    private func performSearch() {
        searchTask?.cancel()
        Task {
            await search()
        }
    }

    private func search() async {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }

        await MainActor.run {
            isSearching = true
        }

        do {
            let results = try await APIClient.shared.searchPlaces(query: searchText)
            await MainActor.run {
                searchResults = results
                isSearching = false
            }
        } catch {
            print("DEBUG: Place search error: \(error)")
            await MainActor.run {
                searchResults = []
                isSearching = false
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
}

// MARK: - Place Preview Sheet
struct PlacePreviewSheet: View {
    let place: PlaceResult
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var checkIns: [CheckIn] = []
    @State private var reviews: [PlaceReview] = []
    @State private var checkInCount: Int = 0
    @State private var averageRating: Double?
    @State private var isLoadingSocial = true

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
                            Text("Check-ins")
                                .font(.headline)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(checkIns) { checkIn in
                                        if let user = checkIn.user {
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
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Reviews section
                    if !reviews.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reviews")
                                .font(.headline)
                                .padding(.horizontal)

                            LazyVStack(spacing: 12) {
                                ForEach(reviews) { review in
                                    ReviewRow(review: review)
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task {
            await loadPlaceData()
        }
    }

    private func loadPlaceData() async {
        isLoadingSocial = true
        do {
            let response = try await APIClient.shared.lookupPlace(
                externalId: place.externalId,
                provider: place.provider
            )
            checkIns = response.checkIns
            reviews = response.reviews
            checkInCount = response.place?.checkInCount ?? response.checkIns.count
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
