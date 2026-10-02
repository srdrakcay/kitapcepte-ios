import Foundation
import SwiftData

@MainActor
final class SwiftDataFavoritesRepository: FavoritesRepository {
    private let context: ModelContext
    private let userIDProvider: @MainActor () -> UUID?

    init(context: ModelContext, userIDProvider: @escaping @MainActor () -> UUID?) {
        self.context = context
        self.userIDProvider = userIDProvider
    }

    func favoriteIDs() async -> Set<String> {
        guard let owner = userIDProvider() else { return [] }
        let descriptor = FetchDescriptor<FavoriteEntity>(predicate: #Predicate { $0.ownerID == owner })
        let entities = (try? context.fetch(descriptor)) ?? []
        return Set(entities.map(\.bookID))
    }

    func favoriteBooks() async throws -> [Book] {
        guard let owner = userIDProvider() else { return [] }
        let descriptor = FetchDescriptor<FavoriteEntity>(
            predicate: #Predicate { $0.ownerID == owner },
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map(FavoriteMapper.book(from:))
    }

    func toggle(_ book: Book) async throws -> Bool {
        guard let owner = userIDProvider() else { throw AppError.unknown }
        let bookID = book.id
        let descriptor = FetchDescriptor<FavoriteEntity>(predicate: #Predicate { $0.ownerID == owner && $0.bookID == bookID })
        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
            return false
        }
        context.insert(FavoriteEntity(ownerID: owner, book: book))
        try context.save()
        return true
    }
}
