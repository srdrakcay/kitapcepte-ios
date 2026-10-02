import SwiftUI

struct BookCard: View {
    @Environment(\.appTheme) private var theme
    let book: Book
    let priceText: String
    let isFavorite: Bool
    let onSelect: () -> Void
    let onToggleFavorite: () -> Void

    private let coverAspectRatio: CGFloat = 2.0 / 3.0

    var body: some View {
        VStack(spacing: theme.dimens.spacingS) {
            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: theme.dimens.spacingS) {
                    // Boyutu kapağın kendi oranı değil, sabit oran belirler (kartlar hizalı kalır).
                    Color.clear
                        .aspectRatio(coverAspectRatio, contentMode: .fit)
                        .overlay { AppAsyncImage(url: book.coverURL(.medium)) }
                        .clipShape(theme.shapes.control)
                        .overlay(alignment: .topLeading) {
                            if book.isTopItem {
                                AppBadge(text: Strings.Home.topItem).padding(theme.dimens.spacingS)
                            }
                        }
                    Text(book.title)
                        .font(theme.typography.callout.weight(.semibold))
                        .foregroundStyle(theme.colors.textPrimary)
                        .lineLimit(2, reservesSpace: true)
                        .multilineTextAlignment(.leading)
                }
            }
            .buttonStyle(.plain)
            .overlay(alignment: .topTrailing) {
                FavoriteButton(isFavorite: isFavorite, action: onToggleFavorite)
            }
            PriceButton(priceText: priceText, action: onSelect)
        }
        .padding(theme.dimens.spacingS)
        .background(theme.colors.surfaceWhite, in: theme.shapes.card)
    }
}

#if DEBUG
#Preview {
    BookCard(
        book: Book(id: "/works/OL1W", title: "The Hobbit", authors: ["J.R.R. Tolkien"], coverID: 8406786,
                   firstPublishYear: 1937, price: 129.9, isTopItem: true),
        priceText: "₺129,90", isFavorite: false, onSelect: {}, onToggleFavorite: {}
    )
    .frame(width: 180)
    .padding()
    .background(AppTheme.standard.colors.backgroundGradient)
}
#endif
