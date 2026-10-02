import SwiftUI

/// Ara toplam, vergi, ödemeler (kargo) ve toplam satırlarını içeren özet kartı.
struct OrderSummaryCard: View {
    @Environment(\.appTheme) private var theme
    let summary: CartSummary
    var formatter: PriceFormatter = .standard

    var body: some View {
        VStack(spacing: theme.dimens.spacingM) {
            SummaryRow(title: Strings.Cart.subtotal, value: formatter.string(from: summary.subtotal))
            SummaryRow(title: Strings.Cart.tax, value: formatter.string(from: summary.tax))
            SummaryRow(title: Strings.Cart.shipping, value: shippingText)
            AppDivider()
            SummaryRow(title: Strings.Cart.total, value: formatter.string(from: summary.total), isEmphasized: true)
        }
        .padding(theme.dimens.spacingL)
        .background(theme.colors.surfaceWhite, in: theme.shapes.card)
    }

    private var shippingText: String {
        summary.shipping == 0 ? Strings.Cart.shippingFree : formatter.string(from: summary.shipping)
    }
}

#if DEBUG
#Preview {
    OrderSummaryCard(summary: CartPricing.summary(for: [CartItem(bookID: "a", title: "A", authors: [], coverID: nil, unitPrice: 100)]))
        .padding()
        .background(AppTheme.standard.colors.backgroundGradient)
}
#endif
