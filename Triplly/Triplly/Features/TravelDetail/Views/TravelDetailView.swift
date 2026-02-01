import SwiftUI
import MapKit
internal import UniformTypeIdentifiers
import Himetrica

struct TravelDetailView: View {
    let travelId: String
    @StateObject private var viewModel: TravelDetailViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    // Delete/Leave confirmation state
    @State private var showingDeleteTravelAlert = false
    @State private var showingLeaveTravelAlert = false
    @State private var activityToDelete: Activity?
    @State private var showingDeleteActivityAlert = false
    @State private var activityToWishlist: Activity?
    @State private var showingWishlistAlert = false

    // Sheet presentation state
    @State private var showingEditTravel = false
    @State private var showingMembers = false
    @State private var showingTodos = false
    @State private var showingWishlist = false
    @State private var showingAddDay = false
    @State private var showingAddActivity = false
    @State private var selectedActivityForDetail: Activity?
    @State private var selectedItineraryForEdit: Itinerary?

    // Day reordering state
    @State private var draggedItinerary: Itinerary?
    @State private var draggedActivityId: String?
    @State private var targetItineraryId: String?
    @State private var isWishlistDropTarget = false
    @State private var itineraryToDelete: Itinerary?
    @State private var showingDeleteItineraryAlert = false

    init(travelId: String) {
        self.travelId = travelId
        _viewModel = StateObject(wrappedValue: TravelDetailViewModel(travelId: travelId))
    }

