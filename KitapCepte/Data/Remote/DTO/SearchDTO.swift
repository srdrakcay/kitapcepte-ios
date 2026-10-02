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
