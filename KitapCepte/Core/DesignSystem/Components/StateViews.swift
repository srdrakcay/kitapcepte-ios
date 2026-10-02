import SwiftUI

/// Ortak durum görünümleri. (`EmptyView` SwiftUI ile çakıştığı için `EmptyStateView`.)
private struct StateMessage<Actions: View>: View {
    @Environment(\.appTheme) private var theme
    let systemImage: String
    let title: String
    let message: String?
    let actions: Actions

    init(systemImage: String, title: String, message: String?, @ViewBuilder actions: () -> Actions) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actions = actions()
    }

    var body: some View {
        VStack(spacing: theme.dimens.spacingM) {
            Image(systemName: systemImage)
                .font(.system(size: theme.dimens.iconL))
                .foregroundStyle(theme.colors.primary)
                .accessibilityHidden(true)
            Text(title)
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.textPrimary)
            if let message {
                Text(message)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            actions
        }
        .padding(theme.dimens.spacingXL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LoadingView: View {
    @Environment(\.appTheme) private var theme
    var body: some View {
        ProgressView(Strings.Common.loading)
            .tint(theme.colors.primary)
            .font(theme.typography.callout)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorView: View {
    let message: String
    var onRetry: (() -> Void)?

    var body: some View {
        StateMessage(systemImage: "exclamationmark.triangle", title: Strings.Common.errorTitle, message: message) {
            if let onRetry {
                AppButton(title: Strings.Common.retry, kind: .secondary, action: onRetry)
            }
        }
    }
}

struct EmptyStateView: View {
    var title: String = Strings.Common.emptyTitle
    var message: String?
    var systemImage = "books.vertical"

    var body: some View {
        StateMessage(systemImage: systemImage, title: title, message: message) { EmptyView() }
    }
}

#Preview("Error") { ErrorView(message: AppError.network.message, onRetry: {}) }
#Preview("Empty") { EmptyStateView() }
#Preview("Loading") { LoadingView() }
