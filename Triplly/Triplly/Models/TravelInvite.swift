import Foundation

// MARK: - Invite Status
enum InviteStatus: String, Codable, Sendable {
    case pending
    case accepted
    case rejected
}

// MARK: - Travel Invite (for user's pending invites)
struct TravelInvite: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let role: TravelRole
    let status: InviteStatus
    let createdAt: String
    let travel: InviteTravelInfo
    let invitedBy: InviteUserInfo
}

struct InviteTravelInfo: Codable, Equatable, Sendable {
    let id: String
    let title: String
    let description: String?
    let startDate: String?
    let endDate: String?
    let coverImageUrl: String?
    let owner: InviteOwnerInfo
}

struct InviteOwnerInfo: Codable, Equatable, Sendable {
    let id: String
    let name: String
}

struct InviteUserInfo: Codable, Equatable, Sendable {
    let id: String
    let name: String
    let email: String
}

// MARK: - Pending Invite (for travel's pending invites)
struct PendingInvite: Codable, Identifiable, Equatable, Sendable {
    let id: String
    let role: TravelRole
    let status: InviteStatus
    let createdAt: String
    let user: MemberUser
}

// MARK: - Helper Extensions
extension TravelInvite {
    var formattedDate: String? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: createdAt) else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: createdAt) else { return nil }
            return formatRelativeDate(date)
        }

        return formatRelativeDate(date)
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

extension InviteTravelInfo {
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

// MARK: - Preview Data
extension TravelInvite {
    static let preview = TravelInvite(
        id: "1",
        role: .editor,
        status: .pending,
        createdAt: ISO8601DateFormatter().string(from: Date()),
        travel: InviteTravelInfo(
            id: "1",
            title: "Tokyo Adventure",
            description: "Exploring Japan's capital",
            startDate: "2025-03-15",
            endDate: "2025-03-22",
            coverImageUrl: nil,
            owner: InviteOwnerInfo(id: "2", name: "Jane Doe")
        ),
        invitedBy: InviteUserInfo(
            id: "2",
            name: "Jane Doe",
            email: "jane@example.com"
        )
    )
}

extension PendingInvite {
    static let preview = PendingInvite(
        id: "1",
        role: .viewer,
        status: .pending,
        createdAt: ISO8601DateFormatter().string(from: Date()),
        user: MemberUser(
            id: "3",
            name: "Bob Smith",
            email: "bob@example.com",
            profilePhotoUrl: nil,
            username: "bobsmith"
        )
    )
}
