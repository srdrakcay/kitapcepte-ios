/// Oturumdaki kullanıcıya ait favoriler.
@MainActor
protocol FavoritesRepository: AnyObject {
    func favoriteIDs() async -> Set<String>
    /// Favori kitapların anlık görüntüleri; en son eklenen önce.
    func favoriteBooks() async throws -> [Book]
    /// Yeni favori durumunu döndürür (`true` = favoride).
    func toggle(_ book: Book) async throws -> Bool
}
