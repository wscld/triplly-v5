import SwiftUI

// MARK: - App Colors
extension Color {
    // Primary brand color - Lime Green
    static let appPrimary = Color(red: 0.012, green: 0.859, blue: 0.424)

    // Background - Warm Beige
    static let appBackground = Color(red: 0.949, green: 0.941, blue: 0.914)

    // System colors
    static let appBlack = Color(red: 0.11, green: 0.11, blue: 0.118)
    static let appWhite = Color.white

    // Text colors
    static let textPrimary = Color(red: 0.11, green: 0.11, blue: 0.118)
    static let textSecondary = Color(red: 0.557, green: 0.557, blue: 0.576)
    static let textLight = Color.white
    static let textError = Color(red: 1, green: 0.231, blue: 0.188)

    // Border colors
    static let borderLight = Color(red: 0.898, green: 0.898, blue: 0.918)
    static let borderMedium = Color(red: 0.780, green: 0.780, blue: 0.800)

    // Status colors
    static let success = Color(red: 0.180, green: 0.490, blue: 0.196)
    static let successLight = Color(red: 0.910, green: 0.961, blue: 0.914)
    static let error = Color(red: 1, green: 0.231, blue: 0.188)

    // Glass effect colors
    static let glassBackground = Color.white.opacity(0.7)
    static let glassBorder = Color.white.opacity(0.5)
    static let glassShadow = Color.black.opacity(0.1)
}

// MARK: - Liquid Glass Design System
struct LiquidGlass {
    // Material effects for iOS 26 liquid glass aesthetic
    static let thinMaterial = Material.ultraThinMaterial
    static let regularMaterial = Material.regularMaterial
    static let thickMaterial = Material.thickMaterial

    // Corner radius for glass cards
    static let cornerRadius: CGFloat = 24
    static let smallCornerRadius: CGFloat = 16
    static let microCornerRadius: CGFloat = 12

    // Shadows
    static let shadowRadius: CGFloat = 20
    static let shadowY: CGFloat = 10

    // Blur amounts
    static let backgroundBlur: CGFloat = 20

    // Animation
    static let springAnimation = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let quickAnimation = Animation.easeOut(duration: 0.2)
}

// MARK: - View Extensions for Liquid Glass
extension View {
    func glassCard(cornerRadius: CGFloat = LiquidGlass.cornerRadius) -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.glassShadow, radius: LiquidGlass.shadowRadius, y: LiquidGlass.shadowY)
    }

    func glassButton() -> some View {
        self
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: LiquidGlass.microCornerRadius, style: .continuous))
    }

    func primaryButton() -> some View {
        self
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.appPrimary)
            .clipShape(RoundedRectangle(cornerRadius: LiquidGlass.smallCornerRadius, style: .continuous))
    }

    func secondaryButton() -> some View {
        self
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
