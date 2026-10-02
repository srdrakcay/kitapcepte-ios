import SwiftUI

/// İki sütunlu kitap kartı ızgarası (Home ve Favoriler ortak kullanır).
struct BookGrid<Footer: View>: View {
    @Environment(\.appTheme) private var theme
    let books: [Book]
    let isFavorite: (Book) -> Bool
    let onSelect: (Book) -> Void
    let onToggleFavorite: (Book) -> Void
    let onBookAppeared: ((Book) -> Void)?
    /// Liste değişimi (ekleme/silme) animasyonlu olsun mu?
    let animatesChanges: Bool
    let footer: Footer

    init(
        books: [Book],
        isFavorite: @escaping (Book) -> Bool,
        onSelect: @escaping (Book) -> Void,
        onToggleFavorite: @escaping (Book) -> Void,
        onBookAppeared: ((Book) -> Void)? = nil,
        animatesChanges: Bool = false,
        @ViewBuilder footer: () -> Footer
    ) {
        self.books = books
        self.isFavorite = isFavorite
        self.onSelect = onSelect
        self.onToggleFavorite = onToggleFavorite
        self.onBookAppeared = onBookAppeared
        self.animatesChanges = animatesChanges
        self.footer = footer()
    }

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: theme.dimens.spacingM), count: 2),
                spacing: theme.dimens.spacingM
            ) {
                ForEach(books) { book in
                    BookCard(
                        book: book,
                        priceText: PriceFormatter.standard.string(from: book.price),
                        isFavorite: isFavorite(book),
                        onSelect: { onSelect(book) },
                        onToggleFavorite: { onToggleFavorite(book) }
                    )
                    .onAppear { onBookAppeared?(book) }
                }
            }
            .animation(animatesChanges ? .easeInOut(duration: theme.dimens.animationDuration) : nil, value: books.map(\.id))
            .padding(.horizontal, theme.dimens.spacingL)
            footer
        }
    }
}

extension BookGrid where Footer == EmptyView {
    init(
        books: [Book],
        isFavorite: @escaping (Book) -> Bool,
        onSelect: @escaping (Book) -> Void,
        onToggleFavorite: @escaping (Book) -> Void,
        onBookAppeared: ((Book) -> Void)? = nil,
        animatesChanges: Bool = false
    ) {
        self.init(
            books: books, isFavorite: isFavorite, onSelect: onSelect, onToggleFavorite: onToggleFavorite,
            onBookAppeared: onBookAppeared, animatesChanges: animatesChanges, footer: { EmptyView() }
        )
    }
}
