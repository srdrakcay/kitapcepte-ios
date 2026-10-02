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
