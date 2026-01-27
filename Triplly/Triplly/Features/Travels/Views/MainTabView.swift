import SwiftUI
import MapKit

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab = 0
    @StateObject private var invitesViewModel = InvitesViewModel()
    @State private var profileImage: UIImage?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    TravelsListView()
                }
                .tabItem {
                    Label("Trips", systemImage: "airplane")
                }
                .tag(0)

                NavigationStack {
                    InvitesView()
                }
                .tabItem {
                    Label("Invites", systemImage: "envelope")
                }
                .tag(1)
                .badge(invitesViewModel.invites.count > 0 ? invitesViewModel.invites.count : 0)

                NavigationStack {
                    ProfileView()
                }
                .tabItem {
                    if let image = profileImage {
                        Label {
                            Text("Profile")
                        } icon: {
                            Image(uiImage: image)
                                .renderingMode(.original)
                        }
                    } else {
                        Label("Profile", systemImage: "person.circle.fill")
                    }
                }
                .tag(2)
            }
            .tint(Color.appPrimary)

            CompanionFloatingButton()
                .padding(.trailing, 16)
                .padding(.bottom, 90)
        }
        .task {
            await invitesViewModel.loadInvites()
            await loadProfileImage()
        }
        .onChange(of: appState.currentUser?.profilePhotoUrl) { _, _ in
            Task { await loadProfileImage() }
        }
        .sheet(isPresented: $appState.showMapSheet) {
            GlobalMapSheetView()
                .environmentObject(appState)
                .offset(y: appState.mapSheetOffset)
                .presentationDetents([.height(140), .medium, .large], selection: $appState.mapSheetDetent)
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .height(140)))
                .interactiveDismissDisabled()
        }
    }

    private func loadProfileImage() async {
        guard let urlString = appState.currentUser?.profilePhotoUrl,
              let url = URL(string: urlString) else {
            profileImage = nil
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                // Create circular image at tab bar icon size
                let size: CGFloat = 25
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
                let circular = renderer.image { context in
                    let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
                    UIBezierPath(ovalIn: rect).addClip()

                    // Scale and center the image
                    let imageSize = uiImage.size
                    let scale = max(size / imageSize.width, size / imageSize.height)
                    let scaledWidth = imageSize.width * scale
                    let scaledHeight = imageSize.height * scale
                    let x = (size - scaledWidth) / 2
                    let y = (size - scaledHeight) / 2

                    uiImage.draw(in: CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight))
                }
                await MainActor.run {
                    profileImage = circular.withRenderingMode(.alwaysOriginal)
                }
            }
        } catch {
            print("Failed to load profile image: \(error)")
        }
    }
}

// MARK: - Profile Initials Icon
struct ProfileInitialsIcon: View {
    let name: String

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.appPrimary.opacity(0.2))
            Text(String(name.prefix(1)).uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.appPrimary)
        }
        .frame(width: 24, height: 24)
    }
}

// MARK: - Global Map Sheet View
struct GlobalMapSheetView: View {
    @EnvironmentObject private var appState: AppState
    @State private var mapRegion: MKCoordinateRegion?

    private var activities: [Activity] {
        appState.mapSheetActivities
    }

    private var mapRegionComputed: MKCoordinateRegion {
        guard !activities.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }

        let coordinates = activities.map { $0.coordinate }
        let minLat = coordinates.map(\.latitude).min() ?? 0
        let maxLat = coordinates.map(\.latitude).max() ?? 0
        let minLon = coordinates.map(\.longitude).min() ?? 0
        let maxLon = coordinates.map(\.longitude).max() ?? 0

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max(0.01, (maxLat - minLat) * 1.5),
            longitudeDelta: max(0.01, (maxLon - minLon) * 1.5)
        )

        return MKCoordinateRegion(center: center, span: span)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "map.fill")
                        .foregroundStyle(Color.appPrimary)
                    Text("\(activities.count) places")
                        .font(.subheadline.weight(.semibold))
                }

                Spacer()

                if let title = appState.mapSheetTitle {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)

            // Map
            Map(
                coordinateRegion: Binding(
                    get: { mapRegion ?? mapRegionComputed },
                    set: { mapRegion = $0 }
                ),
                annotationItems: activities
            ) { activity in
                MapAnnotation(coordinate: activity.coordinate) {
                    GlobalMapPinView(
                        number: (activities.firstIndex(where: { $0.id == activity.id }) ?? 0) + 1
                    )
                }
            }
        }
        .onChange(of: activities) { _, _ in
            mapRegion = nil
        }
        .sheet(item: $appState.mapNestedSheet) { sheet in
            if let viewModel = appState.currentTravelDetailViewModel {
                nestedSheetContent(for: sheet, viewModel: viewModel)
            }
        }
    }

    @ViewBuilder
    private func nestedSheetContent(for sheet: MapNestedSheet, viewModel: TravelDetailViewModel) -> some View {
        switch sheet {
        case .editTravel:
            EditTravelSheet(viewModel: viewModel)
        case .members:
            MembersSheet(viewModel: viewModel)
        case .todos:
            TodosSheet(viewModel: viewModel)
        case .wishlist:
            WishlistSheet(viewModel: viewModel)
        case .addDay:
            AddDaySheet(viewModel: viewModel)
        case .addActivity:
            AddActivitySheet(viewModel: viewModel)
        case .activityDetail(let activity):
            ActivityDetailSheet(activity: activity, viewModel: viewModel)
        case .editItinerary(let itinerary):
            EditItinerarySheet(itinerary: itinerary, viewModel: viewModel)
        }
    }
}

// MARK: - Global Map Pin View
struct GlobalMapPinView: View {
    let number: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.appPrimary)
                .frame(width: 32, height: 32)
                .shadow(color: Color.appPrimary.opacity(0.4), radius: 4, y: 2)

            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
