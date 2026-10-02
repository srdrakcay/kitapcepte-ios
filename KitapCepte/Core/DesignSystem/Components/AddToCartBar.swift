import SwiftUI

/// Detay ekranının alt sabit çubuğu: fiyat + "Sepete ekle" / "Sepette".
struct AddToCartBar: View {
    @Environment(\.appTheme) private var theme
    let priceText: String
    let isInCart: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: theme.dimens.spacingL) {
            VStack(alignment: .leading, spacing: 0) {
                Text(Strings.Detail.price)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
                Text(priceText)
                    .font(theme.typography.title)
                    .foregroundStyle(theme.colors.textPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)
            AppButton(
                title: isInCart ? Strings.Detail.inCart : Strings.Detail.addToCart,
                kind: isInCart ? .secondary : .primary,
                action: onAdd
            )
        }
        .padding(.horizontal, theme.dimens.spacingL)
        .padding(.vertical, theme.dimens.spacingM)
        .background {
            theme.shapes.bottomBar
                .fill(theme.colors.surfaceWhite)
                .shadow(color: theme.colors.shadow, radius: theme.dimens.shadowRadius)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

#if DEBUG
#Preview {
    VStack {
        AddToCartBar(priceText: "₺129,90", isInCart: false, onAdd: {})
        AddToCartBar(priceText: "₺129,90", isInCart: true, onAdd: {})
    }
    .background(AppTheme.standard.colors.backgroundGradient)
}
#endif
