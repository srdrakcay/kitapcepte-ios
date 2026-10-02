import Foundation

/// Satır başına adet sınırları.
enum CartLimits {
    static let minQuantity = 1
    static let maxQuantity = 99

    static func clamp(_ quantity: Int) -> Int { min(max(quantity, minQuantity), maxQuantity) }
}

/// Vergi (KDV) politikası: ara toplam üzerinden tek oran.
enum TaxPolicy {
    static let rate: Decimal = 0.20
}

/// "Ödemeler" satırı: sabit kargo ücreti; ara toplam eşiği aşarsa ücretsiz.
enum ShippingPolicy {
    static let fee: Decimal = 29.90
    static let freeThreshold: Decimal = 250
}

struct CartSummary: Equatable, Sendable {
    let subtotal: Decimal
    let tax: Decimal
    let shipping: Decimal
    var total: Decimal { subtotal + tax + shipping }
}

/// Saf fiyat hesaplayıcı. Tutarlar kuruşa (2 hane) yuvarlanır.
enum CartPricing {
    static func summary(for items: [CartItem]) -> CartSummary {
        guard !items.isEmpty else { return CartSummary(subtotal: 0, tax: 0, shipping: 0) }
        let subtotal = rounded(items.reduce(Decimal.zero) { $0 + $1.totalPrice })
        let tax = rounded(subtotal * TaxPolicy.rate)
        let shipping = subtotal >= ShippingPolicy.freeThreshold ? 0 : ShippingPolicy.fee
        return CartSummary(subtotal: subtotal, tax: tax, shipping: shipping)
    }

    private static func rounded(_ value: Decimal) -> Decimal {
        var input = value
        var output = Decimal()
        NSDecimalRound(&output, &input, 2, .plain)
        return output
    }
}
