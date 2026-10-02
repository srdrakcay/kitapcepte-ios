import Observation

/// Ekranlar arasında paylaşılan favori durumu.
@MainActor @Observable
final class FavoritesStore {
    private(set) var ids: Set<String> = []
    private let repository: FavoritesRepository
    private let toggleFavorite: ToggleFavoriteUseCase

    init(repository: FavoritesRepository) {
        self.repository = repository
        self.toggleFavorite = ToggleFavoriteUseCase(repository: repository)
    }

    func isFavorite(_ id: String) -> Bool { ids.contains(id) }

    func reload() async {
        ids = await repository.favoriteIDs()
    }

    /// Başarısız olursa durum değişmez (kalp eski haliyle kalır).
    func toggle(_ book: Book) async {
        guard let isFavorite = try? await toggleFavorite(book) else { return }
        if isFavorite { ids.insert(book.id) } else { ids.remove(book.id) }
    }
}
