import Foundation
import Testing
@testable import KitapCepte

struct PriceGeneratorTests {
    @Test func fnv1aMatchesPublishedVectors() {
        #expect(PriceGenerator.fnv1a64("") == 0xcbf29ce484222325)
        #expect(PriceGenerator.fnv1a64("a") == 0xaf63dc4c8601ec8c)
        #expect(PriceGenerator.fnv1a64("foobar") == 0x85944171f73967e8)
    }

    @Test func priceIsDeterministic() {
        #expect(PriceGenerator.price(forKey: "/works/OL1W") == PriceGenerator.price(forKey: "/works/OL1W"))
    }

    @Test func priceStaysInRangeAndOnTenKurusSteps() {
        let low = Decimal(PriceGenerator.minCents) / 100
        let high = Decimal(PriceGenerator.maxCents) / 100
        for index in 0..<500 {
            let price = PriceGenerator.price(forKey: "/works/OL\(index)W")
            #expect(price >= low && price <= high)
            let cents = NSDecimalNumber(decimal: price * 100).intValue
            #expect((cents - PriceGenerator.minCents) % PriceGenerator.stepCents == 0)
        }
    }

    @Test func differentKeysProduceDifferentPrices() {
        let prices = Set((0..<50).map { PriceGenerator.price(forKey: "/works/OL\($0)W") })
        #expect(prices.count > 20)
    }
}

struct PriceFormatterTests {
    @Test func formatsTurkishLira() {
        let text = PriceFormatter.standard.string(from: Decimal(string: "129.9") ?? 0)
        #expect(text.contains("₺"))
        #expect(text.contains("129,90"))
    }
}

struct BookMapperTests {
    private func decode(_ json: String) throws -> SearchResponseDTO {
        try JSONDecoder().decode(SearchResponseDTO.self, from: Data(json.utf8))
    }

    @Test func decodesApiPayloadIgnoringUnknownFields() throws {
        let dto = try decode("""
        {"numFound": 2, "start": 0, "docs": [
          {"key": "/works/OL1W", "title": "The Hobbit", "author_name": ["J.R.R. Tolkien"],
           "cover_i": 8406786, "first_publish_year": 1937, "edition_count": 120, "ebook_access": "x"},
          {"key": "/works/OL2W", "title": "No Extras"}
        ]}
        """)
        #expect(dto.numFound == 2)
        #expect(dto.docs.count == 2)
        #expect(dto.docs[0].coverI == 8406786)
        #expect(dto.docs[1].authorName == nil)
    }

