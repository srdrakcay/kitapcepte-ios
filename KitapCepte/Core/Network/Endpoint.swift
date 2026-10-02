import Foundation

struct Endpoint: Sendable {
    var host = "openlibrary.org"
    let path: String
    var queryItems: [URLQueryItem] = []

    var url: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        if !queryItems.isEmpty { components.queryItems = queryItems }
        return components.url
    }
}
