extension CardIssue {
    var message: String {
        switch self {
        case .numberInvalid: Strings.Payment.numberInvalid
        case .holderEmpty: Strings.Payment.holderEmpty
        case .expiryInvalid: Strings.Payment.expiryInvalid
        case .expiryExpired: Strings.Payment.expiryExpired
        case .cvvInvalid: Strings.Payment.cvvInvalid
        }
    }
}

extension CardBrand {
    var title: String {
        switch self {
        case .visa: Strings.Payment.brandVisa
        case .mastercard: Strings.Payment.brandMastercard
        case .amex: Strings.Payment.brandAmex
        case .troy: Strings.Payment.brandTroy
        case .unknown: Strings.Payment.brandUnknown
        }
    }
}
