import SwiftUI

struct FavoriteButton: View {
    @Environment(\.appTheme) private var theme
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        AppIconButton(
            systemImage: isFavorite ? "heart.fill" : "heart",
            accessibilityLabel: isFavorite ? Strings.Accessibility.removeFavorite : Strings.Accessibility.addFavorite,
            tint: isFavorite ? theme.colors.badgeCart : theme.colors.textSecondary,
            action: action
        )
        .animation(.spring(duration: theme.dimens.animationDuration), value: isFavorite)
    }
}

#Preview {
    HStack {
        FavoriteButton(isFavorite: false, action: {})
        FavoriteButton(isFavorite: true, action: {})
    }
    .padding()
    .background(AppTheme.standard.colors.backgroundGradient)
}
