import SwiftUI

/// Faz 2'de gerçek Login/Register ekranıyla değişir.
struct AuthPlaceholderView: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        AppScaffold {
            VStack(spacing: theme.dimens.spacingM) {
                Text(Strings.Auth.placeholderTitle)
                    .font(theme.typography.title)
                    .foregroundStyle(theme.colors.textOnPrimary)
                Text(Strings.Auth.placeholderMessage)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textOnGradientSecondary)
            }
        }
    }
}
