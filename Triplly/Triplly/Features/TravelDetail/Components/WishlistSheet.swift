import SwiftUI
import MapKit

struct WishlistSheet: View {
    @ObservedObject var viewModel: TravelDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showMap = true
    @State private var activityToDelete: Activity?
    @State private var showingDeleteAlert = false
    @State private var showingAddSheet = false

    private var mapRegion: MKCoordinateRegion {
        guard let first = viewModel.wishlistActivities.first else {
            // Default to travel location or Tokyo
            if let lat = viewModel.travel?.latitudeDouble, let lng = viewModel.travel?.longitudeDouble {
                return MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )
            }
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }

        // Calculate region that fits all wishlist activities
        let latitudes = viewModel.wishlistActivities.map { $0.latitudeDouble }
        let longitudes = viewModel.wishlistActivities.map { $0.longitudeDouble }

        let minLat = latitudes.min() ?? first.latitudeDouble
        let maxLat = latitudes.max() ?? first.latitudeDouble
        let minLng = longitudes.min() ?? first.longitudeDouble
        let maxLng = longitudes.max() ?? first.longitudeDouble

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )

        let latDelta = max(0.02, (maxLat - minLat) * 1.5)
        let lngDelta = max(0.02, (maxLng - minLng) * 1.5)

        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.wishlistActivities.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Map Section
                            VStack(spacing: 0) {
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        showMap.toggle()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "map.fill")
                                            .foregroundStyle(Color.appPrimary)
                                        Text("Map")
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                        Text("\(viewModel.wishlistActivities.count) places")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Image(systemName: showMap ? "chevron.up" : "chevron.down")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                                .buttonStyle(.plain)

                                if showMap {
                                    Map(
                                        coordinateRegion: .constant(mapRegion),
                                        annotationItems: viewModel.wishlistActivities
                                    ) { activity in
                                        MapAnnotation(coordinate: activity.coordinate) {
                                            WishlistMapPinView()
                                        }
                                    }
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .padding(.horizontal, 12)
                                    .padding(.bottom, 12)
                                }
                            }
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
                            .padding(.horizontal, 16)

                            // Activities List
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.wishlistActivities) { activity in
                                    WishlistActivityRow(
                                        activity: activity,
                                        itineraries: viewModel.itineraries
                                    ) { itineraryId in
                                        Task {
                                            await viewModel.assignActivityToDay(activity, itineraryId: itineraryId)
                                        }
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            activityToDelete = activity
                                            showingDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Wishlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddWishlistItemSheet(viewModel: viewModel)
            }
            .alert("Delete Activity", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    activityToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let activity = activityToDelete {
                        Task {
                            await viewModel.deleteActivity(activity)
                        }
                    }
                    activityToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete \"\(activityToDelete?.title ?? "this activity")\"?")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "star")
                .font(.system(size: 56))
                .foregroundStyle(Color.appPrimary.opacity(0.6))

            Text("No wishlist items")
                .font(.title3.weight(.semibold))

            Text("Save places you want to visit and assign them to days later")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showingAddSheet = true
            } label: {
                Text("Add First Item")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.appPrimary)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Wishlist Activity Row
struct WishlistActivityRow: View {
    let activity: Activity
    let itineraries: [Itinerary]
    let onAssign: (String) -> Void

    @State private var selectedItinerary: (id: String, title: String)?
    @State private var showingAssignConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            // Star icon
            Image(systemName: "star.fill")
                .font(.title3)
                .foregroundStyle(.yellow)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.headline)

                if let address = activity.address {
                    Text(address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Assign button
            if !itineraries.isEmpty {
                Menu {
                    ForEach(Array(itineraries.enumerated()), id: \.element.id) { index, itinerary in
                        Button {
                            let displayTitle = itinerary.title.isEmpty ? "Day \(index + 1)" : itinerary.title
                            selectedItinerary = (id: itinerary.id, title: displayTitle)
                            showingAssignConfirmation = true
                        } label: {
                            Label(
                                itinerary.title.isEmpty ? "Day \(index + 1)" : itinerary.title,
                                systemImage: "calendar"
                            )
                        }
                    }
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundStyle(Color.appPrimary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
        .alert("Add to Itinerary", isPresented: $showingAssignConfirmation) {
            Button("Cancel", role: .cancel) {
                selectedItinerary = nil
            }
            Button("Add") {
                if let itinerary = selectedItinerary {
                    onAssign(itinerary.id)
                }
                selectedItinerary = nil
            }
        } message: {
            if let itinerary = selectedItinerary {
                Text("Add \"\(activity.title)\" to \(itinerary.title)?")
            }
        }
    }
}

// MARK: - Wishlist Map Pin View
struct WishlistMapPinView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.orange)
                .frame(width: 32, height: 32)
                .shadow(color: Color.orange.opacity(0.4), radius: 6, y: 3)

            Image(systemName: "star.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Add Wishlist Item Sheet
struct AddWishlistItemSheet: View {
    @ObservedObject var viewModel: TravelDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var selectedPlace: PlaceResult?
    @State private var showingPlaceSearch = false
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Button {
                            showingPlaceSearch = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "location.circle")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)

                                if let place = selectedPlace {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(place.name)
                                            .font(.body)
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                        Text(place.address)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                } else {
                                    Text("Search for a location")
                                        .font(.body)
                                        .foregroundStyle(Color(.placeholderText))
                                }

                                Spacer()

                                if selectedPlace != nil {
                                    Button {
                                        selectedPlace = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // Error
                    if let error = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(error)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Create Button
                    AppButton(
                        title: "Add to Wishlist",
                        icon: "star",
                        isLoading: isCreating,
                        isDisabled: selectedPlace == nil
                    ) {
                        Task {
                            await createWishlistItem()
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add to Wishlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .sheet(isPresented: $showingPlaceSearch) {
                PlaceSearchView(selectedPlace: $selectedPlace)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func createWishlistItem() async {
        guard let place = selectedPlace else {
            errorMessage = "Please select a location"
            return
        }

        isCreating = true
        errorMessage = nil

        let request = CreateActivityRequest(
            travelId: viewModel.travelId,
            itineraryId: nil, // nil = wishlist item
            title: title.isEmpty ? place.name : title,
            description: description.isEmpty ? nil : description,
            latitude: place.latitude,
            longitude: place.longitude,
            externalId: place.externalId,
            provider: place.provider,
            address: place.address,
            startTime: nil,
            category: place.category,
            categoryId: nil
        )

        do {
            let newActivity = try await APIClient.shared.createActivity(request)
            viewModel.wishlistActivities.append(newActivity)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isCreating = false
    }
}

#Preview {
    WishlistSheet(viewModel: TravelDetailViewModel(travelId: "1"))
}
