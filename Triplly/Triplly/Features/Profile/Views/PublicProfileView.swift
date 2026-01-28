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
                VStack(spacing: 12) {
                    NetworkAvatarView(
                        name: profile.name,
                        imageUrl: profile.profilePhotoUrl,
                        size: 80
                    )

                    VStack(spacing: 4) {
                        Text(profile.name)
                            .font(.title2.bold())

                        if let username = profile.username {
                            Text("@\(username)")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.appPrimary)
                        }
                    }
                }
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
                                PublicTravelCard(travel: travel)
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
