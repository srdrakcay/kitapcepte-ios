import Foundation

protocol OpenLibraryServicing: Sendable {
    func searchBooks(subject: String, page: Int, limit: Int) async throws -> SearchResponseDTO
}

struct OpenLibraryService: OpenLibraryServicing {
    let client: APIClient

    func searchBooks(subject: String, page: Int, limit: Int) async throws -> SearchResponseDTO {
        try await client.send(Endpoint(
            path: "/search.json",
            queryItems: [
                URLQueryItem(name: "q", value: "subject:\(subject)"),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "page", value: String(page))
            ]
        ))
    }
}
