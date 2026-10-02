import Foundation

struct Book: Identifiable, Hashable, Sendable {
    /// Open Library `key` (ör. `/works/OL8400950W`).
    let id: String
    let title: String
    let authors: [String]
    let coverID: Int?
    let firstPublishYear: Int?
    let price: Decimal
    let isTopItem: Bool
    /// Open Library yazar anahtarları (ör. `OL26320A`); benzer kitap sorgusunda kullanılır.
    let authorKeys: [String]
    /// Kitabın listelendiği Home konusu; yazar anahtarı yoksa benzer kitaplar bununla aranır.
    let subject: BookSubject?

    init(
        id: String, title: String, authors: [String], coverID: Int?, firstPublishYear: Int?,
        price: Decimal, isTopItem: Bool, authorKeys: [String] = [], subject: BookSubject? = nil
    ) {
        self.id = id
        self.title = title
        self.authors = authors
        self.coverID = coverID
        self.firstPublishYear = firstPublishYear
        self.price = price
        self.isTopItem = isTopItem
        self.authorKeys = authorKeys
        self.subject = subject
    }

    var authorsLine: String { authors.joined(separator: ", ") }
}

enum CoverSize: String, Sendable {
    case medium = "M"
    case large = "L"
}

extension Book {
    private static let coversBaseURL = "https://covers.openlibrary.org/b/id/"

    func coverURL(_ size: CoverSize) -> URL? {
        coverID.flatMap { URL(string: "\(Self.coversBaseURL)\($0)-\(size.rawValue).jpg") }
    }
}
