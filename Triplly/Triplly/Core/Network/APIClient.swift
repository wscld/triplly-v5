import Foundation

// MARK: - API Client
actor APIClient {
    static let shared = APIClient()

    #if DEBUG
    private let baseURL = "https://app.triplly.com/api"
    #else
    private let baseURL = "https://app.triplly.com/api"
    #endif

    private var token: String?
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        decoder = JSONDecoder()
        // Backend returns camelCase JSON, no conversion needed

        encoder = JSONEncoder()
        // Backend expects camelCase JSON, no conversion needed
    }

    // MARK: - Token Management
    func setToken(_ token: String) {
        self.token = token
    }

    func clearToken() {
        self.token = nil
    }

    // MARK: - Generic Request
    private func request<T: Decodable>(
        path: String,
        method: HTTPMethod = .get,
        body: (any Encodable)? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorString = String(data: data, encoding: .utf8) ?? "No response body"
            print("DEBUG: [\(method.rawValue)] \(path) - HTTP \(httpResponse.statusCode)")
            print("DEBUG: Response: \(errorString)")

            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                let error = NetworkError.serverError(errorResponse.error)
                await ErrorManager.shared.show(error)
                throw error
            }
            let error = NetworkError.httpError(httpResponse.statusCode)
            await ErrorManager.shared.show(error)
            throw error
        }

        if data.isEmpty || httpResponse.statusCode == 204 {
            print("DEBUG: [\(method.rawValue)] \(path) - Empty response body, expected \(T.self)")
            throw NetworkError.emptyResponse
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch let decodingError as DecodingError {
            print("DEBUG: [\(method.rawValue)] \(path) - Decoding error")
            print("DEBUG: Error: \(decodingError)")
            print("DEBUG: Response: \(String(data: data, encoding: .utf8) ?? "nil")")
            await ErrorManager.shared.show(decodingError)
            throw decodingError
        }
    }

    private func requestVoid(
        path: String,
        method: HTTPMethod = .get,
        body: (any Encodable)? = nil
    ) async throws {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorString = String(data: data, encoding: .utf8) ?? "No response body"
            print("DEBUG: [\(method.rawValue)] \(path) - HTTP \(httpResponse.statusCode)")
            print("DEBUG: Response: \(errorString)")

            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                let error = NetworkError.serverError(errorResponse.error)
                await ErrorManager.shared.show(error)
                throw error
            }
            let error = NetworkError.httpError(httpResponse.statusCode)
            await ErrorManager.shared.show(error)
            throw error
        }
    }

    // MARK: - Auth Endpoints
    func login(email: String, password: String) async throws -> AuthResponse {
        try await request(
            path: "/auth/login",
            method: .post,
            body: LoginRequest(email: email, password: password)
        )
    }

    func register(name: String, email: String, password: String) async throws -> AuthResponse {
        try await request(
            path: "/auth/register",
            method: .post,
            body: RegisterRequest(name: name, email: email, password: password)
        )
    }

    func getCurrentUser() async throws -> User {
        try await request(path: "/auth/me")
    }

    func appleSignIn(identityToken: String, name: String?) async throws -> AuthResponse {
        try await request(
            path: "/auth/apple",
            method: .post,
            body: AppleSignInRequest(identityToken: identityToken, name: name)
        )
    }

    func updateProfile(name: String? = nil, username: String? = nil) async throws -> User {
        try await request(
            path: "/auth/me",
            method: .patch,
            body: UpdateProfileRequest(name: name, username: username)
        )
    }

    func uploadProfilePhoto(imageData: Data) async throws -> User {
        guard let url = URL(string: "\(baseURL)/auth/me/photo") else {
            throw NetworkError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.uploadFailed
        }

        return try decoder.decode(User.self, from: data)
    }

    // MARK: - Travel Endpoints
    func getTravels() async throws -> [TravelListItem] {
        try await request(path: "/travels")
    }

    func getTravel(id: String) async throws -> Travel {
        try await request(path: "/travels/\(id)")
    }

    func createTravel(_ travel: CreateTravelRequest) async throws -> Travel {
        try await request(path: "/travels", method: .post, body: travel)
    }

    func updateTravel(id: String, _ update: UpdateTravelRequest) async throws -> Travel {
        try await request(path: "/travels/\(id)", method: .patch, body: update)
    }

    func deleteTravel(id: String) async throws {
        try await requestVoid(path: "/travels/\(id)", method: .delete)
    }

    func uploadCoverImage(travelId: String, imageData: Data) async throws -> Travel {
        guard let url = URL(string: "\(baseURL)/travels/\(travelId)/cover") else {
            throw NetworkError.invalidURL
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"cover.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.uploadFailed
        }

        return try decoder.decode(Travel.self, from: data)
    }

    // MARK: - Travel Members Endpoints
    func getTravelMembers(travelId: String) async throws -> [TravelMember] {
        try await request(path: "/travels/\(travelId)/members")
    }

    func inviteMember(travelId: String, email: String, role: TravelRole) async throws {
        try await requestVoid(
            path: "/travels/\(travelId)/members",
            method: .post,
            body: InviteMemberRequest(email: email, role: role)
        )
    }

    func updateMemberRole(travelId: String, memberId: String, role: TravelRole) async throws -> TravelMember {
        try await request(
            path: "/travels/\(travelId)/members/\(memberId)",
            method: .patch,
            body: ["role": role.rawValue]
        )
    }

    func removeMember(travelId: String, memberId: String) async throws {
        try await requestVoid(path: "/travels/\(travelId)/members/\(memberId)", method: .delete)
    }

    // MARK: - Invite Endpoints
    func getMyInvites() async throws -> [TravelInvite] {
        try await request(path: "/invites")
    }

    func acceptInvite(inviteId: String) async throws {
        try await requestVoid(path: "/invites/\(inviteId)/accept", method: .post)
    }

    func rejectInvite(inviteId: String) async throws {
        try await requestVoid(path: "/invites/\(inviteId)/reject", method: .post)
    }

    func getTravelInvites(travelId: String) async throws -> [PendingInvite] {
        try await request(path: "/travels/\(travelId)/invites")
    }

    func cancelInvite(travelId: String, inviteId: String) async throws {
        try await requestVoid(path: "/travels/\(travelId)/invites/\(inviteId)", method: .delete)
    }

    func leaveTravel(travelId: String) async throws {
        try await requestVoid(path: "/travels/\(travelId)/leave", method: .post)
    }

    // MARK: - Itinerary Endpoints
    func getItinerary(id: String) async throws -> Itinerary {
        try await request(path: "/itineraries/\(id)")
    }

    func createItinerary(_ itinerary: CreateItineraryRequest) async throws -> Itinerary {
        try await request(path: "/itineraries", method: .post, body: itinerary)
    }

    func updateItinerary(id: String, _ update: UpdateItineraryRequest) async throws -> Itinerary {
        try await request(path: "/itineraries/\(id)", method: .patch, body: update)
    }

    func deleteItinerary(id: String) async throws {
        try await requestVoid(path: "/itineraries/\(id)", method: .delete)
    }

    // MARK: - Activity Endpoints
    func getActivity(id: String) async throws -> Activity {
        try await request(path: "/activities/\(id)")
    }

    func createActivity(_ activity: CreateActivityRequest) async throws -> Activity {
        try await request(path: "/activities", method: .post, body: activity)
    }

    func updateActivity(id: String, _ update: UpdateActivityRequest) async throws -> Activity {
        try await request(path: "/activities/\(id)", method: .patch, body: update)
    }

    func deleteActivity(id: String) async throws {
        try await requestVoid(path: "/activities/\(id)", method: .delete)
    }

    func reorderActivity(activityId: String, afterActivityId: String?, beforeActivityId: String?) async throws {
        let requestBody = ReorderActivityRequest(
            activityId: activityId,
            afterActivityId: afterActivityId,
            beforeActivityId: beforeActivityId
        )
        if let jsonData = try? JSONEncoder().encode(requestBody),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("DEBUG: reorderActivity request body: \(jsonString)")
        }
        try await requestVoid(
            path: "/activities/reorder",
            method: .patch,
            body: requestBody
        )
    }

    func getWishlistActivities(travelId: String) async throws -> [Activity] {
        try await request(path: "/activities/travel/\(travelId)/wishlist")
    }

    func assignActivityToItinerary(activityId: String, itineraryId: String?) async throws -> Activity {
        try await request(
            path: "/activities/\(activityId)/assign",
            method: .patch,
            body: AssignActivityRequest(itineraryId: itineraryId)
        )
    }

    // MARK: - Category Endpoints
    func getCategories(travelId: String) async throws -> [CategoryModel] {
        try await request(path: "/categories/travel/\(travelId)")
    }

    func createCategory(travelId: String, name: String, icon: String, color: String) async throws -> CategoryModel {
        try await request(
            path: "/categories/travel/\(travelId)",
            method: .post,
            body: CreateCategoryRequest(name: name, icon: icon, color: color)
        )
    }

    func deleteCategory(categoryId: String) async throws {
        try await requestVoid(path: "/categories/\(categoryId)", method: .delete)
    }

    // MARK: - Comment Endpoints
    func getActivityComments(activityId: String) async throws -> [ActivityComment] {
        try await request(path: "/comments/activity/\(activityId)")
    }

    func createComment(activityId: String, content: String) async throws -> ActivityComment {
        try await request(
            path: "/comments/activity/\(activityId)",
            method: .post,
            body: CreateCommentRequest(content: content)
        )
    }

    func deleteComment(commentId: String) async throws {
        try await requestVoid(path: "/comments/\(commentId)", method: .delete)
    }

    // MARK: - Todo Endpoints
    func getTodos(travelId: String) async throws -> [Todo] {
        try await request(path: "/todos?travelId=\(travelId)")
    }

    func createTodo(_ todo: CreateTodoRequest) async throws -> Todo {
        try await request(path: "/todos", method: .post, body: todo)
    }

    func updateTodo(id: String, _ update: UpdateTodoRequest) async throws -> Todo {
        try await request(path: "/todos/\(id)", method: .patch, body: update)
    }

    func deleteTodo(id: String) async throws {
        try await requestVoid(path: "/todos/\(id)", method: .delete)
    }

    // MARK: - Check-in Endpoints
    func checkIn(activityId: String) async throws -> CheckIn {
        try await request(
            path: "/checkins",
            method: .post,
            body: CreateCheckInRequest(activityId: activityId)
        )
    }

    func getActivityCheckIns(activityId: String) async throws -> [CheckIn] {
        try await request(path: "/checkins/activity/\(activityId)")
    }

    func getMyCheckIns() async throws -> [CheckIn] {
        try await request(path: "/checkins/me")
    }

    func deleteCheckIn(id: String) async throws {
        try await requestVoid(path: "/checkins/\(id)", method: .delete)
    }

    // MARK: - Place Endpoints
    func searchPlaces(query: String) async throws -> [PlaceResult] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let results: [PlaceSearchResult] = try await request(path: "/places/search?q=\(encodedQuery)")
        return results.map { r in
            PlaceResult(
                id: r.externalId,
                name: r.name,
                address: r.address,
                latitude: r.latitude,
                longitude: r.longitude,
                externalId: r.externalId,
                provider: r.provider,
                category: nil
            )
        }
    }

    func lookupPlace(externalId: String, provider: String, name: String, latitude: Double, longitude: Double) async throws -> PlaceLookupResponse {
        let encodedId = externalId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? externalId
        let encodedProvider = provider.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? provider
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        return try await request(path: "/places/lookup?externalId=\(encodedId)&provider=\(encodedProvider)&name=\(encodedName)&latitude=\(latitude)&longitude=\(longitude)")
    }

    func getPlace(id: String) async throws -> Place {
        try await request(path: "/places/\(id)")
    }

    func getPlaceCheckIns(placeId: String, limit: Int = 20, offset: Int = 0) async throws -> PaginatedCheckIns {
        try await request(path: "/places/\(placeId)/checkins?limit=\(limit)&offset=\(offset)")
    }

    func getPlaceReviews(placeId: String, limit: Int = 20, offset: Int = 0) async throws -> PaginatedReviews {
        try await request(path: "/places/\(placeId)/reviews?limit=\(limit)&offset=\(offset)")
    }

    // MARK: - Review Endpoints
    func createReview(placeId: String, rating: Int, content: String) async throws -> PlaceReview {
        try await request(
            path: "/reviews",
            method: .post,
            body: CreateReviewRequest(placeId: placeId, rating: rating, content: content)
        )
    }

    func deleteReview(reviewId: String) async throws {
        try await requestVoid(path: "/reviews/\(reviewId)", method: .delete)
    }

    // MARK: - Companion Endpoints
    func sendCompanionMessage(message: String, history: [[String: String]]?) async throws -> CompanionResponse {
        try await request(
            path: "/companion/chat",
            method: .post,
            body: CompanionRequest(message: message, conversationHistory: history)
        )
    }

    // MARK: - Public Profile Endpoints
    func getPublicProfile(username: String) async throws -> PublicProfile {
        try await request(path: "/public/users/\(username)")
    }

    func getPublicTravelDetail(travelId: String) async throws -> Travel {
        try await request(path: "/public/travels/\(travelId)")
    }

    func checkUsernameAvailability(_ username: String) async throws -> UsernameAvailability {
        try await request(path: "/public/users/\(username)/available")
    }
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - Request DTOs
private struct LoginRequest: Codable {
    let email: String
    let password: String
}

private struct RegisterRequest: Codable {
    let name: String
    let email: String
    let password: String
}

private struct ErrorResponse: Codable {
    let error: String
}

private struct UpdateProfileRequest: Codable {
    let name: String?
    let username: String?
}

private struct AppleSignInRequest: Codable {
    let identityToken: String
    let name: String?
}

private struct PlaceSearchResult: Codable {
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let externalId: String
    let provider: String
}

struct PlaceLookupResponse: Codable {
    let place: Place?
    let checkIns: [CheckIn]
    let totalCheckIns: Int?
    let reviews: [PlaceReview]
    let totalReviews: Int?
}

struct PaginatedCheckIns: Codable {
    let data: [CheckIn]
    let total: Int
    let limit: Int
    let offset: Int
}

struct PaginatedReviews: Codable {
    let data: [PlaceReview]
    let total: Int
    let limit: Int
    let offset: Int
}

private struct CreateCategoryRequest: Codable {
    let name: String
    let icon: String
    let color: String
}
