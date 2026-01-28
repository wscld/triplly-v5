import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var currentUser: User?
    @Published var error: AppError?

    // MARK: - Subscription Properties
    @Published var isSubscribed = false
    @Published var showPaywall = false
    @Published var travelsCount = 0

    // MARK: - Onboarding Properties
    @Published var hasCompletedOnboarding = false
    @Published var showOnboarding = false

    // MARK: - Global Map Sheet
    @Published var showMapSheet = false
    @Published var mapSheetActivities: [Activity] = []
    @Published var mapSheetTitle: String?
    @Published var mapSheetDetent: PresentationDetent = .height(140)
    @Published var mapSheetOffset: CGFloat = 0

    // MARK: - Deep Link
    @Published var deepLinkUsername: String?

    // MARK: - Nested Sheet (shown on top of map sheet)
    @Published var mapNestedSheet: MapNestedSheet?

    // Store reference to current travel detail view model for nested sheets
    weak var currentTravelDetailViewModel: TravelDetailViewModel?

    // MARK: - Constants
    private let freeTravelLimit = 1
    private let onboardingKey = "hasCompletedOnboarding"
    private let subscriptionKey = "isSubscribed"

    // MARK: - Dependencies
    private let apiClient: APIClient
    private let keychainManager: KeychainManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var canCreateTravel: Bool {
        isSubscribed || travelsCount < freeTravelLimit
    }

    // MARK: - Initialization
    init(
        apiClient: APIClient = .shared,
        keychainManager: KeychainManager = .shared
    ) {
        self.apiClient = apiClient
        self.keychainManager = keychainManager

        // Check onboarding status
        hasCompletedOnboarding = keychainManager.get(key: onboardingKey) == "true"

        // Check subscription status (in a real app, this would verify with StoreKit/RevenueCat)
        isSubscribed = keychainManager.get(key: subscriptionKey) == "true"

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

            // Show onboarding if first time after authentication
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
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

    func appleSignIn(identityToken: String, name: String?) async throws {
        let response = try await apiClient.appleSignIn(identityToken: identityToken, name: name)

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

    // MARK: - Subscription Methods
    func updateTravelsCount(_ count: Int) {
        travelsCount = count
    }

    func checkPaywallNeeded() -> Bool {
        if isSubscribed {
            return false
        }
        if travelsCount >= freeTravelLimit {
            showPaywall = true
            return true
        }
        return false
    }

    func purchaseSubscription() {
        // In a real app, this would integrate with StoreKit 2 or RevenueCat
        // For now, we'll just mark as subscribed
        isSubscribed = true
        keychainManager.save("true", forKey: subscriptionKey)
        showPaywall = false
    }

    func restorePurchases() {
        // In a real app, this would restore purchases from StoreKit/RevenueCat
        // For now, we'll check if previously subscribed
        if keychainManager.get(key: subscriptionKey) == "true" {
            isSubscribed = true
        }
    }

    // MARK: - Onboarding Methods
    func completeOnboarding() {
        hasCompletedOnboarding = true
        keychainManager.save("true", forKey: onboardingKey)
        showOnboarding = false
    }

    // MARK: - Map Sheet Methods
    func showMap(activities: [Activity], title: String?) {
        mapSheetActivities = activities
        mapSheetTitle = title
        mapSheetDetent = .height(140)
        mapSheetOffset = 0
        withAnimation(.easeOut(duration: 0.3)) {
            showMapSheet = true
        }
    }

    func updateMapActivities(_ activities: [Activity], title: String?) {
        mapSheetActivities = activities
        mapSheetTitle = title
    }

    func hideMapSheet() {
        showMapSheet = false
        mapSheetOffset = 0
        mapSheetDetent = .height(140)
        mapNestedSheet = nil
        currentTravelDetailViewModel = nil
    }

    // MARK: - Nested Sheet Methods
    func showNestedSheet(_ sheet: MapNestedSheet) {
        mapNestedSheet = sheet
    }

    func dismissNestedSheet() {
        mapNestedSheet = nil
    }

    // MARK: - Deep Link Methods
    func navigateToPublicProfile(username: String) {
        deepLinkUsername = username
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

// MARK: - Map Nested Sheet
enum MapNestedSheet: Identifiable, Equatable {
    case editTravel
    case members
    case todos
    case wishlist
    case addDay
    case addActivity
    case activityDetail(Activity)
    case editItinerary(Itinerary)

    var id: String {
        switch self {
        case .editTravel: return "editTravel"
        case .members: return "members"
        case .todos: return "todos"
        case .wishlist: return "wishlist"
        case .addDay: return "addDay"
        case .addActivity: return "addActivity"
        case .activityDetail(let activity): return "activityDetail-\(activity.id)"
        case .editItinerary(let itinerary): return "editItinerary-\(itinerary.id)"
        }
    }

    static func == (lhs: MapNestedSheet, rhs: MapNestedSheet) -> Bool {
        lhs.id == rhs.id
    }
}
