import Observation

/// Ekranlar arasında paylaşılan sepet durumu (tab bar rozeti, detay butonu).
@MainActor @Observable
final class CartStore {
    private(set) var items: [CartItem] = []
    private let repository: CartRepository
    private let addToCart: AddToCartUseCase
    private let getCart: GetCartUseCase
    private let updateQuantity: UpdateCartQuantityUseCase
    private let removeFromCart: RemoveFromCartUseCase
    private let clearCart: ClearCartUseCase

    init(repository: CartRepository) {
        self.repository = repository
        self.addToCart = AddToCartUseCase(repository: repository)
        self.getCart = GetCartUseCase(repository: repository)
        self.updateQuantity = UpdateCartQuantityUseCase(repository: repository)
        self.removeFromCart = RemoveFromCartUseCase(repository: repository)
        self.clearCart = ClearCartUseCase(repository: repository)
    }

    /// Sepetteki toplam adet (tab bar rozeti).
    var count: Int { items.reduce(0) { $0 + $1.quantity } }

    func quantity(for bookID: String) -> Int {
        items.first { $0.bookID == bookID }?.quantity ?? 0
    }

    func contains(_ bookID: String) -> Bool { quantity(for: bookID) > 0 }

    func reload() async {
        items = await getCart()
    }

    /// Başarısız olursa durum değişmez.
    func add(_ book: Book) async {
        guard (try? await addToCart(book)) != nil else { return }
        await reload()
    }

    /// Adedi ayarlar (sınırlar `CartLimits`); başarısız olursa hata fırlatır ve durum değişmez.
    func setQuantity(_ quantity: Int, for bookID: String) async throws {
        try await updateQuantity(bookID: bookID, quantity: quantity)
        await reload()
    }

    func remove(_ bookID: String) async throws {
        try await removeFromCart(bookID: bookID)
        await reload()
    }

    func clear() async throws {
        try await clearCart()
        await reload()
    }
}
