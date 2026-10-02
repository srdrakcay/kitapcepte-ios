import Foundation
import SwiftData

@MainActor
final class SwiftDataCartRepository: CartRepository {
    private let context: ModelContext
    private let userIDProvider: @MainActor () -> UUID?

    init(context: ModelContext, userIDProvider: @escaping @MainActor () -> UUID?) {
        self.context = context
        self.userIDProvider = userIDProvider
    }

    func items() async -> [CartItem] {
        guard let owner = userIDProvider() else { return [] }
        let descriptor = FetchDescriptor<CartItemEntity>(
            predicate: #Predicate { $0.ownerID == owner },
            sortBy: [SortDescriptor(\.addedAt)]
        )
        return ((try? context.fetch(descriptor)) ?? []).map(CartMapper.item(from:))
    }

    func add(_ book: Book) async throws {
        guard let owner = userIDProvider() else { throw AppError.unknown }
        let bookID = book.id
        let descriptor = FetchDescriptor<CartItemEntity>(predicate: #Predicate { $0.ownerID == owner && $0.bookID == bookID })
        guard try context.fetch(descriptor).isEmpty else { return }
        context.insert(CartItemEntity(ownerID: owner, item: CartItem(book: book)))
        try context.save()
    }
}
