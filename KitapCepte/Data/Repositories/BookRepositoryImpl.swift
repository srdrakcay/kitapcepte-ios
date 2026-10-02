import Foundation

/// Open Library'den kitap çeker; aynı konu/sayfa için kısa süreli bellek cache'i tutar.
actor BookRepositoryImpl: BookRepository {
    static let pageSize = 30
    static let cacheLifetime: TimeInterval = 300

    private struct CacheKey: Hashable {
        let subject: BookSubject
        let page: Int
    }

    private struct CacheEntry {
        let page: BookPage
        let storedAt: Date
    }

    private let service: OpenLibraryServicing
    private let now: @Sendable () -> Date
    private var cache: [CacheKey: CacheEntry] = [:]

    init(service: OpenLibraryServicing, now: @escaping @Sendable () -> Date = { .now }) {
        self.service = service
        self.now = now
    }

    func books(subject: BookSubject, page: Int) async throws -> BookPage {
        let key = CacheKey(subject: subject, page: page)
        if let entry = cache[key], now().timeIntervalSince(entry.storedAt) < Self.cacheLifetime {
            return entry.page
        }
        let dto = try await service.searchBooks(subject: subject.rawValue, page: page, limit: Self.pageSize)
        let result = BookMapper.page(from: dto, page: page, limit: Self.pageSize)
        cache[key] = CacheEntry(page: result, storedAt: now())
        return result
    }
}
