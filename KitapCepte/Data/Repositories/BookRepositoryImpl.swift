import Foundation

/// Open Library'den kitap çeker; aynı istekler için kısa süreli bellek cache'i tutar.
actor BookRepositoryImpl: BookRepository {
    static let pageSize = 30
    static let cacheLifetime: TimeInterval = 300
    /// Mevcut kitap ve tekrarlar elendikten sonra yeterli kalsın diye fazladan çekilen kayıt çarpanı.
    static let similarFetchMultiplier = 2

    private struct CacheKey: Hashable {
        let subject: BookSubject
        let page: Int
    }

    private struct CacheEntry<Value> {
        let value: Value
        let storedAt: Date
    }

    private let service: OpenLibraryServicing
    private let now: @Sendable () -> Date
    private var pageCache: [CacheKey: CacheEntry<BookPage>] = [:]
    private var descriptionCache: [String: CacheEntry<String?>] = [:]
    private var similarCache: [String: CacheEntry<[Book]>] = [:]

    init(service: OpenLibraryServicing, now: @escaping @Sendable () -> Date = { .now }) {
        self.service = service
        self.now = now
    }

    func books(subject: BookSubject, page: Int) async throws -> BookPage {
        let key = CacheKey(subject: subject, page: page)
        if let cached = fresh(pageCache[key]) { return cached }
        let dto = try await service.searchBooks(subject: subject.rawValue, page: page, limit: Self.pageSize)
        let result = BookMapper.page(from: dto, page: page, limit: Self.pageSize, subject: subject)
        pageCache[key] = CacheEntry(value: result, storedAt: now())
        return result
    }

    func description(for book: Book) async throws -> String? {
        if let cached = fresh(descriptionCache[book.id]) { return cached }
        let text = BookMapper.description(from: try await service.work(key: book.id))
        descriptionCache[book.id] = CacheEntry(value: text, storedAt: now())
        return text
    }

    func similarBooks(to book: Book, limit: Int) async throws -> [Book] {
        if let cached = fresh(similarCache[book.id]) { return cached }
        let fetchLimit = limit * Self.similarFetchMultiplier
        var result: [Book] = []
        if let authorKey = book.authorKeys.first {
            let dto = try await service.searchBooks(authorKey: authorKey, limit: fetchLimit)
            result = BookMapper.similarBooks(from: dto, excluding: book, limit: limit)
        }
        if result.isEmpty, let subject = book.subject {
            let dto = try await service.searchBooks(subject: subject.rawValue, page: 1, limit: fetchLimit)
            result = BookMapper.similarBooks(from: dto, excluding: book, limit: limit)
        }
        similarCache[book.id] = CacheEntry(value: result, storedAt: now())
        return result
    }

    private func fresh<Value>(_ entry: CacheEntry<Value>?) -> Value? {
        guard let entry, now().timeIntervalSince(entry.storedAt) < Self.cacheLifetime else { return nil }
        return entry.value
    }
}
