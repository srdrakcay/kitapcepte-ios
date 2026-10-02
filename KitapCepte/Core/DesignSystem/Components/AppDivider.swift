import SwiftUI

struct AppDivider: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        Rectangle()
            .fill(theme.colors.textSecondary.opacity(0.2))
            .frame(height: theme.dimens.borderWidth)
            .accessibilityHidden(true)
    }
}
