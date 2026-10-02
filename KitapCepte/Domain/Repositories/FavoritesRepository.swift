/// Oturumdaki kullanıcıya ait favoriler.
@MainActor
protocol FavoritesRepository: AnyObject {
    func favoriteIDs() async -> Set<String>
    /// Yeni favori durumunu döndürür (`true` = favoride).
    func toggle(_ book: Book) async throws -> Bool
}
