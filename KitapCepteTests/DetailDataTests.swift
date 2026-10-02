import Foundation
import SwiftData
import Testing
@testable import KitapCepte

struct WorkDTOTests {
    private func decode(_ json: String) throws -> WorkDTO {
        try JSONDecoder().decode(WorkDTO.self, from: Data(json.utf8))
    }

    @Test func decodesPlainStringDescription() throws {
        #expect(try decode(#"{"title":"x","description":"Plain text"}"#).description == "Plain text")
    }

    @Test func decodesTypedObjectDescription() throws {
        let dto = try decode(#"{"description":{"type":"/type/text","value":"From object"}}"#)
        #expect(dto.description == "From object")
    }

    @Test func missingOrNullDescriptionIsNil() throws {
        #expect(try decode(#"{"title":"x"}"#).description == nil)
        #expect(try decode(#"{"description":null}"#).description == nil)
        #expect(try decode(#"{"description":{"type":"/type/text"}}"#).description == nil)
        #expect(try decode(#"{"description":42}"#).description == nil)
    }
}

struct DetailMapperTests {
    @Test func descriptionIsTrimmedAndBlankBecomesNil() {
        #expect(BookMapper.description(from: WorkDTO(description: "  Hello \n")) == "Hello")
        #expect(BookMapper.description(from: WorkDTO(description: "   ")) == nil)
        #expect(BookMapper.description(from: WorkDTO(description: nil)) == nil)
    }

    @Test func mapsAuthorKeysAndSubject() {
        let book = BookMapper.book(from: .sample(key: "k", authorKey: ["OL1A", "OL2A"]), subject: .history)
        #expect(book.authorKeys == ["OL1A", "OL2A"])
        #expect(book.subject == .history)
        #expect(BookMapper.book(from: .sample(key: "k")).authorKeys.isEmpty)
    }

    @Test func similarBooksExcludeCurrentDedupeAndLimit() {
        let docs = ["/works/cur", "/works/a", "/works/a", "/works/b", "/works/c"].map { BookDocDTO.sample(key: $0) }
        let dto = SearchResponseDTO(numFound: 5, docs: docs)
        let result = BookMapper.similarBooks(from: dto, excluding: .sample(id: "/works/cur"), limit: 2)
        #expect(result.map(\.id) == ["/works/a", "/works/b"])
    }
}

struct SimilarBooksRepositoryTests {
    private func docs(_ keys: [String]) -> SearchResponseDTO {
        SearchResponseDTO(numFound: keys.count, docs: keys.map { BookDocDTO.sample(key: $0) })
    }

    @Test func usesAuthorKeyWhenAvailable() async throws {
        let stub = StubOpenLibraryService()
        stub.authorResponse = docs(["/works/cur", "/works/a"])
        let sut = BookRepositoryImpl(service: stub)
        let result = try await sut.similarBooks(to: .sample(id: "/works/cur", authorKeys: ["OL9A"], subject: .fantasy), limit: 10)
        #expect(result.map(\.id) == ["/works/a"])
        #expect(stub.queries == ["author:OL9A"])
    }

    @Test func fallsBackToSubjectWithoutAuthorKey() async throws {
        let stub = StubOpenLibraryService()
        stub.response = docs(["/works/cur", "/works/b", "/works/b", "/works/c"])
        let sut = BookRepositoryImpl(service: stub)
        let result = try await sut.similarBooks(to: .sample(id: "/works/cur", subject: .history), limit: 10)
        #expect(result.map(\.id) == ["/works/b", "/works/c"])
        #expect(stub.queries == ["subject:history"])
    }

    @Test func fallsBackToSubjectWhenAuthorHasNoOtherBooks() async throws {
        let stub = StubOpenLibraryService()
        stub.authorResponse = docs(["/works/cur"])
        stub.response = docs(["/works/x"])
        let sut = BookRepositoryImpl(service: stub)
        let result = try await sut.similarBooks(to: .sample(id: "/works/cur", authorKeys: ["OL9A"], subject: .horror), limit: 10)
        #expect(result.map(\.id) == ["/works/x"])
        #expect(stub.queries == ["author:OL9A", "subject:horror"])
    }

