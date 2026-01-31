import SwiftUI

struct PublicProfileView: View {
    @StateObject private var viewModel: PublicProfileViewModel

    init(username: String) {
        _viewModel = StateObject(wrappedValue: PublicProfileViewModel(username: username))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.error, viewModel.profile == nil {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Could not load profile")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task { await viewModel.loadProfile() }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else if let profile = viewModel.profile {
                profileContent(profile)
            }
        }
        .navigationTitle("@\(viewModel.username)")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadProfile()
        }
    }

    @ViewBuilder
    private func profileContent(_ profile: PublicProfile) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 16) {
                        NetworkAvatarView(
                            name: profile.name,
                            imageUrl: profile.profilePhotoUrl,
                            size: 124
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(profile.name)
                                .font(.system(size: 22, weight: .bold, design: .rounded))

                            if let username = profile.username {
                                Text("@\(username)")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }

                    // Awards inline
                    if let awards = profile.awards, !awards.isEmpty {
                        AwardsInlineRow(awards: awards)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)

                // Public Travels
                if profile.travels.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "airplane")
                            .font(.system(size: 40))
                            .foregroundStyle(.tertiary)
                        Text("No public trips yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Public Trips")
                            .font(.headline)
                            .padding(.horizontal)

                        LazyVStack(spacing: 12) {
                            ForEach(profile.travels) { travel in
                                NavigationLink(destination: PublicTravelDetailView(travelId: travel.id)) {
                                    PublicTravelCard(travel: travel)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Public Travel Card
struct PublicTravelCard: View {
    let travel: PublicTravel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover image
            if let coverUrl = travel.coverImageUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .frame(height: 140)
                .clipped()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(travel.title)
                    .font(.headline)

                if let description = travel.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if let dateRange = travel.formattedDateRange {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(dateRange)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }
}

// MARK: - Public Travel Detail View
struct PublicTravelDetailView: View {
    let travelId: String

    @State private var travel: Travel?
    @State private var isLoading = true
    @State private var error: Error?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = error, travel == nil {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Could not load travel")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task { await loadTravel() }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else if let travel {
                travelContent(travel)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadTravel()
        }
    }

    private func loadTravel() async {
        isLoading = true
        error = nil
        do {
            travel = try await APIClient.shared.getPublicTravelDetail(travelId: travelId)
        } catch {
            self.error = error
        }
        isLoading = false
    }

    @ViewBuilder
    private func travelContent(_ travel: Travel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Cover image
                if let coverUrl = travel.coverImageUrl, let url = URL(string: coverUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .overlay {
                                    Image(systemName: "photo")
                                        .foregroundStyle(.secondary)
                                }
                        }
                    }
                    .frame(height: 200)
                    .clipped()
                }

                VStack(alignment: .leading, spacing: 16) {
                    // Title & dates
                    VStack(alignment: .leading, spacing: 6) {
                        Text(travel.title)
                            .font(.system(size: 24, weight: .bold, design: .rounded))

                        if let dateRange = travel.formattedDateRange {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.subheadline)
                                Text(dateRange)
                                    .font(.subheadline)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }

                    if let description = travel.description, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    // Itineraries
                    if let itineraries = travel.itineraries, !itineraries.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(itineraries) { itinerary in
                                PublicItinerarySection(itinerary: itinerary)
                            }
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "list.bullet.clipboard")
                                .font(.system(size: 32))
                                .foregroundStyle(.tertiary)
                            Text("No itineraries yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    }
                }
                .padding(16)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(travel.title)
    }
}

// MARK: - Public Itinerary Section
private struct PublicItinerarySection: View {
    let itinerary: Itinerary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(itinerary.title)
                    .font(.headline)

                if let formattedDate = itinerary.formattedDate {
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let activities = itinerary.activities, !activities.isEmpty {
                VStack(spacing: 8) {
                    ForEach(activities) { activity in
                        PublicActivityRow(activity: activity)
                    }
                }
            } else {
                Text("No activities")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Public Activity Row
private struct PublicActivityRow: View {
    let activity: Activity

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(activity.title)
                .font(.subheadline)
                .fontWeight(.medium)

            if let description = activity.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 12) {
                if let time = activity.formattedTime {
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(time)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                if let address = activity.address, !address.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "mappin")
                            .font(.caption2)
                        Text(address)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

// MARK: - PublicTravel Date Helper
extension PublicTravel {
    var formattedDateRange: String? {
        guard let start = startDate else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let startParsed = formatter.date(from: start) else { return nil }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "d MMM"

        if let end = endDate, let endParsed = formatter.date(from: end) {
            return "\(displayFormatter.string(from: startParsed)) - \(displayFormatter.string(from: endParsed))"
        }

        return displayFormatter.string(from: startParsed)
    }
}
