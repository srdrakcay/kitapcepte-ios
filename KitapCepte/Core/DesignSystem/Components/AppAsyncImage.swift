import SwiftUI

/// Uzak görsel; yüklenirken ve hata/URL yokken placeholder gösterir.
struct AppAsyncImage: View {
    @Environment(\.appTheme) private var theme
    let url: URL?

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .empty where url != nil:
                ZStack {
                    theme.colors.primaryContainer
                    ProgressView().tint(theme.colors.primary)
                }
            default:
                ZStack {
                    theme.colors.primaryContainer
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: theme.dimens.iconL))
                        .foregroundStyle(theme.colors.primary.opacity(0.5))
                }
            }
        }
        .accessibilityHidden(true)
    }
}
