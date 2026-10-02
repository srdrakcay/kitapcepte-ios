import Observation

@MainActor @Observable
final class FavoritesViewModel {
    struct State: Equatable {
        var books: Loadable<[Book]> = .idle
    }

    enum Action {
        case onAppear
        case retry
        /// `FavoritesStore.ids` başka bir yerden (Home/Detay) değişti.
        case storeChanged
        case remove(Book)
    }

    private(set) var state = State()
    private let getFavorites: GetFavoritesUseCase
    private let favorites: FavoritesStore

    init(getFavorites: GetFavoritesUseCase, favorites: FavoritesStore) {
        self.getFavorites = getFavorites
        self.favorites = favorites
    }

    func send(_ action: Action) async {
        switch action {
        case .onAppear:
            if case .idle = state.books { await load(showsLoading: true) }
        case .retry:
            await load(showsLoading: true)
        case .storeChanged:
            // Liste ekranda zaten varsa titremesin: yükleme göstermeden tazele.
            guard state.books.value != nil else { return }
            await load(showsLoading: false)
        case .remove(let book):
            await remove(book)
        }
    }

    private func remove(_ book: Book) async {
        await favorites.toggle(book)
        // Toggle başarısız olduysa kitap hâlâ favoridedir ve listede kalır.
        guard !favorites.isFavorite(book.id), let books = state.books.value else { return }
        state.books = .loaded(books.filter { $0.id != book.id })
    }

    private func load(showsLoading: Bool) async {
        if showsLoading { state.books = .loading }
        do {
            state.books = .loaded(try await getFavorites())
        } catch {
            // Sessiz tazelemede hata mevcut listeyi bozmaz.
            if showsLoading { state.books = .failed((error as? AppError) ?? .unknown) }
        }
    }
}
