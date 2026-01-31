import SwiftUI
import UIKit

// MARK: - App Colors
extension Color {
    // Primary brand color - Olive/Lime Green (same in both modes)
    static let appPrimary = Color(red: 0.604, green: 0.722, blue: 0.345)

    // Background - Warm Cream / Dark
    static let appBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
            : UIColor(red: 0.965, green: 0.957, blue: 0.937, alpha: 1)
    })

    // System colors
    static let appBlack = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.92, green: 0.92, blue: 0.93, alpha: 1)
            : UIColor(red: 0.11, green: 0.11, blue: 0.118, alpha: 1)
    })
    static let appWhite = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.118, alpha: 1)
            : UIColor.white
    })

    // Text colors
    static let textPrimary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.92, green: 0.92, blue: 0.93, alpha: 1)
            : UIColor(red: 0.11, green: 0.11, blue: 0.118, alpha: 1)
    })
    static let textSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.63, green: 0.63, blue: 0.65, alpha: 1)
            : UIColor(red: 0.557, green: 0.557, blue: 0.576, alpha: 1)
    })
    static let textLight = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.92, green: 0.92, blue: 0.93, alpha: 1)
            : UIColor.white
    })
    static let textError = Color(red: 1, green: 0.231, blue: 0.188)

    // Border colors
    static let borderLight = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.25, green: 0.25, blue: 0.27, alpha: 1)
            : UIColor(red: 0.898, green: 0.898, blue: 0.918, alpha: 1)
    })
    static let borderMedium = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.35, green: 0.35, blue: 0.37, alpha: 1)
            : UIColor(red: 0.780, green: 0.780, blue: 0.800, alpha: 1)
    })

    // Status colors
    static let success = Color(red: 0.180, green: 0.490, blue: 0.196)
    static let successLight = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.25, blue: 0.16, alpha: 1)
            : UIColor(red: 0.910, green: 0.961, blue: 0.914, alpha: 1)
    })
    static let error = Color(red: 1, green: 0.231, blue: 0.188)

    // Glass effect colors
    static let glassBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.1)
            : UIColor.white.withAlphaComponent(0.7)
    })
    static let glassBorder = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.15)
            : UIColor.white.withAlphaComponent(0.5)
    })
    static let glassShadow = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.black.withAlphaComponent(0.3)
            : UIColor.black.withAlphaComponent(0.1)
    })
}

// MARK: - Liquid Glass Design System
struct LiquidGlass {
    // Material effects for iOS 26 liquid glass aesthetic
    static let thinMaterial = Material.ultraThinMaterial
    static let regularMaterial = Material.regularMaterial
    static let thickMaterial = Material.thickMaterial

    // Corner radius for glass cards
    static let cornerRadius: CGFloat = 28
    static let smallCornerRadius: CGFloat = 20
    static let microCornerRadius: CGFloat = 14

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
