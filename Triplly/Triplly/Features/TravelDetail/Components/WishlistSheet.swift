import SwiftUI
import MapKit

struct WishlistSheet: View {
    @ObservedObject var viewModel: TravelDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showMap = true
    @State private var activityToDelete: Activity?
    @State private var showingDeleteAlert = false

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
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(.horizontal, 12)
                                    .padding(.bottom, 12)
                                }
                            }
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
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
                                    } onDelete: {
                                        activityToDelete = activity
                                        showingDeleteAlert = true
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Wishlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
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
        VStack(spacing: 16) {
            Image(systemName: "star")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No wishlist items")
                .font(.headline)

            Text("Activities you haven't assigned to a day will appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Wishlist Activity Row
struct WishlistActivityRow: View {
    let activity: Activity
    let itineraries: [Itinerary]
    let onAssign: (String) -> Void
    let onDelete: () -> Void

    @State private var showingAssignMenu = false

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
                            onAssign(itinerary.id)
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

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Wishlist Map Pin View
struct WishlistMapPinView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.yellow)
                .frame(width: 28, height: 28)
                .shadow(color: Color.yellow.opacity(0.4), radius: 4, y: 2)

            Image(systemName: "star.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    WishlistSheet(viewModel: TravelDetailViewModel(travelId: "1"))
}
