import CoreGraphics

/// Spacing, radius ve boyut token'ları.
struct AppDimens: Sendable {
    // Spacing
    let spacingXS: CGFloat = 4
    let spacingS: CGFloat = 8
    let spacingM: CGFloat = 12
    let spacingL: CGFloat = 16
    let spacingXL: CGFloat = 24

    // Radius
    let radiusS: CGFloat = 12
    let radiusM: CGFloat = 20
    let radiusL: CGFloat = 28
    let radiusPill: CGFloat = 999

    // Boyutlar
    let minTouchTarget: CGFloat = 44
    let iconS: CGFloat = 16
    let iconM: CGFloat = 24
    let iconL: CGFloat = 40
    let borderWidth: CGFloat = 1
    let badgeSize: CGFloat = 18

    let shadowRadius: CGFloat = 16
    let shadowOffsetY: CGFloat = 4

    // Animasyon
    let animationDuration: Double = 0.25
}
