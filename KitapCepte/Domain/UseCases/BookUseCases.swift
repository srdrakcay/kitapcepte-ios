struct GetBooksUseCase: Sendable {
    let repository: BookRepository

    /// `subject` nil ise varsayılan konu kullanılır.
    func callAsFunction(subject: BookSubject?, page: Int) async throws -> BookPage {
        try await repository.books(subject: subject ?? .default, page: page)
    }
}

@MainActor
struct ToggleFavoriteUseCase {
    let repository: FavoritesRepository

    func callAsFunction(_ book: Book) async throws -> Bool {
        try await repository.toggle(book)
    }
}

struct GetBookDescriptionUseCase: Sendable {
    let repository: BookRepository

    func callAsFunction(_ book: Book) async throws -> String? {
        try await repository.description(for: book)
    }
}

struct GetSimilarBooksUseCase: Sendable {
    static let defaultLimit = 10
    let repository: BookRepository

    func callAsFunction(to book: Book, limit: Int = defaultLimit) async throws -> [Book] {
        try await repository.similarBooks(to: book, limit: limit)
    }
}