    @Test func noAuthorKeyAndNoSubjectIsEmptyWithoutRequests() async throws {
        let stub = StubOpenLibraryService()
        let sut = BookRepositoryImpl(service: stub)
        #expect(try await sut.similarBooks(to: .sample(), limit: 10).isEmpty)
        #expect(stub.callCount == 0)
    }

    @Test func respectsLimitAndCachesResult() async throws {
        let stub = StubOpenLibraryService()
        stub.authorResponse = docs((1...20).map { "/works/\($0)" })
        let sut = BookRepositoryImpl(service: stub)
        let book = Book.sample(id: "/works/1", authorKeys: ["OL9A"])
        let first = try await sut.similarBooks(to: book, limit: 5)
        _ = try await sut.similarBooks(to: book, limit: 5)
        #expect(first.count == 5)
        #expect(!first.contains { $0.id == "/works/1" })
        #expect(stub.callCount == 1)
    }

    @Test func mappedSimilarBooksKeepSubjectForNestedFallback() async throws {
        let stub = StubOpenLibraryService()
        stub.response = docs(["/works/b"])
        let sut = BookRepositoryImpl(service: stub)
        let result = try await sut.similarBooks(to: .sample(subject: .mystery), limit: 3)
        #expect(result.first?.subject == .mystery)
    }
}

struct DescriptionRepositoryTests {
    @Test func fetchesAndCachesDescription() async throws {
        let stub = StubOpenLibraryService()
        stub.workResult = .success(WorkDTO(description: " Hi "))
        let sut = BookRepositoryImpl(service: stub)
        let book = Book.sample(id: "/works/OL1W")
        #expect(try await sut.description(for: book) == "Hi")
        #expect(try await sut.description(for: book) == "Hi")
        #expect(stub.queries == ["work:/works/OL1W"])
    }

    @Test func missingDescriptionIsNilAndAlsoCached() async throws {
        let stub = StubOpenLibraryService()
        let sut = BookRepositoryImpl(service: stub)
        #expect(try await sut.description(for: .sample()) == nil)
        #expect(try await sut.description(for: .sample()) == nil)
        #expect(stub.callCount == 1)
    }

