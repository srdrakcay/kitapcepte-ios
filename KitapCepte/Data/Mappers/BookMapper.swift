import Foundation

enum BookMapper {
    /// Bu sayıda veya daha fazla baskısı olan kitaplar "Top Item" sayılır.
    static let topItemEditionThreshold = 30

    static func book(from dto: BookDocDTO, subject: BookSubject? = nil) -> Book {
        Book(
            id: dto.key,
            title: dto.title,
            authors: dto.authorName ?? [],
            coverID: dto.coverI,
            firstPublishYear: dto.firstPublishYear,
            price: PriceGenerator.price(forKey: dto.key),
            isTopItem: (dto.editionCount ?? 0) >= topItemEditionThreshold,
            authorKeys: dto.authorKey ?? [],
            subject: subject
        )
    }

    static func page(from dto: SearchResponseDTO, page: Int, limit: Int, subject: BookSubject? = nil) -> BookPage {
        let books = dto.docs
            .filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { book(from: $0, subject: subject) }
        let loadedCount = (page - 1) * limit + dto.docs.count
        let hasMore = dto.docs.count == limit && dto.numFound.map { loadedCount < $0 } ?? true
        return BookPage(books: books, hasMore: hasMore)
    }
}

extension BookMapper {
    /// Açıklama boşsa nil döner (kenar boşlukları kırpılır).
    static func description(from dto: WorkDTO) -> String? {
        guard let text = dto.description?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
        return text
    }

    /// Benzer kitaplar: mevcut kitap hariç, tekrarsız, en fazla `limit` adet.
    static func similarBooks(from dto: SearchResponseDTO, excluding book: Book, limit: Int) -> [Book] {
        var seen: Set<String> = [book.id]
        return page(from: dto, page: 1, limit: limit, subject: book.subject).books
            .filter { seen.insert($0.id).inserted }
            .prefix(limit)
            .map { $0 }
    }
}