    private var isOwner: Bool {
        guard let travel = viewModel.travel,
              let currentUserId = appState.currentUser?.id else {
            return true // Default to owner behavior if we can't determine
        }
        return travel.owner.id == currentUserId
    }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            if let error = viewModel.error, viewModel.travel == nil {
                ErrorView(error: error) {
                    Task { await viewModel.loadTravel() }
                }
            } else if let travel = viewModel.travel {
                travelContent(travel)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(.label))
                        .frame(width: 32, height: 32)
                        .background(Color(.systemBackground).opacity(0.92))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.12), radius: 10, y: 3)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 10) {
                    Button {
                        if appState.showMapSheet {
                            appState.hideMapSheet()
                        } else {
                            appState.showMap(
                                activities: viewModel.selectedActivities,
                                title: viewModel.selectedItinerary?.title
                            )
                        }
                    } label: {
                        Image(systemName: appState.showMapSheet ? "map.fill" : "map")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(width: 32, height: 32)
                            .background(.white.opacity(0.92))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.12), radius: 10, y: 3)
                    }

                    Button {
                        showingEditTravel = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(width: 32, height: 32)
                            .background(.white.opacity(0.92))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.12), radius: 10, y: 3)
                    }

                    Menu {
                        Button {
                            showingMembers = true
                        } label: {
                            Label("Members", systemImage: "person.2")
                        }

                        Button {
                            showingTodos = true
                        } label: {
                            Label("Checklist", systemImage: "checklist")
                        }

                        Divider()

                        if isOwner {
                            Button(role: .destructive) {
                                showingDeleteTravelAlert = true
                            } label: {
                                Label("Delete Trip", systemImage: "trash")
                            }
                        } else {
                            Button(role: .destructive) {
                                showingLeaveTravelAlert = true
                            } label: {
                                Label("Leave Trip", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(width: 32, height: 32)
                            .background(.white.opacity(0.92))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.12), radius: 10, y: 3)
                    }
                }
            }
        }
        .modifier(TravelDetailAlertsModifier(
            viewModel: viewModel,
            dismiss: dismiss,
            showingDeleteTravelAlert: $showingDeleteTravelAlert,
            showingDeleteActivityAlert: $showingDeleteActivityAlert,
            showingLeaveTravelAlert: $showingLeaveTravelAlert,
            activityToDelete: $activityToDelete,
            showingWishlistAlert: $showingWishlistAlert,
            activityToWishlist: $activityToWishlist
        ))
        .task {
            await viewModel.loadTravel()
        }
        .onViewLifecycle(didAppear: {
            appState.currentTravelDetailViewModel = viewModel
            appState.showMap(
                activities: viewModel.selectedActivities,
                title: viewModel.selectedItinerary?.title
            )
        }, willDisappear: {
            appState.hideMapSheet()
        })
        .onChange(of: viewModel.selectedActivities) { _, activities in
            appState.updateMapActivities(activities, title: viewModel.selectedItinerary?.title)
        }
        .onChange(of: viewModel.selectedItineraryIndex) { _, _ in
            appState.updateMapActivities(viewModel.selectedActivities, title: viewModel.selectedItinerary?.title)
        }
        .enableInteractivePopGesture()
        .trackScreen("Travel Detail")
        // Sheet presentations
        .sheet(isPresented: $showingEditTravel) {
            EditTravelSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingMembers) {
            MembersSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingTodos) {
            TodosSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingWishlist) {
            WishlistSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingAddDay) {
            AddDaySheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingAddActivity) {
            AddActivitySheet(viewModel: viewModel)
        }
        .sheet(item: $selectedActivityForDetail) { activity in
            ActivityDetailSheet(activity: activity, viewModel: viewModel)
        }
        .sheet(item: $selectedItineraryForEdit) { itinerary in
            EditItinerarySheet(itinerary: itinerary, viewModel: viewModel)
        }
        .alert("Delete Day", isPresented: $showingDeleteItineraryAlert) {
            Button("Cancel", role: .cancel) {
                itineraryToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let itinerary = itineraryToDelete {
                    Task {
                        await viewModel.deleteItinerary(itinerary)
                    }
                }
                itineraryToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete \"\(itineraryToDelete?.title ?? "this day")\"? All activities in this day will be moved to your wishlist.")
        }
    }

    @ViewBuilder
    private func travelContent(_ travel: Travel) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero image - Airbnb style (with margins and rounded corners)
                GeometryReader { geo in
                    ZStack(alignment: .bottom) {
                        // Cover image
                        TravelCoverImage(coverUrl: travel.coverImageUrl, height: 420, cornerRadius: 0)
                            .frame(width: geo.size.width, height: 420)

                        // Dark gradient for buttons at top
                        LinearGradient(
                            stops: [
                                .init(color: .black.opacity(0.4), location: 0),
                                .init(color: .clear, location: 0.5)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 120)
                        .frame(maxHeight: .infinity, alignment: .top)
                    }
                    .frame(width: geo.size.width, height: 420)
                    .clipShape(RoundedRectangle(cornerRadius: 44, style: .continuous))
                }
                .frame(height: 420)
                .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))

                // Refresh indicator
                if viewModel.isRefreshing {
                    RefreshIndicator()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Content
                VStack(spacing: 20) {
                    // Info chips row
                    infoChipsSection(travel)

                    // Title and description
                    titleSection(travel)

                    // Clickable stats
                    clickableStatsSection

                    // Day Selector & Activities
                    VStack(alignment: .leading, spacing: 16) {
                        if !viewModel.itineraries.isEmpty {
                            daySelectorSection
                        }

                        activitiesSection
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
                .padding(.horizontal, 16)
                .padding(.bottom, 180)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color.appBackground)
        .refreshable {
            await viewModel.refreshTravel()
        }
    }

    // MARK: - Info Chips Section (Airbnb style)
    private func infoChipsSection(_ travel: Travel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let dateRange = travel.formattedDateRange {
                    InfoChip(icon: "calendar", text: dateRange)
                }

                if !viewModel.itineraries.isEmpty {
                    InfoChip(icon: "flag", text: "\(viewModel.itineraries.count) days")
                }

                if !viewModel.members.isEmpty {
                    InfoChip(icon: "person.2", text: "\(viewModel.members.count) travelers")
                }

                let activityCount = viewModel.itineraries.reduce(0) { $0 + ($1.activities?.count ?? 0) }
                if activityCount > 0 {
                    InfoChip(icon: "mappin", text: "\(activityCount) places")
                }
            }
            .padding(.vertical, 12)
        }
    }

    // MARK: - Title Section
    private func titleSection(_ travel: Travel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(travel.title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            if let description = travel.description, !description.isEmpty {
                Text(description)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Clickable Stats Section
    private var clickableStatsSection: some View {
        HStack(spacing: 0) {
            // Wishlist stat (drop target for activities)
            Button {
                showingWishlist = true
            } label: {
                StatItemView(
                    icon: "star.fill",
                    iconColor: .orange,
                    value: "\(viewModel.wishlistActivities.count)",
                    label: "Wishlist"
                )
                .overlay {
                    if isWishlistDropTarget {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.orange, lineWidth: 2)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .scaleEffect(isWishlistDropTarget ? 1.05 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isWishlistDropTarget)
            }
            .buttonStyle(StatButtonStyle())
            .onDrop(of: [.text], delegate: WishlistDropDelegate(
                viewModel: viewModel,
                draggedActivityId: $draggedActivityId,
                isWishlistDropTarget: $isWishlistDropTarget
            ))

            Divider()
                .frame(height: 40)

            // Todos stat
            Button {
                showingTodos = true
            } label: {
                let completedTodos = viewModel.todos.filter { $0.isCompleted }.count
                StatItemView(
                    icon: "checkmark.circle.fill",
                    iconColor: .green,
                    value: "\(completedTodos)/\(viewModel.todos.count)",
                    label: "Checklist"
                )
            }
            .buttonStyle(StatButtonStyle())

            Divider()
                .frame(height: 40)

            // Members stat with avatars
            Button {
                showingMembers = true
            } label: {
                VStack(spacing: 4) {
                    if viewModel.members.isEmpty {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundStyle(.blue)
                    } else {
                        MiniAvatarStack(members: viewModel.members)
                    }
                    Text("Travelers")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(StatButtonStyle())
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
    }

    // MARK: - Day Selector
    private var daySelectorSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(viewModel.itineraries.enumerated()), id: \.element.id) { index, itinerary in
                    DayChip(
                        itinerary: itinerary,
                        dayNumber: index + 1,
                        isSelected: index == viewModel.selectedItineraryIndex,
                        isDropTarget: targetItineraryId == itinerary.id && (draggedItinerary != nil || draggedActivityId != nil)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedItineraryIndex = index
                        }
                    }
                    .onDrag {
                        draggedItinerary = itinerary
                        return NSItemProvider(object: itinerary.id as NSString)
                    }
                    .onDrop(of: [.text], delegate: DayChipDropDelegate(
                        itinerary: itinerary,
                        viewModel: viewModel,
                        draggedItinerary: $draggedItinerary,
                        draggedActivityId: $draggedActivityId,
                        targetItineraryId: $targetItineraryId
                    ))
                    .contextMenu {
                        Button {
                            selectedItineraryForEdit = itinerary
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive) {
                            itineraryToDelete = itinerary
                            showingDeleteItineraryAlert = true
                        } label: {
                            Label("Delete Day", systemImage: "trash")
                        }
                    } preview: {
                        DayChip(itinerary: itinerary, dayNumber: index + 1, isSelected: index == viewModel.selectedItineraryIndex) {}
                            .padding()
                            .onAppear {
                                draggedItinerary = nil
                                targetItineraryId = nil
                            }
                    }
                }
                .padding(.vertical, 12)

                // Add Day Button
                Button {
                    showingAddDay = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                        Text("Add")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color.appPrimary)
                    .frame(width: 60, height: 76)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.appPrimary.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    // MARK: - Activities Section
    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let itinerary = viewModel.selectedItinerary {
                // Section Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Day \(viewModel.selectedItineraryIndex + 1)")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                        if let formattedDate = itinerary.formattedDate {
                            Text(formattedDate)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()

  
                }
                .padding(.top, 8)

                if viewModel.selectedActivities.isEmpty {
                    EmptyActivitiesCard {
                        showingAddActivity = true
                    }
                } else {
                    // Activities Timeline
                    TimelineView(
                        activities: viewModel.selectedActivitiesBinding,
                        onTap: { activity in
                            selectedActivityForDetail = activity
                        },
                        onReorderComplete: { movedActivity, newIndex in
                            Task {
                                await viewModel.saveActivityReorder(activity: movedActivity, newIndex: newIndex)
                            }
                        },
                        onMoveToWishlist: { activity in
                            activityToWishlist = activity
                            showingWishlistAlert = true
                        },
                        onDelete: { activity in
                            activityToDelete = activity
                            showingDeleteActivityAlert = true
                        },
                        checkedInActivityIds: viewModel.checkedInActivityIds,
                        onDragStarted: { activityId in
                            draggedActivityId = activityId
                        },
                        onDragEnded: {
                            draggedActivityId = nil
                        }
                    )

                    // Add Activity Button
                    Button {
                        showingAddActivity = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            Text("Add Activity")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        }
                        .foregroundStyle(Color.appPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.appPrimary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.appPrimary.opacity(0.2), lineWidth: 1)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, 4)
                }

            } else if viewModel.itineraries.isEmpty {
                EmptyDaysCard {
                    showingAddDay = true
                }
            }
        }
    }
}


// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Info Chip (Airbnb style)
struct InfoChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium, design: .rounded))
            Text(text)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)
    }
}

// MARK: - Stat Item View
struct StatItemView: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(iconColor)
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Stat Button Style
struct StatButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Mini Avatar Stack (for stats section)
struct MiniAvatarStack: View {
    let members: [TravelMember]
    private let maxVisible = 3
    private let avatarSize: CGFloat = 24
    private let overlap: CGFloat = 8

    var body: some View {
        HStack(spacing: -overlap) {
            ForEach(Array(members.prefix(maxVisible).enumerated()), id: \.element.id) { index, member in
                MiniAvatar(name: member.user.name, imageUrl: member.user.profilePhotoUrl, size: avatarSize)
                    .overlay {
                        Circle()
                            .stroke(Color(.secondarySystemBackground), lineWidth: 2)
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
                        .stroke(Color(.secondarySystemBackground), lineWidth: 2)
                }
            }
        }
    }
}

// MARK: - Mini Avatar
struct MiniAvatar: View {
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
                .fill(backgroundColor.gradient)
            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Avatar Stack View
struct AvatarStackView: View {
    let members: [TravelMember]
    private let maxVisible = 3
    private let avatarSize: CGFloat = 34
    private let overlap: CGFloat = 8

