struct SearchResponseDTO: Decodable, Sendable {
    let numFound: Int?
    let docs: [BookDocDTO]
}

struct BookDocDTO: Decodable, Sendable {
    let key: String
    let title: String
    let authorName: [String]?
    let authorKey: [String]?
    let coverI: Int?
    let firstPublishYear: Int?
    let editionCount: Int?
    let language: [String]?

    enum CodingKeys: String, CodingKey {
        case key, title, language
        case authorName = "author_name"
        case authorKey = "author_key"
        case coverI = "cover_i"
        case firstPublishYear = "first_publish_year"
        case editionCount = "edition_count"
    }
}

/// `GET {key}.json` (work). Yalnızca açıklama kullanılır.
struct WorkDTO: Decodable, Sendable {
    let description: String?

    private enum CodingKeys: String, CodingKey { case description }

    /// Open Library açıklamayı düz metin ya da `{type, value}` objesi olarak döndürebilir.
    private struct TypedValue: Decodable { let value: String? }

    init(description: String?) {
        self.description = description
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let text = try? container.decodeIfPresent(String.self, forKey: .description) {
            description = text
        } else if let typed = try? container.decodeIfPresent(TypedValue.self, forKey: .description) {
            description = typed.value
        } else {
            description = nil
        }
    }
}
