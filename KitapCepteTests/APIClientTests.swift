import Foundation
import Testing
@testable import KitapCepte

final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    typealias Responder = @Sendable (URLRequest) -> (statusCode: Int, data: Data)?

    private static let lock = NSLock()
    nonisolated(unsafe) private static var responder: Responder?
    nonisolated(unsafe) private static var requests: [URLRequest] = []

    static func configure(_ responder: @escaping Responder) {
        lock.withLock { self.responder = responder; requests = [] }
    }

    static var recordedRequests: [URLRequest] { lock.withLock { requests } }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let responder = Self.lock.withLock { () -> Responder? in
            Self.requests.append(request)
            return Self.responder
        }
        guard let result = responder?(request), let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: result.statusCode, httpVersion: nil, headerFields: nil)
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: result.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@Suite(.serialized)
struct APIClientTests {
    private struct Payload: Decodable, Sendable, Equatable { let name: String }

    private func makeSUT(maxRetries: Int = 2) -> URLSessionAPIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let config = APIConfig(maxRetries: maxRetries, retryDelay: .zero)
        return URLSessionAPIClient(session: URLSession(configuration: configuration), config: config)
    }

    private let endpoint = Endpoint(path: "/x.json", queryItems: [URLQueryItem(name: "q", value: "subject:fantasy")])

    @Test func decodesSuccessfulResponse() async throws {
        StubURLProtocol.configure { _ in (200, Data(#"{"name":"ok"}"#.utf8)) }
        let result: Payload = try await makeSUT().send(endpoint)
        #expect(result == Payload(name: "ok"))
    }

    @Test func sendsUserAgentAndBuildsExpectedURL() async throws {
        StubURLProtocol.configure { _ in (200, Data(#"{"name":"ok"}"#.utf8)) }
        let _: Payload = try await makeSUT().send(endpoint)
        let request = try #require(StubURLProtocol.recordedRequests.first)
        #expect(request.value(forHTTPHeaderField: "User-Agent")?.hasPrefix("KitapCepte/") == true)
        #expect(request.url?.absoluteString == "https://openlibrary.org/x.json?q=subject:fantasy")
        #expect(request.timeoutInterval == 20)
    }

    @Test func notFoundIsNotRetried() async {
        StubURLProtocol.configure { _ in (404, Data()) }
        await #expect(throws: AppError.notFound) { let _: Payload = try await makeSUT().send(endpoint) }
        #expect(StubURLProtocol.recordedRequests.count == 1)
    }

    @Test func serverErrorRetriesThenFails() async {
        StubURLProtocol.configure { _ in (503, Data()) }
        await #expect(throws: AppError.network) { let _: Payload = try await makeSUT(maxRetries: 2).send(endpoint) }
        #expect(StubURLProtocol.recordedRequests.count == 3)
    }

    @Test func recoversWhenRetrySucceeds() async throws {
        let counter = Counter()
        StubURLProtocol.configure { _ in
            counter.next() == 1 ? (500, Data()) : (200, Data(#"{"name":"back"}"#.utf8))
        }
        let result: Payload = try await makeSUT().send(endpoint)
        #expect(result.name == "back")
        #expect(StubURLProtocol.recordedRequests.count == 2)
    }

    @Test func malformedBodyIsDecodingError() async {
        StubURLProtocol.configure { _ in (200, Data("nope".utf8)) }
        await #expect(throws: AppError.decoding) { let _: Payload = try await makeSUT().send(endpoint) }
    }

    @Test func transportFailureMapsToNetworkError() async {
        StubURLProtocol.configure { _ in nil }
        await #expect(throws: AppError.network) { let _: Payload = try await makeSUT(maxRetries: 0).send(endpoint) }
    }

    @Test func otherClientErrorsMapToNetwork() async {
        StubURLProtocol.configure { _ in (403, Data()) }
        await #expect(throws: AppError.network) { let _: Payload = try await makeSUT().send(endpoint) }
        #expect(StubURLProtocol.recordedRequests.count == 1)
    }
}

final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    func next() -> Int { lock.withLock { value += 1; return value } }
}

struct OpenLibraryServiceTests {
    @Test func buildsSearchEndpointWithSubjectPageAndLimit() async throws {
        final class Capture: APIClient, @unchecked Sendable {
            nonisolated(unsafe) var endpoint: Endpoint?
            func send<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
                self.endpoint = endpoint
                return try JSONDecoder().decode(T.self, from: Data(#"{"docs":[]}"#.utf8))
            }
        }
        let capture = Capture()
        _ = try await OpenLibraryService(client: capture).searchBooks(subject: "fantasy", page: 2, limit: 30)
        let url = try #require(capture.endpoint?.url)
        #expect(url.path == "/search.json")
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.contains(URLQueryItem(name: "q", value: "subject:fantasy")))
        #expect(items.contains(URLQueryItem(name: "limit", value: "30")))
        #expect(items.contains(URLQueryItem(name: "page", value: "2")))
    }
}