    var body: some View {
        HStack(spacing: -overlap) {
            ForEach(Array(members.prefix(maxVisible).enumerated()), id: \.element.id) { index, member in
                NetworkAvatarView(
                    name: member.user.name,
                    imageUrl: member.user.profilePhotoUrl,
                    size: avatarSize
                )
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
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.primary)
                }
                .overlay {
                    Circle()
                        .stroke(Color(.systemBackground), lineWidth: 2)
                }
            }

            if members.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 13, weight: .medium))
                    Text("Invite")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Avatar View
struct AvatarView: View {
    let name: String
    let size: CGFloat

    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var backgroundColor: Color {
        let colors: [Color] = [
            .blue, .green, .orange, .purple, .pink, .teal, .indigo
        ]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor.gradient)
                .frame(width: size, height: size)

            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Day Chip
struct DayChip: View {
    let itinerary: Itinerary
    let dayNumber: Int
    let isSelected: Bool
    var isDropTarget: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(itinerary.dayOfWeek?.uppercased() ?? "DAY")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .secondary)
                Text(itinerary.shortDate ?? "\(dayNumber)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(width: 60, height: 76)
            .background(isSelected ? Color.appPrimary : Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(isSelected ? 0 : 0.06), radius: 8, y: 3)
            .overlay {
                if isDropTarget {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.appPrimary, lineWidth: 2)
                }
            }
            .scaleEffect(isDropTarget ? 1.05 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isDropTarget)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Timeline View
struct TimelineView: View {
    @Binding var activities: [Activity]
    let onTap: (Activity) -> Void
    let onReorderComplete: (Activity, Int) -> Void  // (movedActivity, newIndex)
    let onMoveToWishlist: (Activity) -> Void
    let onDelete: (Activity) -> Void
    var checkedInActivityIds: Set<String> = []
    var onDragStarted: ((String) -> Void)?
    var onDragEnded: (() -> Void)?

    @State private var draggedActivity: Activity?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                TimelineItemView(
                    activity: activity,
                    number: index + 1,
                    isFirst: index == 0,
                    isLast: index == activities.count - 1,
                    isCheckedIn: checkedInActivityIds.contains(activity.id)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap(activity)
                }
                .onDrag {
                    draggedActivity = activity
                    onDragStarted?(activity.id)
                    return NSItemProvider(object: activity.id as NSString)
                }
                .onDrop(of: [.text], delegate: TimelineDropDelegate(
                    activity: activity,
                    activities: $activities,
                    draggedActivity: $draggedActivity,
                    onReorderComplete: onReorderComplete
                ))

                if index < activities.count - 1 {
                    Divider()
                        .padding(.leading, 50)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onChange(of: draggedActivity) { _, newValue in
            if newValue == nil {
                onDragEnded?()
            }
        }
    }
}

// MARK: - Timeline Drop Delegate
struct TimelineDropDelegate: DropDelegate {
    let activity: Activity
    @Binding var activities: [Activity]
    @Binding var draggedActivity: Activity?
    let onReorderComplete: (Activity, Int) -> Void

