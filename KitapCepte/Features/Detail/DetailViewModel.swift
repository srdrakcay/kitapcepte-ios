import Observation

@MainActor @Observable
final class DetailViewModel {
    struct State: Equatable {
        /// Yüklenemeyen/olmayan açıklama hata değil; `.loaded(nil)` olarak "açıklama yok" gösterilir.
        var description: Loadable<String?> = .idle
        var similar: Loadable<[Book]> = .idle
    }

    enum Action {
        case onAppear
        case retrySimilar
        case toggleFavorite(Book)
        case addToCart
    }

    let book: Book
    private(set) var state = State()
    private let getDescription: GetBookDescriptionUseCase
    private let getSimilarBooks: GetSimilarBooksUseCase
    private let favorites: FavoritesStore
    private let cart: CartStore
    private let gate: GuestGate

    init(
        book: Book,
        getDescription: GetBookDescriptionUseCase,
        getSimilarBooks: GetSimilarBooksUseCase,
        favorites: FavoritesStore,
        cart: CartStore,
        gate: GuestGate
    ) {
        self.book = book
        self.getDescription = getDescription
        self.getSimilarBooks = getSimilarBooks
        self.favorites = favorites
        self.cart = cart
        self.gate = gate
    }

    var isInCart: Bool { cart.contains(book.id) }

    func isFavorite(_ book: Book) -> Bool { favorites.isFavorite(book.id) }

    func send(_ action: Action) async {
        switch action {
        case .onAppear:
            async let description: Void = loadDescriptionIfNeeded()
            async let similar: Void = loadSimilarIfNeeded()
            _ = await (description, similar)
        case .retrySimilar:
            await loadSimilar()
        case .toggleFavorite(let target):
            guard isAllowed() else { return }
            await favorites.toggle(target)
        case .addToCart:
            guard !isInCart, isAllowed() else { return }
            await cart.add(book)
        }
    }

    /// Üye değilse `LoginRequiredSheet` açılır ve aksiyon yapılmaz.
    private func isAllowed() -> Bool {
        var allowed = false
        gate.require { allowed = true }
        return allowed
    }

    private func loadDescriptionIfNeeded() async {
        guard case .idle = state.description else { return }
        state.description = .loading
        do {
            state.description = .loaded(try await getDescription(book))
        } catch is CancellationError {
            state.description = .idle
        } catch {
            state.description = .loaded(nil)
        }
    }

    private func loadSimilarIfNeeded() async {
        guard case .idle = state.similar else { return }
        await loadSimilar()
    }

    private func loadSimilar() async {
        state.similar = .loading
        do {
            state.similar = .loaded(try await getSimilarBooks(to: book))
        } catch is CancellationError {
            state.similar = .idle
        } catch {
            state.similar = .failed((error as? AppError) ?? .unknown)
        }
    }
}
