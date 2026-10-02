import Foundation
@testable import KitapCepte

/// Faz 6'da `CartRepository`'ye eklenen yöntemler için test varsayılanları: `Fakes.swift`'teki eski
/// `FakeCartRepository` bunları kullanmaz. Tam davranış `FakeCartManagedRepository`'dedir.
extension CartRepository {
    func setQuantity(_ quantity: Int, for bookID: String) async throws { throw AppError.unknown }
    func remove(_ bookID: String) async throws { throw AppError.unknown }
    func clear() async throws { throw AppError.unknown }
}

@MainActor
final class FakeCartManagedRepository: CartRepository {
    private(set) var stored: [CartItem]
    var shouldFail = false
    private(set) var setQuantityCalls: [(bookID: String, quantity: Int)] = []

    init(items: [CartItem] = []) {
        stored = items
    }

    func items() async -> [CartItem] { stored }

    func add(_ book: Book) async throws {
        if shouldFail { throw AppError.unknown }
        guard !stored.contains(where: { $0.bookID == book.id }) else { return }
        stored.append(CartItem(book: book))
    }

    func setQuantity(_ quantity: Int, for bookID: String) async throws {
        if shouldFail { throw AppError.unknown }
        setQuantityCalls.append((bookID, quantity))
        guard let index = stored.firstIndex(where: { $0.bookID == bookID }) else { return }
        stored[index].quantity = CartLimits.clamp(quantity)
    }

    func remove(_ bookID: String) async throws {
        if shouldFail { throw AppError.unknown }
        stored.removeAll { $0.bookID == bookID }
    }

    func clear() async throws {
        if shouldFail { throw AppError.unknown }
        stored.removeAll()
    }
}

extension CartItem {
    static func sample(id: String = "a", title: String = "Dune", price: Decimal = 100, quantity: Int = 1) -> CartItem {
        CartItem(bookID: id, title: title, authors: ["Frank Herbert"], coverID: nil, unitPrice: price, quantity: quantity)
    }
}
