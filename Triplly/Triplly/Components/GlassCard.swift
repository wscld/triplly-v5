import SwiftUI

// MARK: - Glass Card Component
struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = LiquidGlass.cornerRadius
    var padding: CGFloat = 16

    init(
        cornerRadius: CGFloat = LiquidGlass.cornerRadius,
        padding: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.glassShadow, radius: LiquidGlass.shadowRadius, y: LiquidGlass.shadowY)
    }
}

// MARK: - Glass Button
struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Glass Icon Button
struct GlassIconButton: View {
    let icon: String
    let size: CGFloat
    let action: () -> Void

    init(_ icon: String, size: CGFloat = 44, action: @escaping () -> Void) {
        self.icon = icon
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.45))
                .foregroundStyle(Color.textPrimary)
                .frame(width: size, height: size)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.appPrimary)
            .clipShape(RoundedRectangle(cornerRadius: LiquidGlass.smallCornerRadius, style: .continuous))
        }
        .disabled(isLoading)
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.headline)
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: LiquidGlass.smallCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: LiquidGlass.smallCornerRadius, style: .continuous)
                    .stroke(Color.borderLight, lineWidth: 1)
            }
        }
    }
}

// MARK: - Previews
#Preview("Glass Card") {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack(spacing: 20) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tokyo Adventure")
                        .font(.headline)
                    Text("March 15 - 22, 2025")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                GlassButton("Edit", icon: "pencil") {}
                GlassIconButton("heart") {}
            }

            PrimaryButton("Continue", icon: "arrow.right") {}

            SecondaryButton("Cancel") {}
        }
        .padding()
    }
}
