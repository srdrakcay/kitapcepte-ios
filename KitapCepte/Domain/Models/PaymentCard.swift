import Foundation

/// Kullanıcının girdiği kart. YALNIZCA bellekte yaşar: kart no ve CVV hiçbir yere kaydedilmez, loglanmaz.
struct PaymentCard: Equatable, Sendable {
    /// Yalnızca rakamlar.
    var number: String
    var holderName: String
    /// "AA/YY" (veya ayraçsız rakamlar).
    var expiry: String
    var cvv: String

    static let empty = PaymentCard(number: "", holderName: "", expiry: "", cvv: "")

    var brand: CardBrand { CardBrand.detect(from: number) }
    var last4: String { String(number.suffix(4)) }
    var parsedExpiry: CardExpiry? { CardExpiry(text: expiry) }
}

/// Son kullanma tarihi (ay 1...12, 4 haneli yıl).
struct CardExpiry: Equatable, Hashable, Sendable {
    let month: Int
    let year: Int

    /// "AA/YY" veya "AAYY" biçimini çözer; ay 1...12 değilse nil.
    init?(text: String) {
        let digits = text.filter(\.isNumber)
        guard digits.count == 4, let month = Int(digits.prefix(2)), let yy = Int(digits.suffix(2)),
              (1...12).contains(month) else { return nil }
        self.month = month
        self.year = 2000 + yy
    }
}

/// Kaydedilebilen kart özeti: tam numara/CVV içermez.
struct PaymentCardSummary: Identifiable, Hashable, Sendable {
    let id: UUID
    let brand: CardBrand
    let last4: String
    let holderName: String
    let expiryMonth: Int
    let expiryYear: Int

    init(id: UUID = UUID(), brand: CardBrand, last4: String, holderName: String, expiryMonth: Int, expiryYear: Int) {
        self.id = id
        self.brand = brand
        self.last4 = last4
        self.holderName = holderName
        self.expiryMonth = expiryMonth
        self.expiryYear = expiryYear
    }

    /// Girdi geçerli bir SKT içermiyorsa nil.
    init?(card: PaymentCard) {
        guard let expiry = card.parsedExpiry else { return nil }
        self.init(
            brand: card.brand, last4: card.last4,
            holderName: card.holderName.trimmingCharacters(in: .whitespacesAndNewlines),
            expiryMonth: expiry.month, expiryYear: expiry.year
        )
    }

    /// Aynı kart: marka + son 4 hane + SKT.
    func isSameCard(as other: PaymentCardSummary) -> Bool {
        brand == other.brand && last4 == other.last4 && expiryMonth == other.expiryMonth && expiryYear == other.expiryYear
    }
}

/// Başarılı ödeme fişi. Tam kart numarası içermez.
struct PaymentReceipt: Equatable, Sendable {
    let reference: String
    let amount: Decimal
    let brand: CardBrand
    let last4: String
    let paidAt: Date
}

enum PaymentError: Error, Equatable, Sendable {
    case invalidCard([CardField: CardIssue])
    case emptyCart
    case declined
    case failed
}