    func performDrop(info: DropInfo) -> Bool {
        guard let movedActivity = draggedActivity,
              let newIndex = activities.firstIndex(where: { $0.id == movedActivity.id }) else {
            draggedActivity = nil
            return false
        }
        print("DEBUG: performDrop - activity '\(movedActivity.title)' now at index \(newIndex)")
        let activityToSave = movedActivity
        let indexToSave = newIndex
        draggedActivity = nil
        onReorderComplete(activityToSave, indexToSave)
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedActivity = draggedActivity,
              draggedActivity.id != activity.id,
              let fromIndex = activities.firstIndex(where: { $0.id == draggedActivity.id }),
              let toIndex = activities.firstIndex(where: { $0.id == activity.id }) else {
            return
        }

        print("DEBUG: dropEntered - moving from \(fromIndex) to \(toIndex)")
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            activities.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

// MARK: - Day Chip Drop Delegate (handles both itinerary reorder and activity moves)
struct DayChipDropDelegate: DropDelegate {
    let itinerary: Itinerary
    let viewModel: TravelDetailViewModel
    @Binding var draggedItinerary: Itinerary?
    @Binding var draggedActivityId: String?
    @Binding var targetItineraryId: String?

    func performDrop(info: DropInfo) -> Bool {
        // Activity drop
        if let activityId = draggedActivityId {
            var foundActivity: Activity?
            for itin in viewModel.itineraries {
                if let activity = itin.activities?.first(where: { $0.id == activityId }) {
                    foundActivity = activity
                    break
                }
            }

            guard let activity = foundActivity else {
                draggedActivityId = nil
                targetItineraryId = nil
                return false
            }

            // Don't move if dropping on the same day
            let sourceItinerary = viewModel.itineraries.first { itin in
                itin.activities?.contains(where: { $0.id == activityId }) == true
            }
            guard sourceItinerary?.id != itinerary.id else {
                draggedActivityId = nil
                targetItineraryId = nil
                return false
            }

            let targetId = itinerary.id
            draggedActivityId = nil
            targetItineraryId = nil

            Task {
                await viewModel.moveActivityToDay(activity, itineraryId: targetId)
            }
            return true
        }

        // Itinerary reorder
        guard let dragged = draggedItinerary,
              let targetId = targetItineraryId,
              let toIndex = viewModel.itineraries.firstIndex(where: { $0.id == targetId }) else {
            draggedItinerary = nil
            targetItineraryId = nil
            return false
        }

        viewModel.reorderItinerary(dragged, to: toIndex)
        draggedItinerary = nil
        targetItineraryId = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        // Activity drag
        if let activityId = draggedActivityId {
            let isInThisItinerary = itinerary.activities?.contains(where: { $0.id == activityId }) == true
            if !isInThisItinerary {
                targetItineraryId = itinerary.id
            }
            return
        }

        // Itinerary reorder
        guard let dragged = draggedItinerary,
              dragged.id != itinerary.id else {
            return
        }
        targetItineraryId = itinerary.id
    }

    func dropExited(info: DropInfo) {
        if targetItineraryId == itinerary.id {
            targetItineraryId = nil
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

// MARK: - Wishlist Drop Delegate
struct WishlistDropDelegate: DropDelegate {
    let viewModel: TravelDetailViewModel
    @Binding var draggedActivityId: String?
    @Binding var isWishlistDropTarget: Bool

    func performDrop(info: DropInfo) -> Bool {
        guard let activityId = draggedActivityId else {
            isWishlistDropTarget = false
            return false
        }

        // Find the activity in itineraries
        var foundActivity: Activity?
        for itinerary in viewModel.itineraries {
            if let activity = itinerary.activities?.first(where: { $0.id == activityId }) {
                foundActivity = activity
                break
            }
        }

        guard let activity = foundActivity else {
            draggedActivityId = nil
            isWishlistDropTarget = false
            return false
        }

        draggedActivityId = nil
        isWishlistDropTarget = false

        Task {
            await viewModel.moveActivityToWishlist(activity)
        }
        return true
    }

    func dropEntered(info: DropInfo) {
        if draggedActivityId != nil {
            isWishlistDropTarget = true
        }
    }

    func dropExited(info: DropInfo) {
        isWishlistDropTarget = false
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: draggedActivityId != nil ? .move : .cancel)
    }
}

// MARK: - Timeline Item View
struct TimelineItemView: View {
    let activity: Activity
    let number: Int
    let isFirst: Bool
    let isLast: Bool
    var isCheckedIn: Bool = false

    private let circleSize: CGFloat = 28
    private let lineWidth: CGFloat = 2

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Timeline indicator column
            ZStack(alignment: .top) {
                // Line - only show if not the only item
                if !(isFirst && isLast) {
                    VStack(spacing: 0) {
                        // Top portion of line
                        Rectangle()
                            .fill(isFirst ? Color.clear : Color.appPrimary)
                            .frame(width: lineWidth, height: 20)

                        // Bottom portion of line
                        Rectangle()
                            .fill(isLast ? Color.clear : Color.appPrimary)
                            .frame(width: lineWidth)
                            .frame(maxHeight: .infinity)
                    }
                }

                // Circle with number + check-in badge
                ZStack {
                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: circleSize, height: circleSize)

                    Text("\(number)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)

                    if isCheckedIn {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .frame(width: 14, height: 14)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.green)
                        }
                        .offset(x: 10, y: -10)
                    }
                }
                .padding(.top, 6)
            }
            .frame(width: 36)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let address = activity.address {
                    Text(address)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let time = activity.formattedTime {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10, design: .rounded))
                        Text(time)
                    }
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 12)

