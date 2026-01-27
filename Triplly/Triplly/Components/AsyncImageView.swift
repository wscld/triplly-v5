import SwiftUI

// MARK: - Async Image View with Caching
struct AsyncImageView: View {
    let url: URL?
    var placeholder: some View = Color.gray.opacity(0.2)
    var contentMode: ContentMode = .fill

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                SkeletonView()
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .failure:
                placeholderView
            @unknown default:
                placeholderView
            }
        }
    }

    @ViewBuilder
    private var placeholderView: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Network Avatar View
struct NetworkAvatarView: View {
    let name: String
    let imageUrl: String?
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let urlString = imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        initialsView
                    }
                }
            } else {
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var initialsView: some View {
        ZStack {
            Color.appPrimary.opacity(0.2)
            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(Color.appPrimary)
        }
    }

    private var initials: String {
        let components = name.split(separator: " ")
        let firstInitial = components.first?.first.map(String.init) ?? ""
        let lastInitial = components.count > 1 ? components.last?.first.map(String.init) ?? "" : ""
        return (firstInitial + lastInitial).uppercased()
    }
}

// MARK: - Travel Cover Image
struct TravelCoverImage: View {
    let coverUrl: String?
    var height: CGFloat = 200
    var cornerRadius: CGFloat = LiquidGlass.cornerRadius

    var body: some View {
        Group {
            if let urlString = coverUrl, let url = URL(string: urlString) {
                AsyncImageView(url: url)
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color.appPrimary.opacity(0.3), Color.appPrimary.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: "airplane.departure")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.appPrimary.opacity(0.5))
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Previews
#Preview("Network Avatar") {
    HStack(spacing: 20) {
        NetworkAvatarView(name: "John Doe", imageUrl: nil)
        NetworkAvatarView(name: "Jane Smith", imageUrl: nil, size: 60)
        NetworkAvatarView(name: "Bob", imageUrl: nil, size: 32)
    }
    .padding()
}

#Preview("Initials Avatar (existing)") {
    HStack(spacing: 12) {
        AvatarView(name: "John Doe", size: 40)
        AvatarView(name: "Jane Smith", size: 60)
        AvatarView(name: "Bob", size: 32)
    }
    .padding()
}

#Preview("Travel Cover") {
    VStack(spacing: 20) {
        TravelCoverImage(coverUrl: nil)
        TravelCoverImage(coverUrl: nil, height: 120, cornerRadius: 12)
    }
    .padding()
}
