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
        isTopItem: Bool = false, coverID: Int? = 42
    ) -> Book {
        Book(id: id, title: title, authors: ["J.R.R. Tolkien"], coverID: coverID,
             firstPublishYear: 1937, price: price, isTopItem: isTopItem)
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
    var response = SearchResponseDTO(numFound: 0, docs: [])

    var callCount: Int { lock.withLock { _callCount } }

    func searchBooks(subject: String, page: Int, limit: Int) async throws -> SearchResponseDTO {
        lock.withLock { _callCount += 1 }
        return response
    }
}
