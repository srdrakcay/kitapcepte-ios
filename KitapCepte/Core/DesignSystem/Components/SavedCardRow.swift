import SwiftUI

/// Kayıtlı kart satırı: marka ikonu, maskeli numara, sahibi, SKT ve silme. Silme satır içi onay ister.
/// Metinler hazır gelir (biçimlendirme ViewModel'de); tam numara/CVV hiçbir yerde yoktur.
struct SavedCardRow: View {
    @Environment(\.appTheme) private var theme
    let brandName: String
    let maskedNumber: String
    let holderText: String
    let expiryText: String
    let expiredText: String?
    let accessibilityText: String
    let isConfirmingDeletion: Bool
    let onRequestDelete: () -> Void
    let onCancelDelete: () -> Void
    let onConfirmDelete: () -> Void

    var body: some View {
        VStack(spacing: theme.dimens.spacingM) {
            HStack(spacing: theme.dimens.spacingM) {
                Image(systemName: "creditcard")
                    .font(.system(size: theme.dimens.iconM))
                    .foregroundStyle(theme.colors.primary)
                    .frame(width: theme.dimens.cardBadgeSize, height: theme.dimens.cardBadgeSize)
                    .background(theme.colors.primaryContainer, in: theme.shapes.control)
                    .accessibilityHidden(true)
                details
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(accessibilityText)
                if !isConfirmingDeletion {
                    AppIconButton(
                        systemImage: "trash", accessibilityLabel: Strings.Profile.cardDelete,
                        tint: theme.colors.error, action: onRequestDelete
                    )
                }
            }
            if isConfirmingDeletion {
                InlineConfirmBar(
                    question: Strings.Profile.cardDeleteQuestion,
                    noTitle: Strings.Profile.cardDeleteNo, yesTitle: Strings.Profile.cardDeleteYes,
                    onNo: onCancelDelete, onYes: onConfirmDelete
                )
            }
        }
        .padding(theme.dimens.spacingM)
        .background(theme.colors.surfaceWhite, in: theme.shapes.control)
        .animation(.easeOut(duration: theme.dimens.animationDuration), value: isConfirmingDeletion)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: theme.dimens.spacingXS) {
            Text("\(brandName)  \(maskedNumber)")
                .font(theme.typography.headline.monospacedDigit())
                .foregroundStyle(theme.colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(holderText)
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textSecondary)
                .lineLimit(1)
            HStack(spacing: theme.dimens.spacingS) {
                Text(expiryText)
                    .font(theme.typography.caption.monospacedDigit())
                    .foregroundStyle(theme.colors.textSecondary)
                if let expiredText {
                    Text(expiredText)
                        .font(theme.typography.caption.weight(.semibold))
                        .foregroundStyle(theme.colors.error)
                }
            }
        }
    }
}

#Preview {
    VStack {
        SavedCardRow(
            brandName: "Visa", maskedNumber: "•••• 4242", holderText: "ADA LOVELACE", expiryText: "SKT 12/30",
            expiredText: nil, accessibilityText: "Visa", isConfirmingDeletion: false,
            onRequestDelete: {}, onCancelDelete: {}, onConfirmDelete: {}
        )
        SavedCardRow(
            brandName: "Mastercard", maskedNumber: "•••• 4444", holderText: "ADA LOVELACE", expiryText: "SKT 01/20",
            expiredText: "Süresi doldu", accessibilityText: "Mastercard", isConfirmingDeletion: true,
            onRequestDelete: {}, onCancelDelete: {}, onConfirmDelete: {}
        )
    }
    .padding()
    .background(AppTheme.standard.colors.backgroundGradient)
}
