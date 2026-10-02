/// Oturumdaki kullanıcıya ait sepet. Faz 6 adet/silme işlemleriyle genişletir.
@MainActor
protocol CartRepository: AnyObject {
    func items() async -> [CartItem]
    /// Kitap sepette yoksa 1 adetle ekler; zaten varsa adedi değiştirmez (adet yönetimi sepet ekranındadır).
    func add(_ book: Book) async throws
}
