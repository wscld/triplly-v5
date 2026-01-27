import SwiftUI

@MainActor
final class InvitesViewModel: ObservableObject {
    @Published var invites: [TravelInvite] = []
    @Published var isLoading = false
    @Published var error: Error?

    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func loadInvites() async {
        isLoading = true
        error = nil

        do {
            invites = try await apiClient.getMyInvites()
        } catch {
            self.error = error
            print("DEBUG: Failed to load invites: \(error)")
        }

        isLoading = false
    }

    func acceptInvite(_ invite: TravelInvite) async {
        do {
            try await apiClient.acceptInvite(inviteId: invite.id)
            invites.removeAll { $0.id == invite.id }
        } catch {
            self.error = error
            print("DEBUG: Failed to accept invite: \(error)")
        }
    }

    func rejectInvite(_ invite: TravelInvite) async {
        do {
            try await apiClient.rejectInvite(inviteId: invite.id)
            invites.removeAll { $0.id == invite.id }
        } catch {
            self.error = error
            print("DEBUG: Failed to reject invite: \(error)")
        }
    }
}
