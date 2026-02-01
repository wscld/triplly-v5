import Foundation

struct ActivityComment: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let activityId: String
    let userId: String
    let content: String
    let createdAt: String
    let user: CommentUser
    let linkUrl: String?
    let linkTitle: String?
    let linkDescription: String?
    let linkImageUrl: String?
}

struct CommentUser: Codable, Equatable, Hashable, Sendable {
    let id: String
    let name: String
    let email: String
    let profilePhotoUrl: String?
}

// MARK: - Create DTO
struct CreateCommentRequest: Codable, Sendable {
    let content: String
}

// MARK: - Helper Extensions
extension ActivityComment {
    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: createdAt) else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: createdAt) else {
                return createdAt
            }
            return formatRelativeDate(date)
        }

        return formatRelativeDate(date)
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let now = Date()
        let diff = now.timeIntervalSince(date)

        if diff < 60 {
            return "Just now"
        } else if diff < 3600 {
            let minutes = Int(diff / 60)
            return "\(minutes)m ago"
        } else if diff < 86400 {
            let hours = Int(diff / 3600)
            return "\(hours)h ago"
        } else if diff < 604800 {
            let days = Int(diff / 86400)
            return "\(days)d ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Preview Data
extension ActivityComment {
    static let preview = ActivityComment(
        id: "1",
        activityId: "1",
        userId: "1",
        content: "This looks amazing!",
        createdAt: ISO8601DateFormatter().string(from: Date()),
        user: CommentUser(id: "1", name: "John Doe", email: "john@example.com", profilePhotoUrl: nil),
        linkUrl: nil,
        linkTitle: nil,
        linkDescription: nil,
        linkImageUrl: nil
    )
}
