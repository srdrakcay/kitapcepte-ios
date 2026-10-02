import Foundation
import SwiftData
import Testing
@testable import KitapCepte

private func books(_ ids: ClosedRange<Int>) -> [Book] {
    ids.map { .sample(id: "/works/\($0)", title: "Book \($0)") }
}

@MainActor
struct HomeViewModelTests {
    private func makeSUT(_ handler: @escaping @Sendable (BookSubject, Int) async throws -> BookPage) -> (HomeViewModel, FakeBookRepository) {
        let repo = FakeBookRepository()
        repo.handler = handler
        return (HomeViewModel(getBooks: GetBooksUseCase(repository: repo)), repo)
    }

    @Test func onAppearLoadsDefaultSubject() async {
        let list = books(1...3)
        let (sut, repo) = makeSUT { _, _ in BookPage(books: list, hasMore: true) }
        await sut.send(.onAppear)
        #expect(sut.state.books == .loaded(list))
        #expect(sut.state.canLoadMore)
        #expect(repo.calls.first?.subject == .fantasy)
    }

    @Test func onAppearDoesNotReloadWhenAlreadyLoaded() async {
        let (sut, repo) = makeSUT { _, _ in BookPage(books: [], hasMore: false) }
        await sut.send(.onAppear)
        await sut.send(.onAppear)
        #expect(repo.calls.count == 1)
    }

    @Test func selectingChipLoadsThatSubject() async {
        let (sut, repo) = makeSUT { _, _ in BookPage(books: [], hasMore: false) }
        await sut.send(.selectSubject(.history))
        #expect(sut.state.subject == .history)
        #expect(repo.calls.last?.subject == .history)
    }

    @Test func selectingSelectedChipDeselectsAndFallsBackToDefault() async {
        let (sut, repo) = makeSUT { _, _ in BookPage(books: [], hasMore: false) }
        await sut.send(.selectSubject(.horror))
        await sut.send(.selectSubject(.horror))
        #expect(sut.state.subject == nil)
        #expect(repo.calls.last?.subject == .fantasy)
    }

    @Test func emptyResultIsLoadedEmpty() async {
        let (sut, _) = makeSUT { _, _ in BookPage(books: [], hasMore: false) }
        await sut.send(.onAppear)
        #expect(sut.state.books == .loaded([]))
    }

    @Test func failureThenRetryRecovers() async {
        let counter = Counter()
        let list = books(1...2)
        let (sut, _) = makeSUT { _, _ in
            if counter.next() == 1 { throw AppError.network }
            return BookPage(books: list, hasMore: false)
        }
        await sut.send(.onAppear)
        #expect(sut.state.books == .failed(.network))
        await sut.send(.retry)
        #expect(sut.state.books == .loaded(list))
    }

    @Test func unknownErrorsBecomeUnknownAppError() async {
        struct Boom: Error {}
        let (sut, _) = makeSUT { _, _ in throw Boom() }
        await sut.send(.onAppear)
        #expect(sut.state.books == .failed(.unknown))
    }

    @Test func cancellationReturnsToIdleSoItCanReload() async {
        let (sut, _) = makeSUT { _, _ in throw CancellationError() }
        await sut.send(.onAppear)
        #expect(sut.state.books == .idle)
    }

    @Test func lastBookAppearingLoadsNextPageAndDedupes() async {
        let (sut, repo) = makeSUT { _, page in
            page == 1 ? BookPage(books: books(1...3), hasMore: true)
                      : BookPage(books: books(3...5), hasMore: false)
        }
        await sut.send(.onAppear)
        await sut.send(.bookAppeared(.sample(id: "/works/3")))
        #expect(sut.state.books.value?.map(\.id) == (1...5).map { "/works/\($0)" })
        #expect(sut.state.page == 2)
        #expect(!sut.state.canLoadMore)
        #expect(repo.calls.last?.page == 2)
    }

    @Test func nonLastBookDoesNotTriggerPagination() async {
        let (sut, repo) = makeSUT { _, _ in BookPage(books: books(1...3), hasMore: true) }
        await sut.send(.onAppear)
        await sut.send(.bookAppeared(.sample(id: "/works/1")))
        #expect(repo.calls.count == 1)
    }

    @Test func noMorePagesMeansNoRequest() async {
        let (sut, repo) = makeSUT { _, _ in BookPage(books: books(1...2), hasMore: false) }
        await sut.send(.onAppear)
        await sut.send(.bookAppeared(.sample(id: "/works/2")))
        #expect(repo.calls.count == 1)
    }

    @Test func failedNextPageKeepsExistingBooks() async {
        let counter = Counter()
        let first = books(1...2)
        let (sut, _) = makeSUT { _, _ in
            if counter.next() == 1 { return BookPage(books: first, hasMore: true) }
            throw AppError.network
        }
        await sut.send(.onAppear)
        await sut.send(.bookAppeared(.sample(id: "/works/2")))
        #expect(sut.state.books == .loaded(first))
        #expect(!sut.state.isLoadingMore)
        #expect(sut.state.canLoadMore)
    }

