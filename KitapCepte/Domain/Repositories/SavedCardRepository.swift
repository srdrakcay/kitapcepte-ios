import Foundation

/// Oturumdaki kullanıcıya ait kayıtlı kart ÖZETLERİ (tam numara/CVV asla yok).
@MainActor
protocol SavedCardRepository: AnyObject {
    func cards() async -> [PaymentCardSummary]
    /// Aynı kart (marka + son 4 + SKT) zaten kayıtlıysa tekrar eklemez.
    func save(_ summary: PaymentCardSummary) async throws
    func delete(id: UUID) async throws
}
