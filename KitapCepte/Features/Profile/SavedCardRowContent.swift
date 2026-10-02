import Foundation

/// Kayıtlı kart satırında gösterilecek hazır metinler. Tam numara/CVV içermez.
struct SavedCardRowContent: Equatable, Identifiable {
    let id: UUID
    let brandName: String
    let maskedNumber: String
    let holderText: String
    /// "SKT AA/YY"
    let expiryText: String
    let isExpired: Bool
    let accessibilityText: String

    private static let mask = "••••"

    init(summary: PaymentCardSummary, isExpired: Bool) {
        let expiry = Self.expiryString(month: summary.expiryMonth, year: summary.expiryYear)
        id = summary.id
        brandName = summary.brand.title
        maskedNumber = "\(Self.mask) \(summary.last4)"
        holderText = summary.holderName.uppercased()
        expiryText = Strings.Profile.cardExpiry(expiry)
        self.isExpired = isExpired
        accessibilityText = Strings.Profile.cardA11y(brand: summary.brand.title, last4: summary.last4, expiry: expiry)
            + (isExpired ? ", \(Strings.Profile.cardExpired)" : "")
    }

    /// "AA/YY"
    static func expiryString(month: Int, year: Int) -> String {
        String(format: "%02d/%02d", month, year % 100)
    }
}

extension PaymentCardSummary {
    /// SKT ayının sonuna kadar geçerli sayılır; sonraki ay "süresi doldu".
    func isExpired(now: Date, calendar: Calendar) -> Bool {
        let parts = calendar.dateComponents([.year, .month], from: now)
        guard let year = parts.year, let month = parts.month else { return false }
        return (expiryYear, expiryMonth) < (year, month)
    }
}
