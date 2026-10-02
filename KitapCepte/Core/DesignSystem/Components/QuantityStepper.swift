import SwiftUI

/// Adet artır/azalt hapı. Sınırlara gelince ilgili buton pasifleşir.
struct QuantityStepper: View {
    @Environment(\.appTheme) private var theme
    let quantity: Int
    let range: ClosedRange<Int>
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            stepButton("minus", label: Strings.Cart.decrease, isEnabled: quantity > range.lowerBound, action: onDecrement)
            Text("\(quantity)")
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.textPrimary)
                .monospacedDigit()
                .frame(minWidth: theme.dimens.iconM)
                .accessibilityLabel(Strings.Cart.quantity(quantity))
            stepButton("plus", label: Strings.Cart.increase, isEnabled: quantity < range.upperBound, action: onIncrement)
        }
        .background(theme.colors.primaryContainer, in: theme.shapes.pill)
    }

    private func stepButton(_ systemImage: String, label: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: theme.dimens.iconS, weight: .bold))
                .foregroundStyle(theme.colors.primary)
                .frame(minWidth: theme.dimens.minTouchTarget, minHeight: theme.dimens.minTouchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityLabel(label)
    }
}

#if DEBUG
#Preview {
    VStack {
        QuantityStepper(quantity: 1, range: 1...99, onDecrement: {}, onIncrement: {})
        QuantityStepper(quantity: 3, range: 1...99, onDecrement: {}, onIncrement: {})
    }
    .padding()
}
#endif
