import Foundation
import SwiftData

@Model
final class CartItemEntity {
    var ownerID: UUID
    var bookID: String
    var title: String
    var authors: [String]
    var coverID: Int?
    var unitPrice: Decimal
    var quantity: Int
    var addedAt: Date

    init(ownerID: UUID, item: CartItem, addedAt: Date = .now) {
        self.ownerID = ownerID
        self.bookID = item.bookID
        self.title = item.title
        self.authors = item.authors
        self.coverID = item.coverID
        self.unitPrice = item.unitPrice
        self.quantity = item.quantity
        self.addedAt = addedAt
    }
}
