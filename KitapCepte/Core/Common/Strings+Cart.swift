import Foundation

extension Strings {
    /// Sepet ekranı metinleri (`Cart.xcstrings`).
    enum Cart {
        static let title = String(localized: "cart.title", table: "Cart")
        static let emptyTitle = String(localized: "cart.empty.title", table: "Cart")
        static let emptyMessage = String(localized: "cart.empty.message", table: "Cart")
        static let removeQuestion = String(localized: "cart.remove.question", table: "Cart")
        static let removeNo = String(localized: "cart.remove.no", table: "Cart")
        static let removeYes = String(localized: "cart.remove.yes", table: "Cart")
        static let subtotal = String(localized: "cart.summary.subtotal", table: "Cart")
        static let tax = String(localized: "cart.summary.tax", table: "Cart")
        static let shipping = String(localized: "cart.summary.shipping", table: "Cart")
        static let shippingFree = String(localized: "cart.summary.shipping.free", table: "Cart")
        static let total = String(localized: "cart.summary.total", table: "Cart")
        static let increase = String(localized: "cart.a11y.increase", table: "Cart")
        static let decrease = String(localized: "cart.a11y.decrease", table: "Cart")
        static let remove = String(localized: "cart.a11y.remove", table: "Cart")

        static func checkout(_ price: String) -> String {
            String(format: String(localized: "cart.checkout", table: "Cart"), price)
        }

        static func quantity(_ value: Int) -> String {
            String(format: String(localized: "cart.a11y.quantity", table: "Cart"), value)
        }

        static func itemSummary(title: String, price: String) -> String {
            String(format: String(localized: "cart.a11y.itemFormat", table: "Cart"), title, price)
        }
    }
}
