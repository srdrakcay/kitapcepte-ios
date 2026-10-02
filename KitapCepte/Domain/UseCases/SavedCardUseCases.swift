import Foundation

@MainActor
struct GetSavedCardsUseCase {
    let repository: SavedCardRepository

    func callAsFunction() async -> [PaymentCardSummary] {
        await repository.cards()
    }
}

@MainActor
struct SaveCardUseCase {
    let repository: SavedCardRepository

    func callAsFunction(_ summary: PaymentCardSummary) async throws {
        try await repository.save(summary)
    }
}

@MainActor
struct DeleteSavedCardUseCase {
    let repository: SavedCardRepository

    func callAsFunction(id: UUID) async throws {
        try await repository.delete(id: id)
    }
}
