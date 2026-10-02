import SwiftUI

struct PriceButton: View {
    @Environment(\.appTheme) private var theme
    let priceText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(priceText)
                .font(theme.typography.button)
                .foregroundStyle(theme.colors.textOnPrimary)
                .frame(maxWidth: .infinity, minHeight: theme.dimens.minTouchTarget)
                .background(theme.colors.primary, in: theme.shapes.pill)
        }
        .buttonStyle(.plain)
    }
}
