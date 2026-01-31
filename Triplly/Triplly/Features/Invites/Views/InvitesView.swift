import SwiftUI
import Himetrica

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
        .trackScreen("Invites")
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

    @State private var inviteToAccept: TravelInvite?
    @State private var inviteToDecline: TravelInvite?

    private var invitesList: some View {
        List {
            ForEach(viewModel.invites) { invite in
                InviteCard(invite: invite) {
                    inviteToAccept = invite
                } onDecline: {
                    inviteToDecline = invite
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
        .alert("Accept Invite", isPresented: Binding(
            get: { inviteToAccept != nil },
            set: { if !$0 { inviteToAccept = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                inviteToAccept = nil
            }
            Button("Accept") {
                if let invite = inviteToAccept {
                    Task { await viewModel.acceptInvite(invite) }
                    inviteToAccept = nil
                }
            }
        } message: {
            if let invite = inviteToAccept {
                Text("Join \"\(invite.travel.title)\" as \(invite.role.rawValue)?")
            }
        }
        .alert("Decline Invite", isPresented: Binding(
            get: { inviteToDecline != nil },
            set: { if !$0 { inviteToDecline = nil } }
        )) {
            Button("Keep", role: .cancel) {
                inviteToDecline = nil
            }
            Button("Decline", role: .destructive) {
                if let invite = inviteToDecline {
                    Task { await viewModel.rejectInvite(invite) }
                    inviteToDecline = nil
                }
            }
        } message: {
            if let invite = inviteToDecline {
                Text("Are you sure you want to decline the invite to \"\(invite.travel.title)\"?")
            }
        }
    }
}

// MARK: - Invite Card
struct InviteCard: View {
    let invite: TravelInvite
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Full-width cover image
            TravelCoverImage(coverUrl: invite.travel.coverImageUrl, height: 160, cornerRadius: 0)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 20))

            VStack(alignment: .leading, spacing: 12) {
                // Title and role badge
                HStack {
                    Text(invite.travel.title)
                        .font(.system(size: 18, weight: .semibold))
                        .lineLimit(1)

                    Spacer()

                    Text(invite.role.rawValue.capitalized)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.appPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.appPrimary.opacity(0.12))
                        .clipShape(Capsule())
                }

                // Date range
                if let dateRange = invite.travel.formattedDateRange {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(dateRange)
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                }

                // Invited by
                HStack(spacing: 6) {
                    Image(systemName: "person.badge.plus")
                        .font(.caption)
                    Text("\(invite.invitedBy.name) invited you")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)

                // Action buttons
                HStack(spacing: 12) {
                    Button {
                        onDecline()
                    } label: {
                        Text("Decline")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        onAccept()
                    } label: {
                        Text("Accept")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.appPrimary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.top, 4)
            }
            .padding(18)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
    }
}

#Preview {
    NavigationStack {
        InvitesView()
    }
}
