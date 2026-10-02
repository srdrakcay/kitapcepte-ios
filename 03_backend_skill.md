# BACKEND (API) SKILL — Kitap Cepte

## Kaynak
Open Library Search API (yalnızca **GET**, auth yok).
`https://openlibrary.org/search.json?q=subject:fantasy&limit=30`

## Endpoint kullanımı
| Amaç | İstek |
|---|---|
| Home listesi / chip filtresi | `GET /search.json?q=subject:{subject}&limit=30&page={n}` |
| Arama (opsiyonel) | `GET /search.json?q={text}&limit=30` |
| Detay açıklaması | `GET https://openlibrary.org{key}.json` (ör. `/works/OL8400950W.json`) |
| Benzer kitaplar | Aynı subject veya `author_key` ile `search.json`, mevcut kitap hariç |
| Kapak görseli | `https://covers.openlibrary.org/b/id/{cover_i}-M.jpg` (liste), `-L.jpg` (detay) |

## DTO (Codable)
```swift
struct SearchResponseDTO: Decodable {
    let numFound: Int?
    let docs: [BookDocDTO]
}
struct BookDocDTO: Decodable {
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
```
- Bilinmeyen alanlar yok sayılır; tüm opsiyonel alanlar null-safe.
- Works `description` alanı **String veya `{type, value}` objesi** olabilir → özel `init(from:)` ile ikisi de çözülür.
- `cover_i` yoksa placeholder görsel.

## Domain modeli ve mapping
`Book(id: key, title, authors, coverURL, firstPublishYear, price, description?)`
- **Fiyat API'de yok.** `key`'ten **deterministik** (her çalıştırmada aynı) mock fiyat üretilir: `PriceGenerator` (ör. 79,90–349,90 ₺, eski fiyat opsiyonel). Swift'in `hashValue`'su rastgele tohumludur, kullanılmaz; sabit bir hash (ör. FNV-1a) yazılır. Test edilir.
- "Top Item" rozeti: `editionCount` eşiğine göre (ör. ≥ 30).

## Chip → subject
Fantasy, Science Fiction, Romance, Mystery, History, Thriller, Horror, Biography (tek yerde tanımlı enum). "All" → varsayılan `fantasy`.

## Auth / Sepet / Ödeme (backend yok)
- Login/Register **yerel (mock)**; hesap bilgileri SwiftData + Keychain'de, şifre hash'li. `AuthRepository` protocol arkasında, ileride gerçek backend'e geçilebilir.
- Sepet ve favoriler SwiftData'da.
- Ödeme **simülasyon**: Luhn + SKT + CVV doğrulaması; **tam kart no/CVV saklanmaz**, sadece son 4 hane + marka.

## Ağ katmanı kuralları
- `APIClient` protocol (`func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T`), `URLSession` enjekte edilir.
- Timeout 20 sn, GET için 1–2 retry, `page` ile sayfalama, iptal desteği (`Task` cancel).
- HTTP/Decoding hataları → `AppError`.
- Open Library için `User-Agent` header'ı (uygulama adı + iletişim).
- Kısa süreli bellek cache'i (aynı subject/page tekrar çağrılmaz).
