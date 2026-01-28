import SwiftUI

struct TravelsListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = TravelsViewModel()
    @State private var selectedFilter: TravelFilter = .all
    @State private var showSearch = false
    @State private var showCompanion = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        case 17..<21: return "Good evening,"
        default: return "Good night,"
        }
    }

    private var userName: String {
        appState.currentUser?.name.components(separatedBy: " ").first ?? "Traveler"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Header with parallax
                GeometryReader { geometry in
                    let minY = geometry.frame(in: .global).minY
                    let isScrollingUp = minY > 0

                    heroHeader(offset: minY)
                        .frame(height: isScrollingUp ? 280 + minY : 280)
                        .offset(y: isScrollingUp ? -minY : 0)
                }
                .frame(height: 280)

                // Filter chips
                filterChips
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .background(Color(.systemGroupedBackground))
                    .contentShape(Rectangle())

                // Content
                if viewModel.isLoading && viewModel.travels.isEmpty {
                    loadingContent
                        .padding(.top, 60)
                } else if let error = viewModel.error, viewModel.travels.isEmpty {
                    errorContent(error)
                        .padding(.top, 60)
                } else if filteredTravels.isEmpty {
                    emptyContent
                        .padding(.top, 60)
                } else {
                    travelsContent
                        .padding(.top, 24)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .top)
        .refreshable {
            await viewModel.refreshTravels()
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showingCreateSheet) {
            CreateTravelSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showSearch) {
            SearchTravelsSheet(travels: viewModel.travels)
        }
        .sheet(isPresented: $showCompanion) {
            CompanionView()
        }
        .alert("Delete Trip", isPresented: $viewModel.showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                viewModel.travelToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let travel = viewModel.travelToDelete {
                    Task {
                        await viewModel.deleteTravel(travel)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete \"\(viewModel.travelToDelete?.title ?? "this trip")\"? This action cannot be undone.")
        }
        .task {
            viewModel.appState = appState
            await viewModel.loadTravels()
        }
        .onAppear {
            if appState.showMapSheet {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    appState.hideMapSheet()
                }
            }
        }
    }

    // MARK: - Hero Header with Parallax
    private func heroHeader(offset: CGFloat) -> some View {
        let parallaxOffset = offset > 0 ? offset * 0.5 : 0

        return ZStack(alignment: .top) {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.appPrimary.opacity(0.6),
                    Color.appPrimary.opacity(0.3),
                    Color(.systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 0) {
                // Top bar with avatar and actions
                HStack {
                    // User avatar and name
                    HStack(spacing: 10) {
                        AsyncImage(url: URL(string: appState.currentUser?.profilePhotoUrl ?? "")) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .overlay {
                                    Text(String(userName.prefix(1)).uppercased())
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())

                        Text(userName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    // Search button
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .buttonStyle(FilterChipButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                // Big greeting title with parallax
                VStack(alignment: .leading, spacing: 2) {
                    Text(greeting)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))

                    HStack(spacing: 12) {
                        Text(userName)
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(.white)

                        // AI Travel chip - opens companion
                        Button {
                            showCompanion = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.caption2)
                                Text("AI")
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.25))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(FilterChipButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .offset(y: parallaxOffset)
            }
        }
    }

    // MARK: - Filter Chips
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TravelFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.title,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    }
                }

                // Add trip button
                Button {
                    viewModel.showingCreateSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("New Trip")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.appPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.appPrimary.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(FilterChipButtonStyle())
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Filtered Travels
    private var filteredTravels: [TravelListItem] {
        switch selectedFilter {
        case .all:
            return viewModel.travels
        case .upcoming:
            return viewModel.upcomingTravels
        case .past:
            return viewModel.pastTravels
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.appPrimary))
        }
    }

    private func errorContent(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text("Something went wrong")
                .font(.headline)
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Try Again") {
                Task { await viewModel.loadTravels() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.appPrimary)
        }
        .padding()
    }

    private var emptyContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "airplane")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No trips yet")
                .font(.headline)
            Text("Start planning your next adventure")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Create Trip") {
                viewModel.showingCreateSheet = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.appPrimary)
        }
        .padding()
    }

    private var travelsContent: some View {
        LazyVStack(spacing: 16) {
            ForEach(filteredTravels) { travel in
                travelCardLink(travel)
            }
        }
        .padding(.bottom, 100)
    }

    private func travelCardLink(_ travel: TravelListItem) -> some View {
        NavigationLink {
            TravelDetailView(travelId: travel.id)
        } label: {
            TravelCard(travel: travel)
                .padding(.horizontal)
        }
        .buttonStyle(.plain)
        .contextMenu {
            if travel.role == .owner {
                Button(role: .destructive) {
                    viewModel.travelToDelete = travel
                    viewModel.showingDeleteAlert = true
                } label: {
                    Label("Delete Trip", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Travel Filter
enum TravelFilter: CaseIterable {
    case all, upcoming, past

    var title: String {
        switch self {
        case .all: return "All"
        case .upcoming: return "Upcoming"
        case .past: return "Past"
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.appPrimary : Color(.systemBackground))
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(isSelected ? 0 : 0.05), radius: 4, y: 2)
        }
        .buttonStyle(FilterChipButtonStyle())
    }
}

struct FilterChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    var iconColor: Color = .primary

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Travel Card
struct TravelCard: View {
    let travel: TravelListItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TravelCoverImage(coverUrl: travel.coverImageUrl, height: 140, cornerRadius: 0)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 12))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(travel.title)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    if travel.role != .owner {
                        Text(travel.role.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                }

                if let dateRange = travel.formattedDateRange {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(dateRange)
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                }

                if let description = travel.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - Search Travels Sheet
struct SearchTravelsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let travels: [TravelListItem]
    @State private var searchText = ""
    @State private var selectedTravelId: String?

    private var filteredTravels: [TravelListItem] {
        if searchText.isEmpty {
            return travels
        }
        return travels.filter { travel in
            travel.title.localizedCaseInsensitiveContains(searchText) ||
            (travel.description?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredTravels.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ForEach(filteredTravels) { travel in
                        Button {
                            selectedTravelId = travel.id
                        } label: {
                            HStack(spacing: 12) {
                                TravelCoverImage(coverUrl: travel.coverImageUrl, height: 50, cornerRadius: 8)
                                    .frame(width: 50, height: 50)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(travel.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    if let dateRange = travel.formattedDateRange {
                                        Text(dateRange)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search trips...")
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(isPresented: Binding(
                get: { selectedTravelId != nil },
                set: { if !$0 { selectedTravelId = nil } }
            )) {
                if let travelId = selectedTravelId {
                    TravelDetailView(travelId: travelId)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TravelsListView()
    }
    .environmentObject(AppState())
}