            Spacer(minLength: 0)

            if let creator = activity.createdBy {
                NetworkAvatarView(
                    name: creator.name,
                    imageUrl: creator.profilePhotoUrl,
                    size: 24
                )
                .padding(.top, 12)
                .padding(.trailing, 4)
            }
        }
        .frame(minHeight: 60)
    }
}

// MARK: - Map Pin View
struct MapPinView: View {
    let number: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.appPrimary)
                .frame(width: 28, height: 28)

            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Activity Detail Sheet
struct ActivityDetailSheet: View {
    let activity: Activity
    @ObservedObject var viewModel: TravelDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var mapRegion: MKCoordinateRegion
    @State private var comments: [ActivityComment] = []
    @State private var newComment = ""
    @State private var isLoadingComments = false
    @State private var isSendingComment = false
    @State private var showingDeleteAlert = false
    @State private var showingWishlistAlert = false
    @State private var showingMoveAlert = false
    @State private var selectedMoveTarget: Itinerary?
    @State private var showCreatorProfile = false
    @State private var showingPlaceDetail = false
    @State private var showingCheckInConfirm = false
    @State private var showingUndoCheckInConfirm = false
    @State private var isCheckingIn = false
    @State private var isUndoingCheckIn = false
    @FocusState private var isCommentFocused: Bool

