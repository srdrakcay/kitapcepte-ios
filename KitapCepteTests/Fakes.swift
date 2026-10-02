import Foundation
@testable import KitapCepte

final class InMemorySecureStore: SecureStore, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: String] = [:]

    func set(_ value: String, for key: String) throws { lock.withLock { storage[key] = value } }
    func get(_ key: String) -> String? { lock.withLock { storage[key] } }
    func remove(_ key: String) { lock.withLock { storage[key] = nil } }
}

@MainActor
final class FakeAuthRepository: AuthRepository {
    var registerResult: Result<User, Error> = .success(User.sample)
    var loginResult: Result<User, Error> = .success(User.sample)
    var restoredUser: User?
    private(set) var logoutCount = 0
    private(set) var lastLoginEmail: String?
    private(set) var lastRegisterName: String?

    func register(name: String, email: String, password: String) async throws -> User {
        lastRegisterName = name
        return try registerResult.get()
    }

    func login(email: String, password: String) async throws -> User {
        lastLoginEmail = email
        return try loginResult.get()
    }

    func restoreSession() async -> User? { restoredUser }
    func logout() async { logoutCount += 1 }
}

extension User {
    static let sample = User(id: UUID(), name: "Ada Lovelace", email: "ada@example.com")
}

extension Book {
    static func sample(
        id: String = "/works/OL1W", title: String = "The Hobbit", price: Decimal = 129.9,
        isTopItem: Bool = false, coverID: Int? = 42, authorKeys: [String] = [], subject: BookSubject? = nil
    ) -> Book {
        Book(id: id, title: title, authors: ["J.R.R. Tolkien"], coverID: coverID,
             firstPublishYear: 1937, price: price, isTopItem: isTopItem, authorKeys: authorKeys, subject: subject)
    }
}

final class FakeBookRepository: BookRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var _calls: [(subject: BookSubject, page: Int)] = []
    var handler: @Sendable (BookSubject, Int) async throws -> BookPage = { _, _ in BookPage(books: [], hasMore: false) }

    var calls: [(subject: BookSubject, page: Int)] { lock.withLock { _calls } }

    func books(subject: BookSubject, page: Int) async throws -> BookPage {
        lock.withLock { _calls.append((subject, page)) }
        return try await handler(subject, page)
    }

    var descriptionHandler: @Sendable (Book) async throws -> String? = { _ in nil }
    var similarHandler: @Sendable (Book, Int) async throws -> [Book] = { _, _ in [] }

    func description(for book: Book) async throws -> String? { try await descriptionHandler(book) }
    func similarBooks(to book: Book, limit: Int) async throws -> [Book] { try await similarHandler(book, limit) }
}

@MainActor
final class FakeCartRepository: CartRepository {
    private(set) var stored: [CartItem] = []
    var shouldFail = false

    func items() async -> [CartItem] { stored }

    func add(_ book: Book) async throws {
        if shouldFail { throw AppError.unknown }
        guard !stored.contains(where: { $0.bookID == book.id }) else { return }
        stored.append(CartItem(book: book))
    }
}

@MainActor
final class FakeFavoritesRepository: FavoritesRepository {
    var ids: Set<String> = []
    var shouldFail = false

    func favoriteIDs() async -> Set<String> { ids }

    func toggle(_ book: Book) async throws -> Bool {
        if shouldFail { throw AppError.unknown }
        if ids.remove(book.id) != nil { return false }
        ids.insert(book.id)
        return true
    }
}

final class StubOpenLibraryService: OpenLibraryServicing, @unchecked Sendable {
    private let lock = NSLock()
    private var _callCount = 0
    private var _queries: [String] = []
    var response = SearchResponseDTO(numFound: 0, docs: [])
    var authorResponse = SearchResponseDTO(numFound: 0, docs: [])
    var workResult: Result<WorkDTO, Error> = .success(WorkDTO(description: nil))

    var callCount: Int { lock.withLock { _callCount } }
    /// Yapılan isteklerin özeti: `subject:x`, `author:x`, `work:x`.
    var queries: [String] { lock.withLock { _queries } }

    private func record(_ query: String) {
        lock.withLock {
            _callCount += 1
            _queries.append(query)
        }
    }

    func searchBooks(subject: String, page: Int, limit: Int) async throws -> SearchResponseDTO {
        record("subject:\(subject)")
        return response
    }

    func searchBooks(authorKey: String, limit: Int) async throws -> SearchResponseDTO {
        record("author:\(authorKey)")
        return authorResponse
    }

    func work(key workKey: String) async throws -> WorkDTO {
        record("work:\(workKey)")
        return try workResult.get()
    }
}

extension BookDocDTO {
    static func sample(key: String, title: String = "T", authorKey: [String]? = nil) -> BookDocDTO {
        BookDocDTO(key: key, title: title, authorName: nil, authorKey: authorKey, coverI: nil,
                   firstPublishYear: nil, editionCount: nil, language: nil)
    }
}
