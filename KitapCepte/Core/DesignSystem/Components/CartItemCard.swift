import SwiftUI

/// Sepet satırı: kapak, isim, yazar, fiyat, adet ve silme. Silme satır içi onay ister.
struct CartItemCard: View {
    @Environment(\.appTheme) private var theme
    let item: CartItem
    let priceText: String
    let quantityRange: ClosedRange<Int>
    let isConfirmingRemoval: Bool
    let onDecrement: () -> Void
    let onIncrement: () -> Void
    let onRequestRemove: () -> Void
    let onCancelRemove: () -> Void
    let onConfirmRemove: () -> Void

    var body: some View {
        VStack(spacing: theme.dimens.spacingM) {
            HStack(alignment: .top, spacing: theme.dimens.spacingM) {
                cover
                VStack(alignment: .leading, spacing: theme.dimens.spacingXS) {
                    Text(item.title)
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.colors.textPrimary)
                        .lineLimit(2)
                    if !item.authorsLine.isEmpty {
                        Text(item.authorsLine)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                            .lineLimit(1)
                    }
                    Text(priceText)
                        .font(theme.typography.title)
                        .foregroundStyle(theme.colors.primary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            }
            if isConfirmingRemoval {
                confirmation
            } else {
                controls
            }
        }
        .padding(theme.dimens.spacingM)
        .background(theme.colors.surfaceWhite, in: theme.shapes.card)
        .animation(.easeOut(duration: theme.dimens.animationDuration), value: isConfirmingRemoval)
    }

    private var cover: some View {
        Color.clear
            .frame(width: theme.dimens.cartCoverWidth, height: theme.dimens.cartCoverWidth / theme.dimens.coverAspectRatio)
            .overlay { AppAsyncImage(url: item.coverURL(.medium)) }
            .clipShape(theme.shapes.control)
    }

    private var controls: some View {
        HStack {
            QuantityStepper(
                quantity: item.quantity, range: quantityRange,
                onDecrement: onDecrement, onIncrement: onIncrement
            )
            Spacer()
            AppIconButton(
                systemImage: "trash", accessibilityLabel: Strings.Cart.remove,
                tint: theme.colors.error, action: onRequestRemove
            )
        }
    }

    private var confirmation: some View {
        HStack(spacing: theme.dimens.spacingS) {
            Text(Strings.Cart.removeQuestion)
                .font(theme.typography.callout.weight(.semibold))
                .foregroundStyle(theme.colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            AppButton(title: Strings.Cart.removeNo, kind: .secondary, action: onCancelRemove)
                .fixedSize(horizontal: true, vertical: false)
            AppButton(title: Strings.Cart.removeYes, action: onConfirmRemove)
                .fixedSize(horizontal: true, vertical: false)
        }
    }
}

#if DEBUG
#Preview {
    let item = CartItem(bookID: "a", title: "The Hobbit", authors: ["J.R.R. Tolkien"], coverID: 8406786, unitPrice: 129.9, quantity: 2)
    VStack {
        CartItemCard(
            item: item, priceText: "₺129,90", quantityRange: 1...99, isConfirmingRemoval: false,
            onDecrement: {}, onIncrement: {}, onRequestRemove: {}, onCancelRemove: {}, onConfirmRemove: {}
        )
        CartItemCard(
            item: item, priceText: "₺129,90", quantityRange: 1...99, isConfirmingRemoval: true,
            onDecrement: {}, onIncrement: {}, onRequestRemove: {}, onCancelRemove: {}, onConfirmRemove: {}
        )
    }
    .padding()
    .background(AppTheme.standard.colors.backgroundGradient)
}
#endif
