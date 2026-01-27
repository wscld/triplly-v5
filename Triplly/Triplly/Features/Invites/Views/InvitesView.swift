import SwiftUI

struct InvitesView: View {
    @StateObject private var viewModel = InvitesViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.invites.isEmpty {
                ProgressView("Loading invites...")
            } else if viewModel.invites.isEmpty {
                emptyState
            } else {
                invitesList
            }
        }
        .navigationTitle("Invites")
        .task {
            await viewModel.loadInvites()
        }
        .refreshable {
            await viewModel.loadInvites()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.open")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)

            VStack(spacing: 4) {
                Text("No Pending Invites")
                    .font(.headline)
                Text("When someone invites you to a trip, it will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    private var invitesList: some View {
        List {
            ForEach(viewModel.invites) { invite in
                InviteCard(invite: invite) {
                    Task { await viewModel.acceptInvite(invite) }
                } onDecline: {
                    Task { await viewModel.rejectInvite(invite) }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Invite Card
struct InviteCard: View {
    let invite: TravelInvite
    let onAccept: () -> Void
    let onDecline: () -> Void

    @State private var isAccepting = false
    @State private var isDeclining = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with travel info
            HStack(alignment: .top, spacing: 12) {
                // Travel image placeholder
                TravelCoverImage(
                    coverUrl: invite.travel.coverImageUrl,
                    height: 70,
                    cornerRadius: 10
                )
                .frame(width: 70, height: 70)

                VStack(alignment: .leading, spacing: 4) {
                    Text(invite.travel.title)
                        .font(.headline)
                        .lineLimit(2)

                    if let dateRange = invite.travel.formattedDateRange {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(dateRange)
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "person")
                            .font(.caption2)
                        Text("By \(invite.travel.owner.name)")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Invite details
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "person.badge.plus")
                        .font(.caption)
                    Text("\(invite.invitedBy.name) invited you")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)

                Spacer()

                Text(invite.role.rawValue.capitalized)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.appPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.appPrimary.opacity(0.1))
                    .clipShape(Capsule())
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    isDeclining = true
                    onDecline()
                } label: {
                    HStack {
                        if isDeclining {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Text("Decline")
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray5))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(isAccepting || isDeclining)

                Button {
                    isAccepting = true
                    onAccept()
                } label: {
                    HStack {
                        if isAccepting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Accept")
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.appPrimary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(isAccepting || isDeclining)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack {
        InvitesView()
    }
}
