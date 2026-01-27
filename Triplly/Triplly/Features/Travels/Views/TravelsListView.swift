import SwiftUI

struct TravelsListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = TravelsViewModel()

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if viewModel.isLoading && viewModel.travels.isEmpty {
                loadingContent
            } else if let error = viewModel.error, viewModel.travels.isEmpty {
                errorContent(error)
            } else if viewModel.travels.isEmpty {
                emptyContent
            } else {
                ScrollView {
                    travelsContent
                }
                .refreshable {
                    await viewModel.refreshTravels()
                }
            }
        }
        .navigationTitle("My Trips")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $viewModel.showingCreateSheet) {
            CreateTravelSheet(viewModel: viewModel)
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
            // Hide map sheet when returning to this screen (with delay for smooth transition)
            if appState.showMapSheet {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    appState.hideMapSheet()
                }
            }
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.appPrimary))
            Text("Loading trips...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
            // Stats
            HStack(spacing: 12) {
                StatCard(icon: "suitcase", value: "\(viewModel.totalTrips)", label: "Total")
                StatCard(icon: "calendar", value: "\(viewModel.upcomingCount)", label: "Upcoming", iconColor: Color.appPrimary)
                StatCard(icon: "checkmark.circle", value: "\(viewModel.pastCount)", label: "Completed", iconColor: .green)
            }
            .padding(.horizontal)

            // Search
            AppSearchBar(text: $viewModel.searchText)
                .padding(.horizontal)

            // Upcoming
            if !viewModel.upcomingTravels.isEmpty {
                sectionHeader("Upcoming", count: viewModel.upcomingTravels.count)
                ForEach(viewModel.upcomingTravels) { travel in
                    travelCardLink(travel)
                }
            }

            // Past
            if !viewModel.pastTravels.isEmpty {
                sectionHeader("Past", count: viewModel.pastTravels.count)
                    .padding(.top, 8)
                ForEach(viewModel.pastTravels) { travel in
                    travelCardLink(travel)
                }
            }
        }
        .padding(.vertical)
    }

    private func travelCardLink(_ travel: TravelListItem) -> some View {
        NavigationLink(destination: TravelDetailView(travelId: travel.id)) {
            TravelCard(travel: travel)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .contextMenu {
            NavigationLink(destination: TravelDetailView(travelId: travel.id)) {
                Label("Open", systemImage: "arrow.right.circle")
            }

            if travel.role == .owner {
                Divider()

                Button(role: .destructive) {
                    viewModel.travelToDelete = travel
                    viewModel.showingDeleteAlert = true
                } label: {
                    Label("Delete Trip", systemImage: "trash")
                }
            }
        }
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.title2.bold())
            Text("(\(count))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal)
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

#Preview {
    NavigationStack {
        TravelsListView()
    }
    .environmentObject(AppState())
}
