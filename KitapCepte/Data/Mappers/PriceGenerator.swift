import Foundation

/// Open Library'de fiyat yok; `key`'ten deterministik mock fiyat (TRY) üretir.
/// Swift'in `hashValue`'su rastgele tohumlu olduğundan sabit FNV-1a kullanılır.
enum PriceGenerator {
    static let minCents = 7_990
    static let maxCents = 34_990
    static let stepCents = 10
    private static let fnvOffsetBasis: UInt64 = 0xcbf29ce484222325
    private static let fnvPrime: UInt64 = 0x100000001b3

    static func fnv1a64(_ text: String) -> UInt64 {
        text.utf8.reduce(fnvOffsetBasis) { ($0 ^ UInt64($1)) &* fnvPrime }
    }

    static func price(forKey key: String) -> Decimal {
        let stepCount = UInt64((maxCents - minCents) / stepCents + 1)
        let cents = minCents + Int(fnv1a64(key) % stepCount) * stepCents
        return Decimal(cents) / 100
    }
}
