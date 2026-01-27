import SwiftUI
import MapKit
internal import UniformTypeIdentifiers

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
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if viewModel.isLoading && viewModel.travel == nil {
                LoadingView(message: "Loading trip...")
            } else if let error = viewModel.error, viewModel.travel == nil {
                ErrorView(error: error) {
                    Task { await viewModel.loadTravel() }
                }
            } else if let travel = viewModel.travel {
                travelContent(travel)
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    // hideMapSheet is called in willDisappear
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 8) {
                    Button {
                        appState.showNestedSheet(.editTravel)
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.black.opacity(0.3))
                            .clipShape(Circle())
                    }

                    Menu {
                        Button {
                            appState.showNestedSheet(.members)
                        } label: {
                            Label("Members", systemImage: "person.2")
                        }

                        Button {
                            appState.showNestedSheet(.todos)
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
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.black.opacity(0.3))
                            .clipShape(Circle())
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
            activityToDelete: $activityToDelete
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
    }

    @ViewBuilder
    private func travelContent(_ travel: Travel) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with parallax cover image
                GeometryReader { geometry in
                    let minY = geometry.frame(in: .global).minY
                    let isScrollingUp = minY > 0
                    let headerHeight: CGFloat = 300

                    ZStack(alignment: .bottom) {
                        TravelCoverImage(
                            coverUrl: travel.coverImageUrl,
                            height: isScrollingUp ? headerHeight + minY : headerHeight,
                            cornerRadius: 0
                        )
                        .overlay {
                            LinearGradient(
                                stops: [
                                    .init(color: .black.opacity(0.4), location: 0),
                                    .init(color: .clear, location: 0.4),
                                    .init(color: .black.opacity(0.8), location: 1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }

                        headerOverlay(travel)
                    }
                    .offset(y: isScrollingUp ? -minY : 0)
                }
                .frame(height: 300)

                VStack(spacing: 24) {
                    // Quick Actions
                    quickActionsSection
                        .padding(.top, 20)

                    // Day Selector & Activities
                    VStack(alignment: .leading, spacing: 16) {
                        if !viewModel.itineraries.isEmpty {
                            daySelectorSection
                        }

                        activitiesSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 180)
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Header Overlay
    private func headerOverlay(_ travel: Travel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Spacer()

            // Title
            Text(travel.title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)

            // Date and stats row
            HStack(spacing: 10) {
                if let dateRange = travel.formattedDateRange {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(dateRange)
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial.opacity(0.6))
                    .clipShape(Capsule())
                }

                if !viewModel.itineraries.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "flag.fill")
                            .font(.caption)
                        Text("\(viewModel.itineraries.count) days")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial.opacity(0.6))
                    .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .padding(.bottom, 8)
    }

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "star.fill",
                label: "Wishlist",
                count: viewModel.wishlistActivities.count
            ) {
                appState.showNestedSheet(.wishlist)
            }

            QuickActionButton(
                icon: "checklist",
                label: "Todos",
                progress: viewModel.todoProgress
            ) {
                appState.showNestedSheet(.todos)
            }

            Spacer()

            // Avatar Stack for Team
            Button {
                appState.showNestedSheet(.members)
            } label: {
                AvatarStackView(members: viewModel.members)
            }
        }
    }

    // MARK: - Day Selector
    private var daySelectorSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(viewModel.itineraries.enumerated()), id: \.element.id) { index, itinerary in
                    DayChip(
                        itinerary: itinerary,
                        dayNumber: index + 1,
                        isSelected: index == viewModel.selectedItineraryIndex
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedItineraryIndex = index
                        }
                    }
                    .contextMenu {
                        Button {
                            appState.showNestedSheet(.editItinerary(itinerary))
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive) {
                            Task { await viewModel.deleteItinerary(itinerary) }
                        } label: {
                            Label("Delete Day", systemImage: "trash")
                        }
                    }
                }

                // Add Day Button
                Button {
                    appState.showNestedSheet(.addDay)
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Add")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(Color.appPrimary)
                    .frame(width: 52, height: 52)
                    .background(Color.appPrimary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.appPrimary.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                    }
                }
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
                            .font(.headline)
                        if let formattedDate = itinerary.formattedDate {
                            Text(formattedDate)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 4)
                .padding(.top, 8)

                if viewModel.selectedActivities.isEmpty {
                    EmptyActivitiesCard {
                        appState.showNestedSheet(.addActivity)
                    }
                } else {
                    // Activities Timeline
                    TimelineView(
                        activities: viewModel.selectedActivitiesBinding,
                        onTap: { activity in
                            appState.showNestedSheet(.activityDetail(activity))
                        },
                        onReorderComplete: { movedActivity, newIndex in
                            Task {
                                await viewModel.saveActivityReorder(activity: movedActivity, newIndex: newIndex)
                            }
                        },
                        onMoveToWishlist: { activity in
                            Task {
                                await viewModel.moveActivityToWishlist(activity)
                            }
                        },
                        onDelete: { activity in
                            activityToDelete = activity
                            showingDeleteActivityAlert = true
                        }
                    )

                    // Add Activity Button (only when there are activities)
                    Button {
                        appState.showNestedSheet(.addActivity)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.appPrimary)
                                .clipShape(Circle())

                            Text("Add another activity")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.foreground)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(12)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.black.opacity(0.06), radius: 6, y: 2)
                    }
                }

            } else if viewModel.itineraries.isEmpty {
                EmptyDaysCard {
                    appState.showNestedSheet(.addDay)
                }
            }
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let label: String
    var count: Int?
    var progress: Double?
    let action: () -> Void

    init(icon: String, label: String, count: Int? = nil, progress: Double? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.count = count
        self.progress = progress
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    if let progress = progress {
                        Circle()
                            .stroke(Color(.systemGray4), lineWidth: 2.5)
                            .frame(width: 32, height: 32)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.appPrimary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            .frame(width: 32, height: 32)
                            .rotationEffect(.degrees(-90))

                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.appPrimary)
                    } else {
                        Circle()
                            .fill(Color.appPrimary)
                            .frame(width: 32, height: 32)

                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color(.label))

                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(Color.appPrimary)
                        .clipShape(Circle())
                }
            }
            .padding(.leading, 6)
            .padding(.trailing, 14)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
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
                HStack(spacing: 6) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 14, weight: .medium))
                    Text("Invite")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.appPrimary)
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(itinerary.dayOfWeek?.uppercased() ?? "DAY")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                Text(itinerary.shortDate ?? "\(dayNumber)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(width: 52, height: 52)
            .background(isSelected ? Color.appPrimary : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                if !isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 0.5)
                }
            }
        }
    }
}

