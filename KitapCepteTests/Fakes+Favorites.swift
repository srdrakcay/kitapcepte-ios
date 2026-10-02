import Foundation
@testable import KitapCepte

/// Mevcut `FakeFavoritesRepository` liste kullanmaz; protokolü sağlaması için boş liste döner.
extension FakeFavoritesRepository {
    func favoriteBooks() async throws -> [Book] { [] }
}

/// Favori kitap listesini de tutan fake (en son eklenen başta).
@MainActor
final class FakeFavoritesListRepository: FavoritesRepository {
    private(set) var books: [Book]
    var listError: AppError?
    var toggleShouldFail = false
    private(set) var listCallCount = 0

    init(books: [Book] = []) { self.books = books }

    func favoriteIDs() async -> Set<String> { Set(books.map(\.id)) }

    func favoriteBooks() async throws -> [Book] {
        listCallCount += 1
        if let listError { throw listError }
        return books
    }

    func toggle(_ book: Book) async throws -> Bool {
        if toggleShouldFail { throw AppError.unknown }
        if let index = books.firstIndex(where: { $0.id == book.id }) {
            books.remove(at: index)
            return false
        }
        books.insert(book, at: 0)
        return true
    }
}
