import Foundation
import SwiftData
import Testing
@testable import KitapCepte

struct FavoriteMapperTests {
    @Test func mapsSnapshotFieldsAndLeavesAuthorKeysAndSubjectEmpty() {
        let source = Book.sample(id: "/works/X", title: "Dune", price: 99.5, isTopItem: true, coverID: 7)
        let entity = FavoriteEntity(ownerID: UUID(), book: source)
        let book = FavoriteMapper.book(from: entity)
        #expect(book.id == "/works/X")
        #expect(book.title == "Dune")
        #expect(book.authors == source.authors)
        #expect(book.coverID == 7)
        #expect(book.firstPublishYear == 1937)
        #expect(book.price == 99.5)
        #expect(book.isTopItem)
        #expect(book.authorKeys.isEmpty)
        #expect(book.subject == nil)
    }
}

@MainActor
struct SwiftDataFavoriteBooksTests {
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

    @Test func emptyWhenNoFavorites() async throws {
        let h = try makeHarness()
        #expect(try await h.sut.favoriteBooks().isEmpty)
    }

    @Test func emptyWithoutUser() async throws {
        let h = try makeHarness(user: nil)
        #expect(try await h.sut.favoriteBooks().isEmpty)
    }

    @Test func mostRecentlyAddedComesFirst() async throws {
        let h = try makeHarness()
        let owner = try #require(h.user.id)
        let context = h.container.mainContext
        let base = Date(timeIntervalSince1970: 1_000)
        for (id, offset) in [("old", 0.0), ("new", 100.0), ("mid", 50.0)] {
            context.insert(FavoriteEntity(ownerID: owner, book: .sample(id: id), addedAt: base.addingTimeInterval(offset)))
        }
        try context.save()
        #expect(try await h.sut.favoriteBooks().map(\.id) == ["new", "mid", "old"])
    }

    @Test func listIsScopedPerUser() async throws {
        let h = try makeHarness()
        _ = try await h.sut.toggle(.sample(id: "mine", title: "Mine"))
        #expect(try await h.sut.favoriteBooks().map(\.title) == ["Mine"])
        h.user.id = UUID()
        #expect(try await h.sut.favoriteBooks().isEmpty)
        _ = try await h.sut.toggle(.sample(id: "theirs"))
        #expect(try await h.sut.favoriteBooks().map(\.id) == ["theirs"])
    }

    @Test func removedBookDisappearsFromList() async throws {
        let h = try makeHarness()
        let book = Book.sample()
        _ = try await h.sut.toggle(book)
        _ = try await h.sut.toggle(book)
        #expect(try await h.sut.favoriteBooks().isEmpty)
    }
}

@MainActor
struct GetFavoritesUseCaseTests {
    @Test func returnsRepositoryBooks() async throws {
        let repo = FakeFavoritesRepository(books: [.sample(id: "a"), .sample(id: "b")])
        let result = try await GetFavoritesUseCase(repository: repo)()
        #expect(result.map(\.id) == ["a", "b"])
    }

    @Test func propagatesRepositoryError() async {
        let repo = FakeFavoritesRepository()
        repo.listError = .network
        await #expect(throws: AppError.network) { try await GetFavoritesUseCase(repository: repo)() }
    }
}

@MainActor
struct FavoritesViewModelTests {
    private struct Harness {
        let repo: FakeFavoritesRepository
        let store: FavoritesStore
        let sut: FavoritesViewModel
    }

    private func makeHarness(books: [Book] = []) -> Harness {
        let repo = FakeFavoritesRepository(books: books)
        let store = FavoritesStore(repository: repo)
        let sut = FavoritesViewModel(getFavorites: GetFavoritesUseCase(repository: repo), favorites: store)
        return Harness(repo: repo, store: store, sut: sut)
    }

    @Test func startsIdle() {
        #expect(makeHarness().sut.state.books == .idle)
    }

    @Test func onAppearLoadsFavorites() async {
        let h = makeHarness(books: [.sample(id: "a"), .sample(id: "b")])
        await h.sut.send(.onAppear)
        #expect(h.sut.state.books.value?.map(\.id) == ["a", "b"])
    }

    @Test func onAppearDoesNotReloadOnceLoaded() async {
        let h = makeHarness(books: [.sample(id: "a")])
        await h.sut.send(.onAppear)
        await h.sut.send(.onAppear)
        #expect(h.repo.listCallCount == 1)
    }

    @Test func emptyListIsLoadedEmpty() async {
        let h = makeHarness()
        await h.sut.send(.onAppear)
        #expect(h.sut.state.books == .loaded([]))
    }

    @Test func failureThenRetrySucceeds() async {
        let h = makeHarness(books: [.sample(id: "a")])
        h.repo.listError = .network
        await h.sut.send(.onAppear)
        #expect(h.sut.state.books == .failed(.network))
        h.repo.listError = nil
        await h.sut.send(.retry)
        #expect(h.sut.state.books.value?.map(\.id) == ["a"])
    }

    @Test func removeDropsBookFromListAndStore() async {
        let a = Book.sample(id: "a"), b = Book.sample(id: "b")
        let h = makeHarness(books: [a, b])
        await h.store.reload()
        await h.sut.send(.onAppear)
        await h.sut.send(.remove(a))
        #expect(h.sut.state.books.value?.map(\.id) == ["b"])
        #expect(!h.store.isFavorite("a"))
        #expect(h.store.isFavorite("b"))
    }

    @Test func removingLastBookLeavesEmptyState() async {
        let a = Book.sample(id: "a")
        let h = makeHarness(books: [a])
        await h.store.reload()
        await h.sut.send(.onAppear)
        await h.sut.send(.remove(a))
        #expect(h.sut.state.books == .loaded([]))
    }

    @Test func failedRemoveKeepsBookInList() async {
        let a = Book.sample(id: "a")
        let h = makeHarness(books: [a])
        await h.store.reload()
        await h.sut.send(.onAppear)
        h.repo.shouldFail = true
        await h.sut.send(.remove(a))
        #expect(h.sut.state.books.value?.map(\.id) == ["a"])
        #expect(h.store.isFavorite("a"))
    }

    @Test func storeChangeRefreshesLoadedList() async {
        let h = makeHarness(books: [.sample(id: "a")])
        await h.sut.send(.onAppear)
        // Home'dan yeni favori eklendi.
        await h.store.toggle(.sample(id: "new"))
        await h.sut.send(.storeChanged)
        #expect(h.sut.state.books.value?.map(\.id) == ["new", "a"])
    }

    @Test func storeChangeBeforeFirstLoadIsIgnored() async {
        let h = makeHarness(books: [.sample(id: "a")])
        await h.sut.send(.storeChanged)
        #expect(h.sut.state.books == .idle)
        #expect(h.repo.listCallCount == 0)
    }

    @Test func silentRefreshFailureKeepsExistingList() async {
        let h = makeHarness(books: [.sample(id: "a")])
        await h.sut.send(.onAppear)
        h.repo.listError = .network
        await h.sut.send(.storeChanged)
        #expect(h.sut.state.books.value?.map(\.id) == ["a"])
    }
}
