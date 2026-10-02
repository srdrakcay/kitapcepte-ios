import SwiftUI

/// Uzak görsel; yüklenirken ve hata/URL yokken placeholder gösterir.
struct AppAsyncImage: View {
    /// Başarısız yüklemede (ör. görünüm gizliyken iptal edilen istek) en fazla bu kadar yeniden denenir.
    private static let maxRetries = 2
    private static let retryDelay: Duration = .seconds(1)

    @Environment(\.appTheme) private var theme
    @State private var attempt = 0
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
                .task { await retryIfNeeded() }
            }
        }
        .id(attempt)
        .accessibilityHidden(true)
    }

    private func retryIfNeeded() async {
        guard url != nil, attempt < Self.maxRetries else { return }
        try? await Task.sleep(for: Self.retryDelay)
        guard !Task.isCancelled else { return }
        attempt += 1
    }
}
