protocol BookRepository: Sendable {
    func books(subject: BookSubject, page: Int) async throws -> BookPage
}
