import SwiftUI

enum AppBadgeStyle: Sendable {
    case topItem, cart
}

struct AppBadge: View {
    @Environment(\.appTheme) private var theme
    let text: String
    var style: AppBadgeStyle = .topItem

    var body: some View {
        Text(text)
            .font(theme.typography.caption.weight(.bold))
            .foregroundStyle(style == .topItem ? theme.colors.textPrimary : theme.colors.textOnPrimary)
            .padding(.horizontal, theme.dimens.spacingS)
            .frame(minWidth: theme.dimens.badgeSize, minHeight: theme.dimens.badgeSize)
            .background(style == .topItem ? theme.colors.badgeTopItem : theme.colors.badgeCart, in: theme.shapes.pill)
    }
}

#Preview {
    HStack {
        AppBadge(text: "Top Item")
        AppBadge(text: "3", style: .cart)
    }
    .padding()
}
