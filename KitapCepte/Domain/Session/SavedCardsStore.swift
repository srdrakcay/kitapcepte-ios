import Foundation
import Observation

/// Kayıtlı kart özetlerinin paylaşılan durumu (ödeme sonrası kayıt, Profil listesi).
@MainActor @Observable
final class SavedCardsStore {
    private(set) var cards: [PaymentCardSummary] = []
    private let getCards: GetSavedCardsUseCase
    private let saveCard: SaveCardUseCase
    private let deleteCard: DeleteSavedCardUseCase

    init(repository: SavedCardRepository) {
        self.getCards = GetSavedCardsUseCase(repository: repository)
        self.saveCard = SaveCardUseCase(repository: repository)
        self.deleteCard = DeleteSavedCardUseCase(repository: repository)
    }

    func reload() async {
        cards = await getCards()
    }

    func save(_ summary: PaymentCardSummary) async throws {
        try await saveCard(summary)
        await reload()
    }

    func delete(id: UUID) async throws {
        try await deleteCard(id: id)
        await reload()
    }
}
