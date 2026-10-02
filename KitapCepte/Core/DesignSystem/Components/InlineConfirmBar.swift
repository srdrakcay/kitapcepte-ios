import SwiftUI

/// Satır içi onay: soru + Hayır/Evet. Sepet satırı ve kayıtlı kart satırı paylaşır.
struct InlineConfirmBar: View {
    @Environment(\.appTheme) private var theme
    let question: String
    let noTitle: String
    let yesTitle: String
    let onNo: () -> Void
    let onYes: () -> Void

    var body: some View {
        HStack(spacing: theme.dimens.spacingS) {
            Text(question)
                .font(theme.typography.callout.weight(.semibold))
                .foregroundStyle(theme.colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            AppButton(title: noTitle, kind: .secondary, action: onNo)
                .fixedSize(horizontal: true, vertical: false)
            AppButton(title: yesTitle, action: onYes)
                .fixedSize(horizontal: true, vertical: false)
        }
    }
}

#Preview {
    InlineConfirmBar(question: "Kart silinsin mi?", noTitle: "Hayır", yesTitle: "Evet", onNo: {}, onYes: {})
        .padding()
}
