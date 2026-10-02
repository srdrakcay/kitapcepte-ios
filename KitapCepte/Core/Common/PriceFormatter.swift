import Foundation

struct PriceFormatter: Sendable {
    let locale: Locale

    static let standard = PriceFormatter(locale: Locale(identifier: "tr_TR"))

    func string(from price: Decimal) -> String {
        price.formatted(.currency(code: "TRY").locale(locale))
    }
}
