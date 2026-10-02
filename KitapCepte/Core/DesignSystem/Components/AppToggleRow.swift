import SwiftUI

/// Etiket solda, anahtar sağda.
struct AppToggleRow: View {
    @Environment(\.appTheme) private var theme
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textPrimary)
        }
        .tint(theme.colors.primary)
        .frame(minHeight: theme.dimens.minTouchTarget)
    }
}

#Preview {
    @Previewable @State var isOn = true
    return AppToggleRow(title: "Kartı kaydet", isOn: $isOn)
        .padding()
        .background(AppTheme.standard.colors.surface)
}
