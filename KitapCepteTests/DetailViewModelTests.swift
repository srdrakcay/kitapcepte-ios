import Foundation
import Testing
@testable import KitapCepte

@MainActor
struct DetailViewModelTests {
    private struct Harness {
        let sut: DetailViewModel
        let repo: FakeBookRepository
        let favorites: FakeFavoritesRepository
        let cart: FakeCartRepository
        let gate: GuestGate
        let favoritesStore: FavoritesStore
        let cartStore: CartStore
    }

    private func makeHarness(loggedIn: Bool = true, book: Book = .sample(id: "/works/cur")) -> Harness {
        let session = SessionManager(repository: FakeAuthRepository())
        if loggedIn { session.signedIn(.sample) } else { session.continueAsGuest() }
        let gate = GuestGate(sessionManager: session)
        let repo = FakeBookRepository()
        let favorites = FakeFavoritesRepository()
        let cart = FakeCartRepository()
        let favoritesStore = FavoritesStore(repository: favorites)
        let cartStore = CartStore(repository: cart)
        let sut = DetailViewModel(
            book: book,
            getDescription: GetBookDescriptionUseCase(repository: repo),
            getSimilarBooks: GetSimilarBooksUseCase(repository: repo),
            favorites: favoritesStore, cart: cartStore, gate: gate
        )
        return Harness(sut: sut, repo: repo, favorites: favorites, cart: cart, gate: gate,
                       favoritesStore: favoritesStore, cartStore: cartStore)
    }

    @Test func onAppearLoadsDescriptionAndSimilarBooks() async {
        let h = makeHarness()
        let similar = [Book.sample(id: "/works/a")]
        h.repo.descriptionHandler = { _ in "About" }
        h.repo.similarHandler = { _, _ in similar }
        await h.sut.send(.onAppear)
        #expect(h.sut.state.description == .loaded("About"))
        #expect(h.sut.state.similar == .loaded(similar))
    }

    @Test func missingDescriptionIsLoadedNil() async {
        let h = makeHarness()
        await h.sut.send(.onAppear)
        #expect(h.sut.state.description == .loaded(nil))
    }

    @Test func descriptionFailureDoesNotBreakScreen() async {
        let h = makeHarness()
        let similar = [Book.sample(id: "/works/a")]
        h.repo.descriptionHandler = { _ in throw AppError.network }
        h.repo.similarHandler = { _, _ in similar }
        await h.sut.send(.onAppear)
        #expect(h.sut.state.description == .loaded(nil))
        #expect(h.sut.state.similar == .loaded(similar))
    }

    @Test func similarFailureThenRetryRecovers() async {
        let h = makeHarness()
        let counter = Counter()
        let similar = [Book.sample(id: "/works/a")]
        h.repo.similarHandler = { _, _ in
            if counter.next() == 1 { throw AppError.network }
            return similar
        }
        await h.sut.send(.onAppear)
        #expect(h.sut.state.similar == .failed(.network))
        #expect(h.sut.state.description == .loaded(nil))
        await h.sut.send(.retrySimilar)
        #expect(h.sut.state.similar == .loaded(similar))
    }

    @Test func emptySimilarIsLoadedEmpty() async {
        let h = makeHarness()
        await h.sut.send(.onAppear)
        #expect(h.sut.state.similar == .loaded([]))
    }

    @Test func cancellationReturnsToIdleSoItReloads() async {
        let h = makeHarness()
        h.repo.descriptionHandler = { _ in throw CancellationError() }
        h.repo.similarHandler = { _, _ in throw CancellationError() }
        await h.sut.send(.onAppear)
        #expect(h.sut.state.description == .idle)
        #expect(h.sut.state.similar == .idle)
    }

    @Test func onAppearDoesNotReloadWhenAlreadyLoaded() async {
        let h = makeHarness()
        let counter = Counter()
        h.repo.similarHandler = { _, _ in _ = counter.next(); return [] }
        await h.sut.send(.onAppear)
        await h.sut.send(.onAppear)
        #expect(counter.next() == 2)
    }

    @Test func memberTogglesFavorite() async {
        let h = makeHarness()
        let book = h.sut.book
        await h.sut.send(.toggleFavorite(book))
        #expect(h.sut.isFavorite(book))
        await h.sut.send(.toggleFavorite(book))
        #expect(!h.sut.isFavorite(book))
    }

    @Test func guestFavoriteOpensGateAndDoesNothing() async {
        let h = makeHarness(loggedIn: false)
        await h.sut.send(.toggleFavorite(h.sut.book))
        #expect(h.gate.isSheetPresented)
        #expect(!h.sut.isFavorite(h.sut.book))
    }

    @Test func memberAddsToCartOnce() async {
        let h = makeHarness()
        #expect(!h.sut.isInCart)
        await h.sut.send(.addToCart)
        #expect(h.sut.isInCart)
        await h.sut.send(.addToCart)
        #expect(h.cartStore.quantity(for: h.sut.book.id) == 1)
        #expect(h.cart.stored.count == 1)
    }

    @Test func guestAddToCartOpensGate() async {
        let h = makeHarness(loggedIn: false)
        await h.sut.send(.addToCart)
        #expect(h.gate.isSheetPresented)
        #expect(!h.sut.isInCart)
    }
}

@MainActor
struct MainNavigationTests {
    private func makeSUT(loggedIn: Bool) -> (MainViewModel, GuestGate) {
        let session = SessionManager(repository: FakeAuthRepository())
        if loggedIn { session.signedIn(.sample) } else { session.continueAsGuest() }
        let gate = GuestGate(sessionManager: session)
        return (MainViewModel(gate: gate), gate)
    }

    @Test func memberPushesDetailAndPopsBack() {
        let (sut, gate) = makeSUT(loggedIn: true)
        let book = Book.sample(id: "a")
        sut.openDetail(book)
        #expect(sut.path == [.detail(book)])
        #expect(!gate.isSheetPresented)
        sut.pop()
        #expect(sut.path.isEmpty)
    }

    @Test func similarBookIsPushedOnTopOfCurrentDetail() {
        let (sut, _) = makeSUT(loggedIn: true)
        sut.openDetail(.sample(id: "a"))
        sut.openDetail(.sample(id: "b"))
        #expect(sut.path.count == 2)
        sut.pop()
        #expect(sut.path == [.detail(.sample(id: "a"))])
    }

    @Test func guestCannotOpenDetail() {
        let (sut, gate) = makeSUT(loggedIn: false)
        sut.openDetail(.sample())
        #expect(sut.path.isEmpty)
        #expect(gate.isSheetPresented)
    }

    @Test func popOnEmptyPathIsNoOpAndSystemBackUpdatesPath() {
        let (sut, _) = makeSUT(loggedIn: true)
        sut.pop()
        #expect(sut.path.isEmpty)
        sut.openDetail(.sample(id: "a"))
        sut.updatePath([])
        #expect(sut.path.isEmpty)
    }
}