    init(activity: Activity, viewModel: TravelDetailViewModel) {
        self.activity = activity
        self.viewModel = viewModel
        _mapRegion = State(initialValue: MKCoordinateRegion(
            center: activity.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    mapPreviewSection
                    detailsSection
                    Divider()
                        .padding(.horizontal)
                    commentsSection
                    Divider()
                        .padding(.horizontal)
                    actionsSection
                }
                .padding(.vertical)
            }
            .navigationTitle(activity.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Menu {
                            Button {
                                showingWishlistAlert = true
                            } label: {
                                Label("Move to Wishlist", systemImage: "star")
                            }

                            if viewModel.itineraries.count > 1 {
                                let currentItineraryId = viewModel.itineraries.first(where: { itinerary in
                                    itinerary.activities?.contains(where: { $0.id == activity.id }) == true
                                })?.id

                                Menu("Move to Day") {
                                    ForEach(Array(viewModel.itineraries.enumerated()), id: \.element.id) { index, itinerary in
                                        if itinerary.id != currentItineraryId {
                                            Button {
                                                selectedMoveTarget = itinerary
                                                showingMoveAlert = true
                                            } label: {
                                                Label(
                                                    "Day \(index + 1) — \(itinerary.title)",
                                                    systemImage: "calendar"
                                                )
                                            }
                                        }
                                    }
                                }
                            }

                            Divider()

                            Button(role: .destructive) {
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete Activity", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.body)
                        }

                        Button("Done") {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .alert("Delete Activity", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteActivity(activity)
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to delete \"\(activity.title)\"?")
            }
            .alert("Move to Wishlist", isPresented: $showingWishlistAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Move", role: .destructive) {
                    Task {
                        await viewModel.moveActivityToWishlist(activity)
                        dismiss()
                    }
                }
            } message: {
                Text("Move \"\(activity.title)\" to the wishlist? It will be removed from the current day.")
            }
            .alert("Move to Day", isPresented: $showingMoveAlert) {
                Button("Cancel", role: .cancel) {
                    selectedMoveTarget = nil
                }
                Button("Move") {
                    if let target = selectedMoveTarget {
                        Task {
                            await viewModel.moveActivityToDay(activity, itineraryId: target.id)
                            dismiss()
                        }
                    }
                    selectedMoveTarget = nil
                }
            } message: {
                Text("Move \"\(activity.title)\" to \"\(selectedMoveTarget?.title ?? "this day")\"?")
            }
            .alert("Check In", isPresented: $showingCheckInConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Check In") {
                    isCheckingIn = true
                    Task {
                        await viewModel.checkInActivity(activity)
                        isCheckingIn = false
                    }
                }
            } message: {
                Text("Check in at \"\(activity.title)\"?")
            }
            .alert("Undo Check-In", isPresented: $showingUndoCheckInConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Undo", role: .destructive) {
                    isUndoingCheckIn = true
                    Task {
                        await viewModel.uncheckInActivity(activity)
                        isUndoingCheckIn = false
                    }
                }
            } message: {
                Text("Remove your check-in at \"\(activity.title)\"?")
            }
            .sheet(isPresented: $showCreatorProfile) {
                if let username = activity.createdBy?.username {
                    NavigationStack {
                        PublicProfileView(username: username)
                    }
                }
            }
            .sheet(isPresented: $showingPlaceDetail) {
                if let placeId = activity.placeId {
                    PlaceDetailView(placeId: placeId)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task {
            await loadComments()
        }
    }
    
    // MARK: - Activity Detail Sections
    
    private var mapPreviewSection: some View {
        Map(coordinateRegion: $mapRegion, annotationItems: [activity]) { act in
            MapAnnotation(coordinate: act.coordinate) {
                MapPinView(number: 1)
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let time = activity.formattedTime {
                DetailRow(icon: "clock.fill", title: "Time", value: time)
            }

            if let address = activity.address {
                DetailRow(icon: "mappin.circle.fill", title: "Location", value: address)
            }

            if let description = activity.description, !description.isEmpty {
                DetailRow(icon: "text.alignleft", title: "Notes", value: description)
            }

            if let creator = activity.createdBy {
                creatorRow(creator)
            }

            if activity.placeId != nil {
                placeDetailButton
            }
        }
        .padding(.horizontal)
    }
    
    private func creatorRow(_ creator: ActivityCreator) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "person.fill")
                .foregroundStyle(Color.appPrimary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text("Added by")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let username = creator.username {
                    Button {
                        showCreatorProfile = true
                    } label: {
                        Text(creator.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.appPrimary)
                    }
                } else {
                    Text(creator.name)
                        .font(.subheadline)
                }
            }
        }
    }
    
    private var placeDetailButton: some View {
        Button {
            showingPlaceDetail = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "building.2.fill")
                    .foregroundStyle(Color.appPrimary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Place")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("View Place Details")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.appPrimary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            commentHeader
            commentInput
            commentsList
        }
    }
    
    private var commentHeader: some View {
        HStack {
            Text("Comments")
                .font(.headline)

            if !comments.isEmpty {
                Text("\(comments.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.appPrimary)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal)
    }
    
    private var commentInput: some View {
        HStack(spacing: 10) {
            TextField("Add a comment...", text: $newComment, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .focused($isCommentFocused)
                .lineLimit(1...4)

            Button {
                Task { await sendComment() }
            } label: {
                Group {
                    if isSendingComment {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                }
                .frame(width: 40, height: 40)
                .background(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.appPrimary)
                .foregroundStyle(.white)
                .clipShape(Circle())
            }
            .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSendingComment)
        }
        .padding(.horizontal)
    }
    
    private var commentsList: some View {
        Group {
            if isLoadingComments {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if comments.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.title)
                        .foregroundStyle(.tertiary)
                    Text("No comments yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Be the first to comment!")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(comments) { comment in
                        CommentRow(comment: comment) {
                            Task { await deleteComment(comment) }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var actionsSection: some View {
        VStack(spacing: 10) {
            checkInButton
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var checkInButton: some View {
        Group {
            if viewModel.isActivityCheckedIn(activity) {
                Button {
                    showingUndoCheckInConfirm = true
                } label: {
                    HStack {
                        if isUndoingCheckIn {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .green))
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Checked In")
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(isUndoingCheckIn)
            } else {
                Button {
                    showingCheckInConfirm = true
                } label: {
                    HStack {
                        if isCheckingIn {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                        } else {
                            Image(systemName: "checkmark.circle")
                            Text("Check In")
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.1))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(isCheckingIn)
            }
        }
    }
    
    private func loadComments() async {
        isLoadingComments = true
        do {
            comments = try await APIClient.shared.getActivityComments(activityId: activity.id)
        } catch {
            print("Failed to load comments: \(error)")
        }
        isLoadingComments = false
    }

    private func sendComment() async {
        let content = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        isSendingComment = true
        do {
            let comment = try await APIClient.shared.createComment(activityId: activity.id, content: content)
            comments.insert(comment, at: 0)
            newComment = ""
            isCommentFocused = false
        } catch {
            print("Failed to send comment: \(error)")
        }
        isSendingComment = false
    }

    private func deleteComment(_ comment: ActivityComment) async {
        do {
            try await APIClient.shared.deleteComment(commentId: comment.id)
            comments.removeAll { $0.id == comment.id }
        } catch {
            print("Failed to delete comment: \(error)")
        }
    }
}

// MARK: - Comment Row
struct CommentRow: View {
    let comment: ActivityComment
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            NetworkAvatarView(name: comment.user.name, imageUrl: comment.user.profilePhotoUrl, size: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.user.name)
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    Text(comment.formattedDate)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Text(comment.content)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.appPrimary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
            }
        }
    }
}

// MARK: - Empty States
struct EmptyActivitiesCard: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 40, weight: .medium, design: .rounded))
                .foregroundStyle(Color.appPrimary.opacity(0.6))

            VStack(spacing: 6) {
                Text("No places added")
                    .font(.system(.headline, design: .rounded))
                Text("Start adding places you want to visit")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Button(action: action) {
                Text("Add Place")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.appPrimary)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct EmptyDaysCard: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40, weight: .medium, design: .rounded))
                .foregroundStyle(Color.appPrimary.opacity(0.6))

            VStack(spacing: 6) {
                Text("No days planned")
                    .font(.system(.headline, design: .rounded))
                Text("Create your first day to start planning")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Button(action: action) {
                Text("Add Day")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.appPrimary)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Alerts Modifier
struct TravelDetailAlertsModifier: ViewModifier {
    @ObservedObject var viewModel: TravelDetailViewModel
    let dismiss: DismissAction
    @Binding var showingDeleteTravelAlert: Bool
    @Binding var showingDeleteActivityAlert: Bool
    @Binding var showingLeaveTravelAlert: Bool
    @Binding var activityToDelete: Activity?
    @Binding var showingWishlistAlert: Bool
    @Binding var activityToWishlist: Activity?

    func body(content: Content) -> some View {
        content
            .alert("Delete Trip", isPresented: $showingDeleteTravelAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteTravel()
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to delete \"\(viewModel.travel?.title ?? "this trip")\"? This action cannot be undone.")
            }
            .alert("Delete Activity", isPresented: $showingDeleteActivityAlert) {
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
            .alert("Move to Wishlist", isPresented: $showingWishlistAlert) {
                Button("Cancel", role: .cancel) {
                    activityToWishlist = nil
                }
                Button("Move", role: .destructive) {
                    if let activity = activityToWishlist {
                        Task {
                            await viewModel.moveActivityToWishlist(activity)
                        }
                    }
                    activityToWishlist = nil
                }
            } message: {
                Text("Move \"\(activityToWishlist?.title ?? "this activity")\" to the wishlist? It will be removed from the current day.")
            }
            .alert("Leave Trip", isPresented: $showingLeaveTravelAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Leave", role: .destructive) {
                    Task {
                        await viewModel.leaveTravel()
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to leave \"\(viewModel.travel?.title ?? "this trip")\"? You will no longer have access to this trip.")
            }
    }
}

#Preview {
    NavigationStack {
        TravelDetailView(travelId: "1")
    }
    .environmentObject(AppState())
}
