import Foundation

/// Sepetteki bir kitap satırı (kitabın eklendiği andaki özeti).
struct CartItem: Identifiable, Hashable, Sendable {
    let bookID: String
    let title: String
    let authors: [String]
    let coverID: Int?
    let unitPrice: Decimal
    var quantity: Int

    var id: String { bookID }
    var authorsLine: String { authors.joined(separator: ", ") }
    var totalPrice: Decimal { unitPrice * Decimal(quantity) }
    func coverURL(_ size: CoverSize) -> URL? { Book.coverURL(id: coverID, size: size) }

    init(bookID: String, title: String, authors: [String], coverID: Int?, unitPrice: Decimal, quantity: Int = 1) {
        self.bookID = bookID
        self.title = title
        self.authors = authors
        self.coverID = coverID
        self.unitPrice = unitPrice
        self.quantity = quantity
    }

    init(book: Book, quantity: Int = 1) {
        self.init(bookID: book.id, title: book.title, authors: book.authors, coverID: book.coverID,
                  unitPrice: book.price, quantity: quantity)
    }
}
