import Foundation
import SwiftData

@MainActor
final class SwiftDataSavedCardRepository: SavedCardRepository {
    private let context: ModelContext
    private let userIDProvider: @MainActor () -> UUID?

    init(context: ModelContext, userIDProvider: @escaping @MainActor () -> UUID?) {
        self.context = context
        self.userIDProvider = userIDProvider
    }

    func cards() async -> [PaymentCardSummary] {
        guard let owner = userIDProvider() else { return [] }
        return ((try? fetchAll(owner: owner)) ?? []).map(SavedCardMapper.summary(from:))
    }

    func save(_ summary: PaymentCardSummary) async throws {
        guard let owner = userIDProvider() else { throw AppError.unknown }
        let existing = try fetchAll(owner: owner).map(SavedCardMapper.summary(from:))
        guard !existing.contains(where: { $0.isSameCard(as: summary) }) else { return }
        context.insert(SavedCardEntity(ownerID: owner, summary: summary))
        try context.save()
    }

    func delete(id: UUID) async throws {
        guard let owner = userIDProvider() else { throw AppError.unknown }
        let descriptor = FetchDescriptor<SavedCardEntity>(predicate: #Predicate { $0.ownerID == owner && $0.id == id })
        for entity in try context.fetch(descriptor) { context.delete(entity) }
        try context.save()
    }

    private func fetchAll(owner: UUID) throws -> [SavedCardEntity] {
        let descriptor = FetchDescriptor<SavedCardEntity>(
            predicate: #Predicate { $0.ownerID == owner },
            sortBy: [SortDescriptor(\.addedAt)]
        )
        return try context.fetch(descriptor)
    }
}
