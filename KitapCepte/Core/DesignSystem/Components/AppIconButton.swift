import SwiftUI

/// Beyaz yuvarlak zeminli ikon buton (profil, favori vb.).
struct AppIconButton: View {
    @Environment(\.appTheme) private var theme
    let systemImage: String
    let accessibilityLabel: String
    var tint: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: theme.dimens.iconS, weight: .semibold))
                .foregroundStyle(tint ?? theme.colors.primary)
                .frame(width: theme.dimens.iconL, height: theme.dimens.iconL)
                .background(theme.colors.surfaceWhite, in: Circle())
                .frame(minWidth: theme.dimens.minTouchTarget, minHeight: theme.dimens.minTouchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
