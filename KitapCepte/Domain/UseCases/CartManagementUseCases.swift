@MainActor
struct GetCartUseCase {
    let repository: CartRepository

    func callAsFunction() async -> [CartItem] {
        await repository.items()
    }
}

@MainActor
struct UpdateCartQuantityUseCase {
    let repository: CartRepository

    func callAsFunction(bookID: String, quantity: Int) async throws {
        try await repository.setQuantity(quantity, for: bookID)
    }
}

@MainActor
struct RemoveFromCartUseCase {
    let repository: CartRepository

    func callAsFunction(bookID: String) async throws {
        try await repository.remove(bookID)
    }
}

@MainActor
struct ClearCartUseCase {
    let repository: CartRepository

    func callAsFunction() async throws {
        try await repository.clear()
    }
}
