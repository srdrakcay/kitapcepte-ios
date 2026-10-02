import SwiftUI

/// Tüm renk token'larının tek kaynağı.
struct AppColors: Sendable {
    let primary = Color(hex: 0x5B3FE8)
    let primaryContainer = Color(hex: 0xE8E3FB)
    let backgroundGradientStart = Color(hex: 0x6E7BE6)
    let backgroundGradientEnd = Color(hex: 0xA08BEF)
    let surface = Color(hex: 0xEEEBF8)
    let surfaceWhite = Color(hex: 0xFFFFFF)
    let textPrimary = Color(hex: 0x1F1B33)
    let textSecondary = Color(hex: 0x8D8AA3)
    let textOnPrimary = Color(hex: 0xFFFFFF)
    let textOnGradientSecondary = Color(hex: 0xFFFFFF, opacity: 0.85)
    let badgeTopItem = Color(hex: 0xFFD93B)
    let badgeCart = Color(hex: 0xF04A3C)
    let error = Color(hex: 0xF04A3C)

    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundGradientStart, backgroundGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
