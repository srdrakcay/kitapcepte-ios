@MainActor
struct GetFavoritesUseCase {
    let repository: FavoritesRepository

    func callAsFunction() async throws -> [Book] {
        try await repository.favoriteBooks()
    }
}
