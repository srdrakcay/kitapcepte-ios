import SwiftUI

/// Etiket solda, değer sağda; `isEmphasized` toplam satırı içindir.
struct SummaryRow: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let value: String
    var isEmphasized = false

    var body: some View {
        HStack {
            Text(title)
                .font(isEmphasized ? theme.typography.headline : theme.typography.callout)
                .foregroundStyle(isEmphasized ? theme.colors.textPrimary : theme.colors.textSecondary)
            Spacer(minLength: theme.dimens.spacingM)
            Text(value)
                .font(isEmphasized ? theme.typography.title : theme.typography.callout.weight(.semibold))
                .foregroundStyle(theme.colors.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview {
    VStack {
        SummaryRow(title: "Ara toplam", value: "₺259,80")
        SummaryRow(title: "Toplam", value: "₺311,76", isEmphasized: true)
    }
    .padding()
}
#endif