// MARK: - Timeline View
struct TimelineView: View {
    @Binding var activities: [Activity]
    let onTap: (Activity) -> Void
    let onReorderComplete: (Activity, Int) -> Void  // (movedActivity, newIndex)
    let onMoveToWishlist: (Activity) -> Void
    let onDelete: (Activity) -> Void

    @State private var draggedActivity: Activity?

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                TimelineItemView(
                    activity: activity,
                    number: index + 1,
                    isFirst: index == 0,
                    isLast: index == activities.count - 1
                )
                .contentShape(Rectangle())
                .opacity(1)
                .onTapGesture {
                    onTap(activity)
                }
                .onDrag {
                    draggedActivity = activity
                    return NSItemProvider(object: activity.id as NSString)
                }
                .onDrop(of: [.text], delegate: TimelineDropDelegate(
                    activity: activity,
                    activities: $activities,
                    draggedActivity: $draggedActivity,
                    onReorderComplete: onReorderComplete
                ))
                .contextMenu {
                    Button {
                        onMoveToWishlist(activity)
                    } label: {
                        Label("Move to Wishlist", systemImage: "star")
                    }

                    Divider()

                    Button(role: .destructive) {
                        onDelete(activity)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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

// MARK: - Timeline Item View
struct TimelineItemView: View {
    let activity: Activity
    let number: Int
    let isFirst: Bool
    let isLast: Bool

    private let circleSize: CGFloat = 32
    private let lineWidth: CGFloat = 2.5

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Drag handle
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.quaternary)
                .frame(width: 28)
                .padding(.top, 28)

            // Timeline indicator column
            VStack(spacing: 0) {
                // Top line
                Rectangle()
                    .fill(isFirst ? Color.clear : Color.appPrimary.opacity(0.3))
                    .frame(width: lineWidth, height: 16)

                // Circle with number
                ZStack {
                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: circleSize, height: circleSize)

                    Text("\(number)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }

                // Bottom line
                Rectangle()
                    .fill(isLast ? Color.clear : Color.appPrimary.opacity(0.3))
                    .frame(width: lineWidth)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 48)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let address = activity.address {
                    Text(address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let time = activity.formattedTime {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(time)
                            .font(.caption)
                    }
                    .foregroundStyle(Color.appPrimary)
                    .padding(.top, 2)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 16)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.quaternary)
                .padding(.trailing, 12)
                .padding(.top, 24)
        }
        .frame(minHeight: 80)
    }
}

// MARK: - Map Pin View
struct MapPinView: View {
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
                    // Map preview
                    Map(coordinateRegion: $mapRegion, annotationItems: [activity]) { act in
                        MapAnnotation(coordinate: act.coordinate) {
                            MapPinView(number: 1)
                        }
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Details Section
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
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.horizontal)

                    // Comments Section
                    VStack(alignment: .leading, spacing: 12) {
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

                        // Comment Input
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

                        // Comments List
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

                    Divider()
                        .padding(.horizontal)

                    // Actions
                    VStack(spacing: 10) {
                        Button {
                            Task {
                                await viewModel.moveActivityToWishlist(activity)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "star")
                                Text("Move to Wishlist")
                            }
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)

                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Activity")
                            }
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .padding(.vertical)
            }
            .navigationTitle(activity.title)
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
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task {
            await loadComments()
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
            AvatarView(name: comment.user.name, size: 32)

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
        VStack(spacing: 16) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 40))
                .foregroundStyle(Color.appPrimary.opacity(0.6))

            VStack(spacing: 4) {
                Text("No activities yet")
                    .font(.headline)
                Text("Add places you want to visit")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button(action: action) {
                Text("Add First Activity")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.appPrimary)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct EmptyDaysCard: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(Color.appPrimary.opacity(0.6))

            VStack(spacing: 4) {
                Text("No days planned")
                    .font(.headline)
                Text("Start by adding days to your trip")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button(action: action) {
                Text("Add First Day")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.appPrimary)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
