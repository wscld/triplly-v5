import Foundation
import Combine

@MainActor
final class PublicProfileViewModel: ObservableObject {
    @Published var profile: PublicProfile?
    @Published var isLoading = true
    @Published var error: Error?

    private let apiClient: APIClient
    let username: String

    init(username: String, apiClient: APIClient = .shared) {
        self.username = username
        self.apiClient = apiClient
    }

    func loadProfile() async {
        isLoading = true
        error = nil

        do {
            profile = try await apiClient.getPublicProfile(username: username)
        } catch {
            self.error = error
        }

        isLoading = false
    }
}
