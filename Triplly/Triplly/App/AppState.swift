import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var currentUser: User?
    @Published var error: AppError?

    // MARK: - Dependencies
    private let apiClient: APIClient
    private let keychainManager: KeychainManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(
        apiClient: APIClient = .shared,
        keychainManager: KeychainManager = .shared
    ) {
        self.apiClient = apiClient
        self.keychainManager = keychainManager

        Task {
            await checkAuthStatus()
        }
    }

    // MARK: - Authentication Methods
    func checkAuthStatus() async {
        isLoading = true
        defer { isLoading = false }

        guard let token = keychainManager.getToken() else {
            isAuthenticated = false
            return
        }

        await apiClient.setToken(token)

        do {
            let user = try await apiClient.getCurrentUser()
            self.currentUser = user
            self.isAuthenticated = true
        } catch {
            // Token is invalid, clear it
            keychainManager.deleteToken()
            await apiClient.clearToken()
            isAuthenticated = false
        }
    }

    func login(email: String, password: String) async throws {
        let response = try await apiClient.login(email: email, password: password)

        keychainManager.saveToken(response.token)
        await apiClient.setToken(response.token)

        currentUser = response.user
        isAuthenticated = true
    }

    func register(name: String, email: String, password: String) async throws {
        let response = try await apiClient.register(name: name, email: email, password: password)

        keychainManager.saveToken(response.token)
        await apiClient.setToken(response.token)

        currentUser = response.user
        isAuthenticated = true
    }

    func logout() {
        keychainManager.deleteToken()
        Task {
            await apiClient.clearToken()
        }
        currentUser = nil
        isAuthenticated = false
    }

    func updateUser(_ user: User) {
        currentUser = user
    }
}

// MARK: - App Error
enum AppError: LocalizedError, Identifiable {
    case network(String)
    case authentication(String)
    case validation(String)
    case unknown(String)

    var id: String { localizedDescription }

    var errorDescription: String? {
        switch self {
        case .network(let message): return message
        case .authentication(let message): return message
        case .validation(let message): return message
        case .unknown(let message): return message
        }
    }
}
