import SwiftUI

struct CategoryModel: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let name: String
    let icon: String
    let color: String
    let isDefault: Bool
    let travelId: String?

    var swiftUIColor: Color {
        Color(hex: color)
    }

    var backgroundColor: Color {
        swiftUIColor.opacity(0.15)
    }

    /// Returns true if the icon is an emoji (not an SF Symbol name).
    var isEmoji: Bool {
        // SF Symbol names contain only ASCII letters, dots, and digits
        // Emojis contain non-ASCII characters
        icon.unicodeScalars.contains { !$0.isASCII }
    }

    var displayName: String {
        // Capitalize first letter of name for display
        name.prefix(1).uppercased() + name.dropFirst()
    }
}

// MARK: - Category Icon View
struct CategoryIconView: View {
    let category: CategoryModel
    let size: CGFloat

    init(_ category: CategoryModel, size: CGFloat = 16) {
        self.category = category
        self.size = size
    }

    var body: some View {
        if category.isEmoji {
            Text(category.icon)
                .font(.system(size: size))
        } else {
            Image(systemName: category.icon)
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Category Circle View (filled circle with icon)
struct CategoryCircleView: View {
    let category: CategoryModel
    let circleSize: CGFloat
    let iconSize: CGFloat

    init(_ category: CategoryModel, circleSize: CGFloat = 28, iconSize: CGFloat = 12) {
        self.category = category
        self.circleSize = circleSize
        self.iconSize = iconSize
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(category.swiftUIColor)
                .frame(width: circleSize, height: circleSize)

            CategoryIconView(category, size: iconSize)
        }
    }
}

// MARK: - Preview Data
extension CategoryModel {
    static let preview = CategoryModel(
        id: "1",
        name: "restaurant",
        icon: "fork.knife",
        color: "#EA580C",
        isDefault: true,
        travelId: nil
    )

    static let customPreview = CategoryModel(
        id: "2",
        name: "Live Music",
        icon: "🎸",
        color: "#9333EA",
        isDefault: false,
        travelId: "1"
    )
}
