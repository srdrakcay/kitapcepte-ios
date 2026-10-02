import SwiftUI

/// Kart önizleme: marka, numara, isim ve SKT. Metinler hazır gelir (biçimlendirme ViewModel'de).
struct CardPreview: View {
    @Environment(\.appTheme) private var theme
    let brandName: String
    let numberText: String
    let holderText: String
    let expiryText: String
    let accessibilityText: String

    var body: some View {
        VStack(alignment: .leading, spacing: theme.dimens.spacingL) {
            HStack {
                Image(systemName: "creditcard")
                    .font(.system(size: theme.dimens.iconM))
                    .accessibilityHidden(true)
                Spacer()
                Text(brandName)
                    .font(theme.typography.headline)
            }
            Spacer(minLength: 0)
            Text(numberText)
                .font(theme.typography.title.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            HStack(alignment: .bottom) {
                Text(holderText)
                    .font(theme.typography.callout)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: theme.dimens.spacingM)
                Text(expiryText)
                    .font(theme.typography.callout.monospacedDigit())
            }
        }
        .foregroundStyle(theme.colors.textOnPrimary)
        .padding(theme.dimens.spacingXL)
        .frame(maxWidth: .infinity)
        .aspectRatio(theme.dimens.cardAspectRatio, contentMode: .fit)
        .background(theme.colors.cardGradient, in: theme.shapes.card)
        .shadow(color: theme.colors.shadow, radius: theme.dimens.shadowRadius, y: theme.dimens.shadowOffsetY)
        // Maskeli numara tek tek okunmasın; sade bir özet okunur.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }
}

#Preview {
    CardPreview(
        brandName: "Visa", numberText: "4242 4242 •••• ••••", holderText: "ADA LOVELACE",
        expiryText: "12/30", accessibilityText: "Visa kartı"
    )
    .padding()
    .background(AppTheme.standard.colors.backgroundGradient)
}
