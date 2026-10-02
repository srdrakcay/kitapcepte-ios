import SwiftUI

struct AppErrorBanner: View {
    @Environment(\.appTheme) private var theme
    let message: String

    var body: some View {
        Text(message)
            .font(theme.typography.callout)
            .foregroundStyle(theme.colors.error)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(theme.dimens.spacingM)
            .background(theme.colors.surfaceWhite, in: theme.shapes.control)
    }
}
