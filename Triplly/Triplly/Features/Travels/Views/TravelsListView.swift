import SwiftUI
import Himetrica

struct TravelsListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = TravelsViewModel()
    @State private var selectedFilter: TravelFilter = .all
    @State private var showSearch = false
    @State private var showCompanion = false
    @State private var showPublicProfile = false

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
                PullToRefreshAnchor(coordinateSpace: "ptr_scroll")

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
                    .background(Color.appBackground)
                    .contentShape(Rectangle())
                    .zIndex(1)

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
        .background(Color.appBackground)
        .ignoresSafeArea(edges: .top)
        .pullToRefresh(isRefreshing: $viewModel.isRefreshing) {
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
        .sheet(isPresented: $showPublicProfile) {
            if let username = appState.currentUser?.username {
                NavigationStack {
                    PublicProfileView(username: username)
                }
            }
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
        .trackScreen("Trips")
    }

    // MARK: - Hero Header with Parallax
    @Environment(\.colorScheme) private var colorScheme

    private func heroHeader(offset: CGFloat) -> some View {
        let parallaxOffset = offset > 0 ? offset * 0.5 : 0

        return ZStack(alignment: .top) {
            // Gradient background
            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        Color(red: 0.08, green: 0.12, blue: 0.06),
                        Color(red: 0.10, green: 0.14, blue: 0.08).opacity(0.8),
                        Color.appBackground
                    ]
                    : [
                        Color.appPrimary.opacity(0.7),
                        Color.appPrimary.opacity(0.4),
                        Color.appBackground
                    ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 0) {
                // Top bar with avatar and actions
                HStack {
                    // User avatar and name
                    Button {
                        showPublicProfile = true
                    } label: {
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: appState.currentUser?.profilePhotoUrl ?? "")) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Circle()
                                    .fill(Color.white.opacity(0.3))
                                    .overlay {
                                        Text(String(userName.prefix(1)).uppercased())
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(.white)
                                    }
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())

                            Text(userName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                    }

                    Spacer()

                    // Search button
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.25))
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
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("New Trip")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.appPrimary.opacity(0.15))
                    .clipShape(Capsule())
                }
                .buttonStyle(FilterChipButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
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
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 56))
                .foregroundStyle(.red.opacity(0.7))
            Text("Something went wrong")
                .font(.title3.weight(.semibold))
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button {
                Task { await viewModel.loadTravels() }
            } label: {
                Text("Try Again")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.appPrimary)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }

    private var emptyContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "airplane")
                .font(.system(size: 56))
                .foregroundStyle(Color.appPrimary.opacity(0.6))
            Text("No trips yet")
                .font(.title3.weight(.semibold))
            Text("Start planning your next adventure")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                viewModel.showingCreateSheet = true
            } label: {
                Text("Create Trip")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.appPrimary)
                    .clipShape(Capsule())
            }
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
                .contentShape(Rectangle())
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
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(isSelected ? Color.appPrimary : Color(.systemBackground))
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(isSelected ? 0 : 0.06), radius: 6, y: 3)
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
            TravelCoverImage(coverUrl: travel.coverImageUrl, height: 160, cornerRadius: 0)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 20))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(travel.title)
                        .font(.system(size: 18, weight: .semibold))
                        .lineLimit(1)
                    Spacer()
                    if travel.role != .owner {
                        Text(travel.role.rawValue.capitalized)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.appPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.appPrimary.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                if let dateRange = travel.formattedDateRange {
                    HStack(spacing: 6) {
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

                if let members = travel.members, !members.isEmpty {
                    CardAvatarStack(members: members)
                }
            }
            .padding(18)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
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

// MARK: - Card Avatar Stack
struct CardAvatarStack: View {
    let members: [TravelMemberSummary]
    private let maxVisible = 4
    private let avatarSize: CGFloat = 26
    private let overlap: CGFloat = 8

    var body: some View {
        HStack(spacing: -overlap) {
            ForEach(Array(members.prefix(maxVisible).enumerated()), id: \.element.id) { item in
                let index = item.offset
                let member = item.element
                MemberMiniAvatar(name: member.name, imageUrl: member.profilePhotoUrl, size: avatarSize)
                    .overlay {
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 2)
                    }
                    .zIndex(Double(maxVisible - index))
            }

            if members.count > maxVisible {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: avatarSize, height: avatarSize)

                    Text("+\(members.count - maxVisible)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                .overlay {
                    Circle()
                        .stroke(Color(.systemBackground), lineWidth: 2)
                }
            }
        }
    }
}

struct MemberMiniAvatar: View {
    let name: String
    let imageUrl: String?
    let size: CGFloat

    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(1)).uppercased()
    }

    private var backgroundColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .teal, .indigo]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }

    var body: some View {
        Group {
            if let urlString = imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        initialsView
                    }
                }
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(backgroundColor.opacity(0.3))
            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(backgroundColor)
        }
    }
}

#Preview {
    NavigationStack {
        TravelsListView()
    }
    .environmentObject(AppState())
}
