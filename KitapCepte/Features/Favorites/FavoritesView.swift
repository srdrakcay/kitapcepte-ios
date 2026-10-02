import SwiftUI

struct FavoritesView: View {
    @Environment(\.appTheme) private var theme
    @Environment(FavoritesStore.self) private var favorites
    let viewModel: FavoritesViewModel
    let onProfile: () -> Void
    let onSelectBook: (Book) -> Void

    var body: some View {
        VStack(spacing: theme.dimens.spacingM) {
            AppTopBar.titled(Strings.Favorites.title, onProfile: onProfile)
            content(viewModel.state.books)
        }
        .task { await viewModel.send(.onAppear) }
        // Home/Detay'dan yapılan değişiklikler de listeye yansır.
        .onChange(of: favorites.ids) { Task { await viewModel.send(.storeChanged) } }
    }

    @ViewBuilder
    private func content(_ books: Loadable<[Book]>) -> some View {
        switch books {
        case .idle, .loading:
            LoadingView()
        case .failed(let error):
            ErrorView(message: error.message) { Task { await viewModel.send(.retry) } }
        case .loaded(let books) where books.isEmpty:
            EmptyStateView(title: Strings.Favorites.emptyTitle, message: Strings.Favorites.emptyMessage, systemImage: "heart")
        case .loaded(let books):
            BookGrid(
                books: books,
                isFavorite: { favorites.isFavorite($0.id) },
                onSelect: onSelectBook,
                onToggleFavorite: { book in Task { await viewModel.send(.remove(book)) } },
                animatesChanges: true
            )
        }
    }
}

#if DEBUG
#Preview("Dolu") {
    let repository = PreviewFavoritesRepository(books: [.preview(1), .preview(2), .preview(3)])
    let store = FavoritesStore(repository: repository)
    return AppScaffold {
        FavoritesView(
            viewModel: FavoritesViewModel(getFavorites: GetFavoritesUseCase(repository: repository), favorites: store),
            onProfile: {}, onSelectBook: { _ in }
        )
    }
    .environment(store)
}

#Preview("Boş") {
    let repository = PreviewFavoritesRepository(books: [])
    let store = FavoritesStore(repository: repository)
    return AppScaffold {
        FavoritesView(
            viewModel: FavoritesViewModel(getFavorites: GetFavoritesUseCase(repository: repository), favorites: store),
            onProfile: {}, onSelectBook: { _ in }
        )
    }
    .environment(store)
}

@MainActor
private final class PreviewFavoritesRepository: FavoritesRepository {
    private var books: [Book]
    init(books: [Book]) { self.books = books }
    func favoriteIDs() async -> Set<String> { Set(books.map(\.id)) }
    func favoriteBooks() async throws -> [Book] { books }
    func toggle(_ book: Book) async throws -> Bool {
        books.removeAll { $0.id == book.id }
        return false
    }
}

private extension Book {
    static func preview(_ n: Int) -> Book {
        Book(id: "/works/OL\(n)W", title: "Örnek Kitap \(n)", authors: ["Yazar"], coverID: nil,
             firstPublishYear: 2000 + n, price: 100 + Decimal(n), isTopItem: n == 1)
    }
}
#endif
