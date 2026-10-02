protocol BookRepository: Sendable {
    func books(subject: BookSubject, page: Int) async throws -> BookPage
    /// Kitabın açıklaması; yoksa nil.
    func description(for book: Book) async throws -> String?
    /// Aynı yazar (yoksa aynı konu) kitapları; `book` hariç, tekrarsız, en fazla `limit` adet.
    func similarBooks(to book: Book, limit: Int) async throws -> [Book]
}
