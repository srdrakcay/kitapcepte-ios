/// Oturumdaki kullanıcıya ait sepet.
@MainActor
protocol CartRepository: AnyObject {
    func items() async -> [CartItem]
    /// Kitap sepette yoksa 1 adetle ekler; zaten varsa adedi değiştirmez (adet yönetimi sepet ekranındadır).
    func add(_ book: Book) async throws
    /// Adedi `CartLimits` aralığına sıkıştırarak ayarlar. Sepette olmayan kitap için etkisizdir.
    func setQuantity(_ quantity: Int, for bookID: String) async throws
    func remove(_ bookID: String) async throws
    func clear() async throws
}
