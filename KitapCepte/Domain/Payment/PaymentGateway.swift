import Foundation

/// Ödeme sağlayıcısı soyutlaması. Gerçek bir sağlayıcı bu protokolle bağlanır; uygulamada simülasyon vardır.
protocol PaymentGateway: Sendable {
    /// İptal edilirse `CancellationError` fırlatır. Reddedilirse `PaymentError.declined`.
    func pay(amount: Decimal, card: PaymentCard) async throws -> PaymentReceipt
}