    @Test func switchingSubjectResetsPagination() async {
        let (sut, _) = makeSUT { _, _ in BookPage(books: books(1...2), hasMore: true) }
        await sut.send(.onAppear)
        await sut.send(.bookAppeared(.sample(id: "/works/2")))
        #expect(sut.state.page == 2)
        await sut.send(.selectSubject(.romance))
        #expect(sut.state.page == 1)
    }
}

@MainActor
struct FavoritesStoreTests {
    @Test func reloadReadsRepositoryIDs() async {
        let repo = FakeFavoritesRepository()
        repo.ids = ["a"]
        let sut = FavoritesStore(repository: repo)
        await sut.reload()
        #expect(sut.isFavorite("a"))
        #expect(!sut.isFavorite("b"))
    }

    @Test func toggleAddsThenRemoves() async {
        let sut = FavoritesStore(repository: FakeFavoritesRepository())
        let book = Book.sample()
        await sut.toggle(book)
        #expect(sut.isFavorite(book.id))
        await sut.toggle(book)
        #expect(!sut.isFavorite(book.id))
    }

    @Test func failedToggleLeavesStateUntouched() async {
        let repo = FakeFavoritesRepository()
        repo.shouldFail = true
        let sut = FavoritesStore(repository: repo)
        await sut.toggle(.sample())
        #expect(sut.ids.isEmpty)
    }
}

@MainActor
struct SwiftDataFavoritesRepositoryTests {
    private struct Harness {
        let container: ModelContainer
        let sut: SwiftDataFavoritesRepository
        let user: UserBox
    }

    private final class UserBox { var id: UUID?; init(_ id: UUID?) { self.id = id } }

    private func makeHarness(user: UUID? = UUID()) throws -> Harness {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: FavoriteEntity.self, configurations: config)
        let box = UserBox(user)
        let sut = SwiftDataFavoritesRepository(context: container.mainContext, userIDProvider: { box.id })
        return Harness(container: container, sut: sut, user: box)
    }

    @Test func toggleInsertsThenDeletes() async throws {
        let h = try makeHarness()
        let book = Book.sample()
        #expect(try await h.sut.toggle(book))
        #expect(await h.sut.favoriteIDs() == [book.id])
        #expect(try await h.sut.toggle(book) == false)
        #expect(await h.sut.favoriteIDs().isEmpty)
    }

    @Test func favoritesAreScopedPerUser() async throws {
        let h = try makeHarness()
        _ = try await h.sut.toggle(.sample(id: "mine"))
        h.user.id = UUID()
        #expect(await h.sut.favoriteIDs().isEmpty)
        _ = try await h.sut.toggle(.sample(id: "theirs"))
        #expect(await h.sut.favoriteIDs() == ["theirs"])
    }

    @Test func withoutUserThereAreNoFavoritesAndToggleFails() async throws {
        let h = try makeHarness(user: nil)
        #expect(await h.sut.favoriteIDs().isEmpty)
        await #expect(throws: AppError.unknown) { try await h.sut.toggle(.sample()) }
    }

    @Test func persistsBookSnapshotForFavoritesList() async throws {
        let h = try makeHarness()
        _ = try await h.sut.toggle(.sample(title: "Dune", price: 99.5, isTopItem: true))
        let entity = try #require(try h.container.mainContext.fetch(FetchDescriptor<FavoriteEntity>()).first)
        #expect(entity.title == "Dune")
        #expect(entity.price == 99.5)
        #expect(entity.isTopItem)
    }
}

@MainActor
struct MainViewModelTests {
    private func makeSUT(loggedIn: Bool) -> (MainViewModel, GuestGate) {
        let session = SessionManager(repository: FakeAuthRepository())
        if loggedIn { session.signedIn(.sample) } else { session.continueAsGuest() }
        let gate = GuestGate(sessionManager: session)
        return (MainViewModel(gate: gate), gate)
    }

    @Test func startsOnHome() {
        #expect(makeSUT(loggedIn: false).0.selectedTab == .home)
    }

    @Test func memberCanOpenEveryTab() {
        let (sut, _) = makeSUT(loggedIn: true)
        for tab in AppTab.allCases {
            sut.select(tab)
            #expect(sut.selectedTab == tab)
        }
    }

    @Test(arguments: [AppTab.favorites, .cart, .profile])
    func guestIsBlockedFromRestrictedTabs(tab: AppTab) {
        let (sut, gate) = makeSUT(loggedIn: false)
        sut.select(tab)
        #expect(sut.selectedTab == .home)
        #expect(gate.isSheetPresented)
    }

    @Test func guestCanReturnToHome() {
        let (sut, gate) = makeSUT(loggedIn: false)
        sut.select(.home)
        #expect(sut.selectedTab == .home)
        #expect(!gate.isSheetPresented)
    }
}
