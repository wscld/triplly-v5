import SwiftUI
import Combine
import MapKit

@MainActor
final class TravelDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var travel: Travel?
    @Published var members: [TravelMember] = []
    @Published var todos: [Todo] = []
    @Published var wishlistActivities: [Activity] = []

    @Published var isLoading = false
    @Published var error: Error?

    @Published var selectedItineraryIndex = 0
    @Published var isMapExpanded = false

    // MARK: - Sheet State
    @Published var showingEditSheet = false
    @Published var showingMembersSheet = false
    @Published var showingTodosSheet = false
    @Published var showingWishlistSheet = false
    @Published var showingAddActivitySheet = false
    @Published var showingAddDaySheet = false

    // MARK: - Edit State
    @Published var isUpdating = false
    @Published var editTitle = ""
    @Published var editDescription = ""
    @Published var editStartDate: Date?
    @Published var editEndDate: Date?

    // MARK: - Add Day State
    @Published var isCreatingDay = false
    @Published var newDayTitle = ""
    @Published var newDayDate: Date?

    // MARK: - Dependencies
    private let apiClient: APIClient
    let travelId: String

    init(travelId: String, apiClient: APIClient = .shared) {
        self.travelId = travelId
        self.apiClient = apiClient
    }

    // MARK: - Computed Properties
    var itineraries: [Itinerary] {
        travel?.itineraries ?? []
    }

    var selectedItinerary: Itinerary? {
        guard selectedItineraryIndex < itineraries.count else { return nil }
        return itineraries[selectedItineraryIndex]
    }

    var selectedActivities: [Activity] {
        selectedItinerary?.activities ?? []
    }

    var selectedActivitiesBinding: Binding<[Activity]> {
        Binding(
            get: { self.selectedActivities },
            set: { newActivities in
                guard var updatedTravel = self.travel,
                      let itineraryIndex = updatedTravel.itineraries?.firstIndex(where: { $0.id == self.selectedItinerary?.id }) else {
                    print("DEBUG: Failed to get travel or itinerary index for binding update")
                    return
                }
                updatedTravel.itineraries?[itineraryIndex].activities = newActivities
                self.travel = updatedTravel
                print("DEBUG: Updated activities order locally: \(newActivities.map { $0.title })")
            }
        )
    }

    var mapRegion: MKCoordinateRegion {
        if let activity = selectedActivities.first {
            return MKCoordinateRegion(
                center: activity.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        } else if let lat = travel?.latitudeDouble, let lng = travel?.longitudeDouble {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    }

    var todoProgress: Double {
        guard !todos.isEmpty else { return 0 }
        let completed = todos.filter { $0.isCompleted }.count
        return Double(completed) / Double(todos.count)
    }

    func isCurrentUserOwner(currentUserId: String?) -> Bool {
        guard let userId = currentUserId, let travel = travel else { return false }
        return travel.owner.id == userId
    }

    // MARK: - Load Data
    func loadTravel() async {
        isLoading = true
        error = nil

        // First, load the travel - this is required
        do {
            let fetchedTravel = try await apiClient.getTravel(id: travelId)
            travel = fetchedTravel

            // Initialize edit form
            editTitle = fetchedTravel.title
            editDescription = fetchedTravel.description ?? ""

            if let startStr = fetchedTravel.startDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                editStartDate = formatter.date(from: startStr)
            }
            if let endStr = fetchedTravel.endDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                editEndDate = formatter.date(from: endStr)
            }
        } catch {
            print("DEBUG: Failed to load travel: \(error)")
            self.error = error
            isLoading = false
            return
        }

        // Then load secondary data - failures here shouldn't block the view
        async let membersTask: () = loadMembers()
        async let todosTask: () = loadTodos()
        async let wishlistTask: () = loadWishlist()

        _ = await (membersTask, todosTask, wishlistTask)

        isLoading = false
    }

    private func loadMembers() async {
        do {
            members = try await apiClient.getTravelMembers(travelId: travelId)
        } catch {
            print("DEBUG: Failed to load members: \(error)")
        }
    }

    private func loadTodos() async {
        do {
            todos = try await apiClient.getTodos(travelId: travelId)
        } catch {
            print("DEBUG: Failed to load todos: \(error)")
        }
    }

    private func loadWishlist() async {
        do {
            wishlistActivities = try await apiClient.getWishlistActivities(travelId: travelId)
        } catch {
            print("DEBUG: Failed to load wishlist: \(error)")
        }
    }

    func refreshTravel() async {
        do {
            travel = try await apiClient.getTravel(id: travelId)
        } catch {
            // Silent fail
        }
    }

    // MARK: - Update Travel
    func updateTravel() async {
        isUpdating = true

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let request = UpdateTravelRequest(
            title: editTitle,
            description: editDescription.isEmpty ? nil : editDescription,
            startDate: editStartDate.map { formatter.string(from: $0) },
            endDate: editEndDate.map { formatter.string(from: $0) },
            latitude: travel?.latitudeDouble,
            longitude: travel?.longitudeDouble
        )

        do {
            travel = try await apiClient.updateTravel(id: travelId, request)
            showingEditSheet = false
        } catch {
            self.error = error
        }

        isUpdating = false
    }

    // MARK: - Itinerary Actions
    func createDay() async {
        guard !newDayTitle.isEmpty else { return }

        isCreatingDay = true

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let request = CreateItineraryRequest(
            travelId: travelId,
            title: newDayTitle,
            date: newDayDate.map { formatter.string(from: $0) }
        )

        do {
            let newItinerary = try await apiClient.createItinerary(request)

            // Update local state
            if var updatedTravel = travel {
                var itineraries = updatedTravel.itineraries ?? []
                itineraries.append(newItinerary)
                updatedTravel.itineraries = itineraries
                travel = updatedTravel
            }

            newDayTitle = ""
            newDayDate = nil
            showingAddDaySheet = false

            // Select the new day
            if let count = travel?.itineraries?.count, count > 0 {
                selectedItineraryIndex = count - 1
            }
        } catch {
            self.error = error
        }

        isCreatingDay = false
    }

    func deleteItinerary(_ itinerary: Itinerary) async {
        do {
            try await apiClient.deleteItinerary(id: itinerary.id)

            // Update local state
            if var updatedTravel = travel {
                updatedTravel.itineraries?.removeAll { $0.id == itinerary.id }
                travel = updatedTravel
            }

            // Adjust selection
            if selectedItineraryIndex >= itineraries.count && !itineraries.isEmpty {
                selectedItineraryIndex = itineraries.count - 1
            }
        } catch {
            self.error = error
        }
    }

    func updateItinerary(id: String, title: String, date: String) async {
        let request = UpdateItineraryRequest(title: title, date: date)

        do {
            let updated = try await apiClient.updateItinerary(id: id, request)

            // Update local state
            if var updatedTravel = travel {
                if let index = updatedTravel.itineraries?.firstIndex(where: { $0.id == id }) {
                    // Preserve activities
                    let activities = updatedTravel.itineraries?[index].activities
                    var newItinerary = updated
                    newItinerary.activities = activities
                    updatedTravel.itineraries?[index] = newItinerary
                    travel = updatedTravel
                }
            }
        } catch {
            self.error = error
        }
    }

    // MARK: - Activity Actions
    func deleteActivity(_ activity: Activity) async {
        do {
            try await apiClient.deleteActivity(id: activity.id)

            // Update local state
            if var updatedTravel = travel {
                for (index, var itinerary) in (updatedTravel.itineraries ?? []).enumerated() {
                    itinerary.activities?.removeAll { $0.id == activity.id }
                    updatedTravel.itineraries?[index] = itinerary
                }
                travel = updatedTravel
            }

            wishlistActivities.removeAll { $0.id == activity.id }
        } catch {
            self.error = error
        }
    }

    func moveActivityToWishlist(_ activity: Activity) async {
        do {
            let updated = try await apiClient.assignActivityToItinerary(activityId: activity.id, itineraryId: nil)

            // Remove from itinerary
            if var updatedTravel = travel {
                for (index, var itinerary) in (updatedTravel.itineraries ?? []).enumerated() {
                    itinerary.activities?.removeAll { $0.id == activity.id }
                    updatedTravel.itineraries?[index] = itinerary
                }
                travel = updatedTravel
            }

            // Add to wishlist
            wishlistActivities.append(updated)
        } catch {
            self.error = error
        }
    }

    func assignActivityToDay(_ activity: Activity, itineraryId: String) async {
        do {
            let updated = try await apiClient.assignActivityToItinerary(activityId: activity.id, itineraryId: itineraryId)

            // Remove from wishlist
            wishlistActivities.removeAll { $0.id == activity.id }

            // Add to itinerary
            if var updatedTravel = travel {
                if let index = updatedTravel.itineraries?.firstIndex(where: { $0.id == itineraryId }) {
                    var itinerary = updatedTravel.itineraries![index]
                    var activities = itinerary.activities ?? []
                    activities.append(updated)
                    itinerary.activities = activities
                    updatedTravel.itineraries![index] = itinerary
                    travel = updatedTravel
                }
            }
        } catch {
            self.error = error
        }
    }

    func saveActivityReorder(activity: Activity, newIndex: Int) async {
        let activities = selectedActivities

        // Calculate afterActivityId and beforeActivityId based on new position
        let afterActivityId: String? = newIndex > 0 ? activities[newIndex - 1].id : nil
        let beforeActivityId: String? = newIndex < activities.count - 1 ? activities[newIndex + 1].id : nil

        print("DEBUG: saveActivityReorder - activity '\(activity.title)' at index \(newIndex)")
        print("DEBUG: afterActivityId: \(afterActivityId ?? "nil")")
        print("DEBUG: beforeActivityId: \(beforeActivityId ?? "nil")")

        do {
            try await apiClient.reorderActivity(
                activityId: activity.id,
                afterActivityId: afterActivityId,
                beforeActivityId: beforeActivityId
            )
            print("DEBUG: saveActivityReorder - API call succeeded")
        } catch {
            print("DEBUG: Failed to save activity reorder: \(error)")
            // Rollback on error - refetch travel
            await refreshTravel()
        }
    }

    // MARK: - Todo Actions
    func createTodo(_ title: String) async {
        let request = CreateTodoRequest(travelId: travelId, title: title)

        do {
            let newTodo = try await apiClient.createTodo(request)
            todos.append(newTodo)
        } catch {
            self.error = error
        }
    }

    func toggleTodo(_ todo: Todo) async {
        let request = UpdateTodoRequest(title: nil, isCompleted: !todo.isCompleted)

        // Optimistic update
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isCompleted.toggle()
        }

        do {
            let updated = try await apiClient.updateTodo(id: todo.id, request)
            if let index = todos.firstIndex(where: { $0.id == todo.id }) {
                todos[index] = updated
            }
        } catch {
            // Rollback
            if let index = todos.firstIndex(where: { $0.id == todo.id }) {
                todos[index].isCompleted.toggle()
            }
        }
    }

    func deleteTodo(_ todo: Todo) async {
        // Optimistic update
        let backup = todos
        todos.removeAll { $0.id == todo.id }

        do {
            try await apiClient.deleteTodo(id: todo.id)
        } catch {
            // Rollback
            todos = backup
        }
    }

    // MARK: - Member Actions
    func sendInvite(email: String, role: TravelRole) async throws {
        _ = try await apiClient.inviteMember(travelId: travelId, email: email, role: role)
        // Note: inviteMember now creates an invite, not a member directly
        // The member will be added when the invite is accepted
    }

    func removeMember(_ member: TravelMember) async {
        do {
            try await apiClient.removeMember(travelId: travelId, memberId: member.id)
            members.removeAll { $0.id == member.id }
        } catch {
            self.error = error
        }
    }

    func deleteTravel() async {
        do {
            try await apiClient.deleteTravel(id: travelId)
        } catch {
            self.error = error
        }
    }

    func leaveTravel() async {
        do {
            try await apiClient.leaveTravel(travelId: travelId)
        } catch {
            self.error = error
        }
    }
}
