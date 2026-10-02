import Foundation

extension Strings {
    /// Ödeme ekranı metinleri (`Payment.xcstrings`).
    enum Payment {
        static let title = String(localized: "payment.title", table: "Payment")
        static let numberLabel = String(localized: "payment.field.number", table: "Payment")
        static let numberA11y = String(localized: "payment.a11y.number", table: "Payment")
        static let holderLabel = String(localized: "payment.field.holder", table: "Payment")
        static let expiryLabel = String(localized: "payment.field.expiry", table: "Payment")
        static let cvvLabel = String(localized: "payment.field.cvv", table: "Payment")
        static let saveCard = String(localized: "payment.saveCard", table: "Payment")
        static let total = String(localized: "payment.total", table: "Payment")
        static let numberInvalid = String(localized: "payment.error.number", table: "Payment")
        static let holderEmpty = String(localized: "payment.error.holder", table: "Payment")
        static let expiryInvalid = String(localized: "payment.error.expiry", table: "Payment")
        static let expiryExpired = String(localized: "payment.error.expired", table: "Payment")
        static let cvvInvalid = String(localized: "payment.error.cvv", table: "Payment")
        static let declined = String(localized: "payment.error.declined", table: "Payment")
        static let failed = String(localized: "payment.error.failed", table: "Payment")
        static let emptyTitle = String(localized: "payment.empty.title", table: "Payment")
        static let emptyMessage = String(localized: "payment.empty.message", table: "Payment")
        static let successTitle = String(localized: "payment.success.title", table: "Payment")
        static let successMessage = String(localized: "payment.success.message", table: "Payment")
        static let receiptReference = String(localized: "payment.receipt.reference", table: "Payment")
        static let receiptAmount = String(localized: "payment.receipt.amount", table: "Payment")
        static let receiptCard = String(localized: "payment.receipt.card", table: "Payment")
        static let receiptDate = String(localized: "payment.receipt.date", table: "Payment")
        static let backHome = String(localized: "payment.backHome", table: "Payment")
        static let brandVisa = String(localized: "payment.brand.visa", table: "Payment")
        static let brandMastercard = String(localized: "payment.brand.mastercard", table: "Payment")
        static let brandAmex = String(localized: "payment.brand.amex", table: "Payment")
        static let brandTroy = String(localized: "payment.brand.troy", table: "Payment")
        static let brandUnknown = String(localized: "payment.brand.unknown", table: "Payment")
        static let holderPlaceholder = String(localized: "payment.preview.holder", table: "Payment")
        static let expiryPlaceholder = String(localized: "payment.preview.expiry", table: "Payment")

        static func pay(_ price: String) -> String {
            String(format: String(localized: "payment.pay", table: "Payment"), price)
        }

        /// "Visa •••• 4242"
        static func cardDescription(brand: String, last4: String) -> String {
            String(format: String(localized: "payment.cardFormat", table: "Payment"), brand, last4)
        }

        static func previewA11y(brand: String) -> String {
            String(format: String(localized: "payment.a11y.preview", table: "Payment"), brand)
        }

        static func previewA11yLast4(brand: String, last4: String) -> String {
            String(format: String(localized: "payment.a11y.previewLast4", table: "Payment"), brand, last4)
        }
    }
}
