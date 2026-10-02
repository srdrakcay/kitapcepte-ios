import Foundation

protocol OpenLibraryServicing: Sendable {
    func searchBooks(subject: String, page: Int, limit: Int) async throws -> SearchResponseDTO
    func searchBooks(authorKey: String, limit: Int) async throws -> SearchResponseDTO
    /// `workKey`: Open Library work anahtarı (ör. `/works/OL8400950W`).
    func work(key workKey: String) async throws -> WorkDTO
}

struct OpenLibraryService: OpenLibraryServicing {
    let client: APIClient

    func searchBooks(subject: String, page: Int, limit: Int) async throws -> SearchResponseDTO {
        try await search(query: "subject:\(subject)", page: page, limit: limit)
    }

    func searchBooks(authorKey: String, limit: Int) async throws -> SearchResponseDTO {
        try await search(query: "author_key:\(authorKey)", page: 1, limit: limit)
    }

    func work(key workKey: String) async throws -> WorkDTO {
        try await client.send(Endpoint(path: "\(workKey).json"))
    }

    private func search(query: String, page: Int, limit: Int) async throws -> SearchResponseDTO {
        try await client.send(Endpoint(
            path: "/search.json",
            queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "page", value: String(page))
            ]
        ))
    }
}
