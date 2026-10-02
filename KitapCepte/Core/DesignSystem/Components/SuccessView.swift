import SwiftUI

/// Başarı ekranı: ikon + başlık + mesaj + detay kartı + birincil buton.
struct SuccessView<Details: View>: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let message: String
    let buttonTitle: String
    let onContinue: () -> Void
    let details: Details

    init(
        title: String, message: String, buttonTitle: String,
        onContinue: @escaping () -> Void, @ViewBuilder details: () -> Details
    ) {
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.onContinue = onContinue
        self.details = details()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: theme.dimens.spacingL) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: theme.dimens.successIconSize))
                    .foregroundStyle(theme.colors.textOnPrimary)
                    .accessibilityHidden(true)
                Text(title)
                    .font(theme.typography.largeTitle)
                    .foregroundStyle(theme.colors.textOnPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(message)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textOnGradientSecondary)
                    .multilineTextAlignment(.center)
                AppFormCard { details }
                AppButton(title: buttonTitle, action: onContinue)
            }
            .padding(theme.dimens.spacingL)
        }
    }
}

#Preview {
    SuccessView(title: "Ödeme başarılı", message: "Siparişin alındı.", buttonTitle: "Ana sayfaya dön", onContinue: {}) {
        SummaryRow(title: "Tutar", value: "₺311,76")
    }
    .background(AppTheme.standard.colors.backgroundGradient)
}
