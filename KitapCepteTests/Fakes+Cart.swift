import Foundation
@testable import KitapCepte

extension CartItem {
    static func sample(id: String = "a", title: String = "Dune", price: Decimal = 100, quantity: Int = 1) -> CartItem {
        CartItem(bookID: id, title: title, authors: ["Frank Herbert"], coverID: nil, unitPrice: price, quantity: quantity)
    }
}
