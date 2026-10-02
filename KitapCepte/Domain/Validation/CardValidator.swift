import Foundation

/// Kart formundaki alanlar.
enum CardField: Hashable, Sendable, CaseIterable {
    case number, holder, expiry, cvv
}

enum CardIssue: Equatable, Sendable {
    case numberInvalid
    case holderEmpty
    case expiryInvalid
    case expiryExpired
    case cvvInvalid

    var field: CardField {
        switch self {
        case .numberInvalid: .number
        case .holderEmpty: .holder
        case .expiryInvalid, .expiryExpired: .expiry
        case .cvvInvalid: .cvv
        }
    }
}

/// "Şu an"ı soyutlar; testlerde sabit tarih verilir.
protocol DateProviding: Sendable {
    var now: Date { get }
}

struct SystemDateProvider: DateProviding {
    var now: Date { .now }
}

/// Saf Swift kart doğrulayıcı.
struct CardValidator: Sendable {
    /// SKT bu kadar yıldan ileri olamaz.
    static let maxYearsAhead = 20

    private let dateProvider: DateProviding
    private let calendar: Calendar

    init(dateProvider: DateProviding = SystemDateProvider(), calendar: Calendar = .current) {
        self.dateProvider = dateProvider
        self.calendar = calendar
    }

    /// Alan başına en fazla bir sorun döner; boş sözlük = geçerli.
    func validate(_ card: PaymentCard) -> [CardField: CardIssue] {
        var issues: [CardField: CardIssue] = [:]
        let checks: [CardIssue?] = [
            numberIssue(card), holderIssue(card), expiryIssue(card), cvvIssue(card)
        ]
        for issue in checks.compactMap({ $0 }) { issues[issue.field] = issue }
        return issues
    }

    static func passesLuhn(_ digits: String) -> Bool {
        guard !digits.isEmpty, digits.allSatisfy(\.isASCII), digits.allSatisfy(\.isNumber) else { return false }
        var sum = 0
        for (index, character) in digits.reversed().enumerated() {
            guard var value = character.wholeNumberValue else { return false }
            if index % 2 == 1 {
                value *= 2
                if value > 9 { value -= 9 }
            }
            sum += value
        }
        return sum % 10 == 0
    }

    private func numberIssue(_ card: PaymentCard) -> CardIssue? {
        let valid = card.number.count == card.brand.numberLength && Self.passesLuhn(card.number)
        return valid ? nil : .numberInvalid
    }

    private func holderIssue(_ card: PaymentCard) -> CardIssue? {
        card.holderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .holderEmpty : nil
    }

    private func cvvIssue(_ card: PaymentCard) -> CardIssue? {
        let valid = card.cvv.count == card.brand.cvvLength && card.cvv.allSatisfy { $0.isASCII && $0.isNumber }
        return valid ? nil : .cvvInvalid
    }

    private func expiryIssue(_ card: PaymentCard) -> CardIssue? {
        guard let expiry = card.parsedExpiry else { return .expiryInvalid }
        let now = calendar.dateComponents([.year, .month], from: dateProvider.now)
        guard let year = now.year, let month = now.month else { return .expiryInvalid }
        if expiry.year < year || (expiry.year == year && expiry.month < month) { return .expiryExpired }
        if expiry.year > year + Self.maxYearsAhead { return .expiryInvalid }
        return nil
    }
}

/// Girdi biçimlendirme yardımcıları (yazarken otomatik biçimlendirme).
enum CardFormatter {
    static let maxHolderLength = 26
    static let expiryDigits = 4
    static let maxCvvLength = 4

    static func digits(_ text: String) -> String {
        text.filter { $0.isASCII && $0.isNumber }
    }

    /// Rakamları markaya göre gruplar ("4242 4242 4242 4242"); marka uzunluğunu aşan rakamlar atılır.
    static func formatNumber(_ text: String) -> String {
        let all = digits(text)
        let brand = CardBrand.detect(from: all)
        return group(String(all.prefix(brand.numberLength)), sizes: brand.groupSizes)
    }

    /// Rakam dizisini boşlukla gruplar (kalan rakamlar için boşluk eklemez).
    static func group(_ digits: String, sizes: [Int]) -> String {
        var parts: [String] = []
        var rest = Substring(digits)
        for size in sizes where !rest.isEmpty {
            parts.append(String(rest.prefix(size)))
            rest = rest.dropFirst(size)
        }
        return parts.joined(separator: " ")
    }

    /// "AA/YY". 2–9 ile başlayan ilk rakamın önüne 0 eklenir; ayraç 3. rakamla gelir.
    static func formatExpiry(_ text: String) -> String {
        var all = digits(text)
        if let first = all.first, first.wholeNumberValue.map({ $0 > 1 }) == true { all = "0" + all }
        all = String(all.prefix(expiryDigits))
        guard all.count > 2 else { return all }
        return all.prefix(2) + "/" + all.dropFirst(2)
    }

    static func formatCvv(_ text: String, brand: CardBrand) -> String {
        String(digits(text).prefix(brand.cvvLength))
    }

    static func formatHolder(_ text: String) -> String {
        String(text.prefix(maxHolderLength))
    }
}
