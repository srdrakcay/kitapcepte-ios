import Foundation

enum BookMapper {
    /// Bu sayıda veya daha fazla baskısı olan kitaplar "Top Item" sayılır.
    static let topItemEditionThreshold = 30

    static func book(from dto: BookDocDTO) -> Book {
        Book(
            id: dto.key,
            title: dto.title,
            authors: dto.authorName ?? [],
            coverID: dto.coverI,
            firstPublishYear: dto.firstPublishYear,
            price: PriceGenerator.price(forKey: dto.key),
            isTopItem: (dto.editionCount ?? 0) >= topItemEditionThreshold
        )
    }

    static func page(from dto: SearchResponseDTO, page: Int, limit: Int) -> BookPage {
        let books = dto.docs
            .filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map(book(from:))
        let loadedCount = (page - 1) * limit + dto.docs.count
        let hasMore = dto.docs.count == limit && dto.numFound.map { loadedCount < $0 } ?? true
        return BookPage(books: books, hasMore: hasMore)
    }
}