    @Test func mapsFullDocument() throws {
        let dto = try decode(#"{"docs":[{"key":"/works/OL1W","title":"The Hobbit","author_name":["Tolkien"],"cover_i":7,"first_publish_year":1937,"edition_count":30}]}"#)
        let book = try #require(BookMapper.page(from: dto, page: 1, limit: 30).books.first)
        #expect(book.id == "/works/OL1W")
        #expect(book.authors == ["Tolkien"])
        #expect(book.isTopItem)
        #expect(book.price == PriceGenerator.price(forKey: "/works/OL1W"))
        #expect(book.coverURL(.medium)?.absoluteString == "https://covers.openlibrary.org/b/id/7-M.jpg")
        #expect(book.coverURL(.large)?.absoluteString == "https://covers.openlibrary.org/b/id/7-L.jpg")
    }

    @Test func missingOptionalFieldsAreNullSafe() throws {
        let dto = try decode(#"{"docs":[{"key":"/works/OL2W","title":"Bare"}]}"#)
        let book = try #require(BookMapper.page(from: dto, page: 1, limit: 30).books.first)
        #expect(book.authors.isEmpty)
        #expect(book.coverURL(.medium) == nil)
        #expect(!book.isTopItem)
    }

    @Test func topItemThresholdIsInclusive() throws {
        let below = try decode(#"{"docs":[{"key":"a","title":"A","edition_count":29}]}"#)
        #expect(BookMapper.page(from: below, page: 1, limit: 30).books.first?.isTopItem == false)
    }

    @Test func skipsBlankTitles() throws {
        let dto = try decode(#"{"docs":[{"key":"a","title":"  "},{"key":"b","title":"Ok"}]}"#)
        #expect(BookMapper.page(from: dto, page: 1, limit: 30).books.map(\.id) == ["b"])
    }

    @Test func hasMoreDependsOnPageSizeAndTotal() throws {
        let docs = (0..<2).map { #"{"key":"k\#($0)","title":"T"}"# }.joined(separator: ",")
        let fullPage = try decode(#"{"numFound":10,"docs":[\#(docs)]}"#)
        #expect(BookMapper.page(from: fullPage, page: 1, limit: 2).hasMore)
        let lastPage = try decode(#"{"numFound":4,"docs":[\#(docs)]}"#)
        #expect(!BookMapper.page(from: lastPage, page: 2, limit: 2).hasMore)
        let shortPage = try decode(#"{"numFound":10,"docs":[\#(docs)]}"#)
        #expect(!BookMapper.page(from: shortPage, page: 1, limit: 30).hasMore)
    }
}

struct BookRepositoryTests {
    private final class Clock: @unchecked Sendable {
        private let lock = NSLock()
        private var date = Date(timeIntervalSince1970: 1_000)
        var now: Date { lock.withLock { date } }
        func advance(_ seconds: TimeInterval) { lock.withLock { date.addTimeInterval(seconds) } }
    }

    private func service(titles: [String] = ["A"]) -> StubOpenLibraryService {
        let stub = StubOpenLibraryService()
        stub.response = SearchResponseDTO(numFound: 1, docs: titles.map {
            BookDocDTO(key: "/works/\($0)", title: $0, authorName: nil, authorKey: nil, coverI: nil,
                       firstPublishYear: nil, editionCount: nil, language: nil)
        })
        return stub
    }

    @Test func cachesRepeatedRequestsForSameSubjectAndPage() async throws {
        let stub = service()
        let sut = BookRepositoryImpl(service: stub)
        _ = try await sut.books(subject: .fantasy, page: 1)
        _ = try await sut.books(subject: .fantasy, page: 1)
        #expect(stub.callCount == 1)
    }

    @Test func differentSubjectOrPageIsNotShared() async throws {
        let stub = service()
        let sut = BookRepositoryImpl(service: stub)
        _ = try await sut.books(subject: .fantasy, page: 1)
        _ = try await sut.books(subject: .fantasy, page: 2)
        _ = try await sut.books(subject: .history, page: 1)
        #expect(stub.callCount == 3)
    }

    @Test func cacheExpiresAfterLifetime() async throws {
        let stub = service()
        let clock = Clock()
        let sut = BookRepositoryImpl(service: stub, now: { clock.now })
        _ = try await sut.books(subject: .fantasy, page: 1)
        clock.advance(BookRepositoryImpl.cacheLifetime + 1)
        _ = try await sut.books(subject: .fantasy, page: 1)
        #expect(stub.callCount == 2)
    }

    @Test func mapsResponseToDomain() async throws {
        let sut = BookRepositoryImpl(service: service(titles: ["A", "B"]))
        let page = try await sut.books(subject: .fantasy, page: 1)
        #expect(page.books.map(\.title) == ["A", "B"])
    }
}

struct GetBooksUseCaseTests {
    @Test func usesDefaultSubjectWhenNoneSelected() async throws {
        let repo = FakeBookRepository()
        _ = try await GetBooksUseCase(repository: repo)(subject: nil, page: 1)
        #expect(repo.calls.first?.subject == .fantasy)
    }

    @Test func passesSelectedSubjectAndPage() async throws {
        let repo = FakeBookRepository()
        _ = try await GetBooksUseCase(repository: repo)(subject: .horror, page: 3)
        #expect(repo.calls.first?.subject == .horror)
        #expect(repo.calls.first?.page == 3)
    }
}

struct BookSubjectTests {
    @Test func rawValuesMatchOpenLibrarySubjects() {
        #expect(BookSubject.scienceFiction.rawValue == "science_fiction")
        #expect(BookSubject.allCases.count == 8)
        #expect(BookSubject.allCases.allSatisfy { !$0.title.isEmpty })
    }
}
