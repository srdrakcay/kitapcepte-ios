/// Kart markası; BIN önekinden tespit edilir. Her markanın numara uzunluğu, CVV hane sayısı ve gruplaması farklıdır.
enum CardBrand: String, Hashable, Sendable, CaseIterable {
    case visa, mastercard, amex, troy, unknown

    /// Numara başındaki rakamlardan marka tespiti (kısmi girdide de çalışır).
    static func detect(from digits: String) -> CardBrand {
        let prefix2 = Int(digits.prefix(2))
        let prefix4 = Int(digits.prefix(4))
        if digits.hasPrefix("9792") { return .troy }
        if prefix2 == 34 || prefix2 == 37 { return .amex }
        if digits.hasPrefix("4") { return .visa }
        if let prefix2, (51...55).contains(prefix2) { return .mastercard }
        if let prefix4, digits.count >= 4, (2221...2720).contains(prefix4) { return .mastercard }
        return .unknown
    }

    var numberLength: Int { self == .amex ? 15 : 16 }
    var cvvLength: Int { self == .amex ? 4 : 3 }
    /// Numara gruplaması (ör. Amex 4-6-5).
    var groupSizes: [Int] { self == .amex ? [4, 6, 5] : [4, 4, 4, 4] }
}
