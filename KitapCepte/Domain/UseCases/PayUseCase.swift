import Foundation

/// Doğrulama -> ödeme -> (isteğe bağlı) kart özetini kaydet -> sepeti temizle.
/// Reddedilen/geçersiz ödemede sepete ve kayıtlı kartlara dokunulmaz.
@MainActor
struct PayUseCase {
    let validator: CardValidator
    let gateway: PaymentGateway
    let cart: CartStore
    let savedCards: SavedCardsStore

    func callAsFunction(card: PaymentCard, saveCard: Bool) async throws -> PaymentReceipt {
        guard !cart.items.isEmpty else { throw PaymentError.emptyCart }
        let issues = validator.validate(card)
        guard issues.isEmpty else { throw PaymentError.invalidCard(issues) }

        let amount = CartPricing.summary(for: cart.items).total
        let receipt = try await gateway.pay(amount: amount, card: card)

        // Ödeme alındı: bundan sonraki yan işlemlerin hatası kullanıcıya "ödeme başarısız" olarak yansımaz.
        if saveCard, let summary = PaymentCardSummary(card: card) {
            try? await savedCards.save(summary)
        }
        try? await cart.clear()
        return receipt
    }
}
