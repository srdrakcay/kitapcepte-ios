import SwiftUI

struct SectionHeader: View {
    @Environment(\.appTheme) private var theme
    let title: String

    var body: some View {
        Text(title)
            .font(theme.typography.headline)
            .foregroundStyle(theme.colors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}
