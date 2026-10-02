import Observation

/// Ekranlar arasında paylaşılan sepet durumu (tab bar rozeti, detay butonu).
@MainActor @Observable
final class CartStore {
    private(set) var items: [CartItem] = []
    private let repository: CartRepository
    private let addToCart: AddToCartUseCase

    init(repository: CartRepository) {
        self.repository = repository
        self.addToCart = AddToCartUseCase(repository: repository)
    }

    /// Sepetteki toplam adet (tab bar rozeti).
    var count: Int { items.reduce(0) { $0 + $1.quantity } }

    func quantity(for bookID: String) -> Int {
        items.first { $0.bookID == bookID }?.quantity ?? 0
    }

    func contains(_ bookID: String) -> Bool { quantity(for: bookID) > 0 }

    func reload() async {
        items = await repository.items()
    }

    /// Başarısız olursa durum değişmez.
    func add(_ book: Book) async {
        guard (try? await addToCart(book)) != nil else { return }
        await reload()
    }
}
