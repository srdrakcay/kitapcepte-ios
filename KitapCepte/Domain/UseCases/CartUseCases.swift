@MainActor
struct AddToCartUseCase {
    let repository: CartRepository

    func callAsFunction(_ book: Book) async throws {
        try await repository.add(book)
    }
}
