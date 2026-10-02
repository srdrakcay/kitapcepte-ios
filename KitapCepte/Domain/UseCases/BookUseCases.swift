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
