import SwiftUI
import Combine

@MainActor
final class TravelsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var travels: [TravelListItem] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: Error?
    @Published var searchText = ""

    // MARK: - Sheet State
    @Published var showingCreateSheet = false
    @Published var isCreating = false
    @Published var createError: String?

    // MARK: - Delete State
    @Published var showingDeleteAlert = false
    @Published var travelToDelete: TravelListItem?

    // MARK: - Create Form
    @Published var newTravelTitle = ""
    @Published var newTravelDescription = ""
    @Published var newTravelStartDate: Date?
    @Published var newTravelEndDate: Date?
    @Published var selectedLocation: PlaceResult?
    @Published var showingLocationSearch = false

    // MARK: - Dependencies
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    // MARK: - Computed Properties
    var upcomingTravels: [TravelListItem] {
        let filtered = searchText.isEmpty ? travels : travels.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
        return filtered.filter { $0.isUpcoming }
    }

    var pastTravels: [TravelListItem] {
        let filtered = searchText.isEmpty ? travels : travels.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
        return filtered.filter { !$0.isUpcoming }
    }

    var totalTrips: Int { travels.count }
    var upcomingCount: Int { travels.filter { $0.isUpcoming }.count }
    var pastCount: Int { travels.filter { !$0.isUpcoming }.count }

    // MARK: - App State Reference
    weak var appState: AppState?

    // MARK: - Actions
    func loadTravels() async {
        isLoading = true
        error = nil

        do {
            travels = try await apiClient.getTravels()
            // Update travels count in AppState for paywall logic
            // Only count travels where user is owner (they created it)
            let ownedTravels = travels.filter { $0.role == .owner }.count
            await MainActor.run {
                appState?.updateTravelsCount(ownedTravels)
            }
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func refreshTravels() async {
        isRefreshing = true

        do {
            travels = try await apiClient.getTravels()
        } catch {
            // Silent fail on refresh
        }

        isRefreshing = false
    }

    func createTravel() async {
        guard !newTravelTitle.isEmpty else {
            createError = "Please enter a title"
            return
        }

        // Check if paywall is needed
        if let appState = appState, appState.checkPaywallNeeded() {
            showingCreateSheet = false
            return
        }

        isCreating = true
        createError = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let request = CreateTravelRequest(
            title: newTravelTitle,
            description: newTravelDescription.isEmpty ? nil : newTravelDescription,
            startDate: newTravelStartDate.map { formatter.string(from: $0) },
            endDate: newTravelEndDate.map { formatter.string(from: $0) },
            latitude: selectedLocation?.latitude,
            longitude: selectedLocation?.longitude
        )

        do {
            let newTravel = try await apiClient.createTravel(request)

            // Convert to TravelListItem (owner role)
            let listItem = TravelListItem(
                id: newTravel.id,
                title: newTravel.title,
                description: newTravel.description,
                startDate: newTravel.startDate,
                endDate: newTravel.endDate,
                coverImageUrl: newTravel.coverImageUrl,
                latitude: newTravel.latitude,
                longitude: newTravel.longitude,
                ownerId: newTravel.ownerId,
                owner: newTravel.owner,
                createdAt: newTravel.createdAt,
                role: .owner,
                itineraries: newTravel.itineraries
            )

            travels.insert(listItem, at: 0)

            // Update travels count in AppState
            let ownedTravels = travels.filter { $0.role == .owner }.count
            appState?.updateTravelsCount(ownedTravels)

            resetCreateForm()
            showingCreateSheet = false
        } catch {
            createError = error.localizedDescription
        }

        isCreating = false
    }

    func deleteTravel(_ travel: TravelListItem) async {
        do {
            try await apiClient.deleteTravel(id: travel.id)
            travels.removeAll { $0.id == travel.id }
            travelToDelete = nil
        } catch {
            self.error = error
            travelToDelete = nil
        }
    }

    func resetCreateForm() {
        newTravelTitle = ""
        newTravelDescription = ""
        newTravelStartDate = nil
        newTravelEndDate = nil
        selectedLocation = nil
        createError = nil
    }
}
