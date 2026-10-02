import SwiftUI

/// Faz 7'de gerçek ödeme ekranıyla değişir.
struct PaymentPlaceholderView: View {
    let onBack: () -> Void

    var body: some View {
        AppScaffold(
            top: {
                AppTopBar(
                    title: Strings.Cart.paymentTitle,
                    leading: { AppIconButton(systemImage: "chevron.left", accessibilityLabel: Strings.Accessibility.back, action: onBack) },
                    trailing: { EmptyView() }
                )
            },
            bottom: { EmptyView() },
            content: { EmptyStateView(title: Strings.Cart.paymentTitle, message: Strings.Cart.paymentMessage, systemImage: "creditcard") }
        )
        .toolbar(.hidden, for: .navigationBar)
    }
}

#if DEBUG
#Preview { PaymentPlaceholderView(onBack: {}) }
#endif