    @Test func failuresPropagateAndAreNotCached() async throws {
        let stub = StubOpenLibraryService()
        stub.workResult = .failure(AppError.network)
        let sut = BookRepositoryImpl(service: stub)
        await #expect(throws: AppError.network) { try await sut.description(for: .sample()) }
        stub.workResult = .success(WorkDTO(description: "ok"))
        #expect(try await sut.description(for: .sample()) == "ok")
    }
}

struct WorkEndpointTests {
    @Test func requestsWorkJsonByKeyAndAuthorQuery() async throws {
        final class Capture: APIClient, @unchecked Sendable {
            nonisolated(unsafe) var endpoints: [Endpoint] = []
            func send<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
                endpoints.append(endpoint)
                return try JSONDecoder().decode(T.self, from: Data(#"{"docs":[]}"#.utf8))
            }
        }
        let capture = Capture()
        let sut = OpenLibraryService(client: capture)
        _ = try await sut.work(key: "/works/OL8400950W")
        _ = try await sut.searchBooks(authorKey: "OL26320A", limit: 20)
        #expect(capture.endpoints[0].url?.absoluteString == "https://openlibrary.org/works/OL8400950W.json")
        let items = URLComponents(url: try #require(capture.endpoints[1].url), resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.contains(URLQueryItem(name: "q", value: "author_key:OL26320A")))
        #expect(items.contains(URLQueryItem(name: "limit", value: "20")))
    }
}

@MainActor
struct SwiftDataCartRepositoryTests {
    private struct Harness {
        let container: ModelContainer
        let sut: SwiftDataCartRepository
        let user: UserBox
    }

    private final class UserBox { var id: UUID?; init(_ id: UUID?) { self.id = id } }

    private func makeHarness(user: UUID? = UUID()) throws -> Harness {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: CartItemEntity.self, configurations: config)
        let box = UserBox(user)
        return Harness(container: container, sut: SwiftDataCartRepository(context: container.mainContext, userIDProvider: { box.id }), user: box)
    }

    @Test func addInsertsOneQuantitySnapshot() async throws {
        let h = try makeHarness()
        try await h.sut.add(.sample(id: "a", title: "Dune", price: 99.5))
        let items = await h.sut.items()
        #expect(items.count == 1)
        #expect(items.first?.title == "Dune")
        #expect(items.first?.unitPrice == 99.5)
        #expect(items.first?.quantity == 1)
    }

    @Test func addingSameBookTwiceKeepsQuantityAtOne() async throws {
        let h = try makeHarness()
        try await h.sut.add(.sample(id: "a"))
        try await h.sut.add(.sample(id: "a"))
        #expect(await h.sut.items().map(\.quantity) == [1])
    }

    @Test func cartIsScopedPerUser() async throws {
        let h = try makeHarness()
        try await h.sut.add(.sample(id: "mine"))
        h.user.id = UUID()
        #expect(await h.sut.items().isEmpty)
        try await h.sut.add(.sample(id: "mine"))
        try await h.sut.add(.sample(id: "theirs"))
        #expect(await h.sut.items().map(\.bookID) == ["mine", "theirs"])
    }

    @Test func withoutUserCartIsEmptyAndAddFails() async throws {
        let h = try makeHarness(user: nil)
        #expect(await h.sut.items().isEmpty)
        await #expect(throws: AppError.unknown) { try await h.sut.add(.sample()) }
    }
}

@MainActor
struct CartStoreTests {
    @Test func addUpdatesCountContainsAndQuantity() async {
        let sut = CartStore(repository: FakeCartRepository())
        #expect(sut.count == 0)
        await sut.add(.sample(id: "a"))
        #expect(sut.contains("a"))
        #expect(sut.quantity(for: "a") == 1)
        #expect(sut.quantity(for: "b") == 0)
        #expect(sut.count == 1)
    }

    @Test func addingExistingBookDoesNotIncreaseQuantity() async {
        let sut = CartStore(repository: FakeCartRepository())
        await sut.add(.sample(id: "a"))
        await sut.add(.sample(id: "a"))
        #expect(sut.count == 1)
    }

    @Test func countSumsQuantities() async {
        let repo = FakeCartRepository()
        let sut = CartStore(repository: repo)
        await sut.add(.sample(id: "a"))
        await sut.add(.sample(id: "b"))
        #expect(sut.count == 2)
    }

    @Test func reloadReadsRepository() async {
        let repo = FakeCartRepository()
        try? await repo.add(.sample(id: "x"))
        let sut = CartStore(repository: repo)
        #expect(!sut.contains("x"))
        await sut.reload()
        #expect(sut.contains("x"))
    }

    @Test func failedAddLeavesStateUntouched() async {
        let repo = FakeCartRepository()
        repo.shouldFail = true
        let sut = CartStore(repository: repo)
        await sut.add(.sample())
        #expect(sut.count == 0)
    }
}

@MainActor
struct AddToCartUseCaseTests {
    @Test func delegatesToRepository() async throws {
        let repo = FakeCartRepository()
        try await AddToCartUseCase(repository: repo)(.sample(id: "a"))
        #expect(repo.stored.map(\.bookID) == ["a"])
    }

    @Test func propagatesRepositoryError() async {
        let repo = FakeCartRepository()
        repo.shouldFail = true
        await #expect(throws: AppError.unknown) { try await AddToCartUseCase(repository: repo)(.sample()) }
    }
}

struct CartItemTests {
    @Test func buildsFromBookWithQuantityOneAndTotals() {
        var item = CartItem(book: .sample(id: "a", price: 100))
        #expect(item.quantity == 1)
        #expect(item.totalPrice == 100)
        item.quantity = 3
        #expect(item.totalPrice == 300)
    }
}
