import Foundation
import SwiftData

@Model
final class FavoriteEntity {
    var ownerID: UUID
    var bookID: String
    var title: String
    var authors: [String]
    var coverID: Int?
    var firstPublishYear: Int?
    var price: Decimal
    var isTopItem: Bool
    var addedAt: Date

    init(ownerID: UUID, book: Book, addedAt: Date = .now) {
        self.ownerID = ownerID
        self.bookID = book.id
        self.title = book.title
        self.authors = book.authors
        self.coverID = book.coverID
        self.firstPublishYear = book.firstPublishYear
        self.price = book.price
        self.isTopItem = book.isTopItem
        self.addedAt = addedAt
    }
}
